import UIKit
import Supabase

// MARK: - Models
struct ApplicationCard {
    let id: String
    let actorId: UUID
    let name: String
    let location: String
    let timeAgo: String
    let profileImage: String
    var isConnected: Bool
    var hasSubmittedTask: Bool
    var isShortlisted: Bool
    var aiMatchScore: Int?
    var aiScoreExplanation: String?
    var aiScoreBreakdown: ApplicantAIScoreBreakdown?
}

struct ApplicantAIScoreBreakdown {
    let skill: Int
    let experience: Int
    let location: Int
    let portfolio: Int
    let reliability: Int
}

struct ApplicantAIMatch {
    let score: Int
    let explanation: String
    let breakdown: ApplicantAIScoreBreakdown
}

private struct AIApplicantContext: Encodable {
    let application_id: String
    let actor_id: String
    let name: String
    let role: String
    let location: String
    let bio: String
    let skills: [String]
    let years_of_experience: Int
    let portfolio_project_count: Int
    let has_portfolio: Bool
    let has_submitted_task: Bool
    let connection_count: Int
    let current_status: String
}

private struct AIApplicantMatchResult: Decodable {
    let actor_id: String
    let match_score: Int
    let explanation: String?
    let breakdown: AIApplicantBreakdown?
}

private struct AIApplicantBreakdown: Decodable {
    let skill_match: Int?
    let experience_match: Int?
    let location_match: Int?
    let portfolio_quality: Int?
    let activity_reliability: Int?
}

private struct AIApplicantMatchEnvelope: Decodable {
    let matches: [AIApplicantMatchResult]
}

private struct AIChatRequestBody: Encodable {
    let user_id: String
    let message: String
    let conversation_id: String
}

private struct AIChatResponseBody: Decodable {
    let answer: String
}

private final class ApplicantAIScoringService {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared) {
        self.session = session
        if let configuredBaseURL = Bundle.main.object(forInfoDictionaryKey: "AI_CHATBOT_BASE_URL") as? String,
           let configuredURL = URL(string: configuredBaseURL),
           !configuredBaseURL.isEmpty {
            self.baseURL = configuredURL
        } else {
            self.baseURL = URL(string: "https://cinemyst-chatbot-backend.onrender.com")!
        }
    }

    func scoreApplicants(userId: String, job: Job, applicants: [AIApplicantContext]) async throws -> [AIApplicantMatchResult] {
        let prompt = makePrompt(job: job, applicants: applicants)
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(
            AIChatRequestBody(
                user_id: userId,
                message: prompt,
                conversation_id: "job-shortlist-\(job.id.uuidString)"
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let bodyText = String(data: data, encoding: .utf8) ?? "Unknown AI server error"
            throw NSError(domain: "ApplicantAIScoringService", code: 1, userInfo: [NSLocalizedDescriptionKey: bodyText])
        }

        let chatResponse = try JSONDecoder().decode(AIChatResponseBody.self, from: data)
        return try parseMatches(from: chatResponse.answer)
    }

    private func makePrompt(job: Job, applicants: [AIApplicantContext]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let applicantsJSON = (try? String(data: encoder.encode(applicants), encoding: .utf8)) ?? "[]"
        let jobSummary = """
        {
          "id": "\(job.id.uuidString)",
          "title": "\(job.title ?? "")",
          "location": "\(job.location ?? "")",
          "description": "\(job.description ?? "")",
          "requirements": "\(job.requirements ?? "")",
          "job_type": "\(job.jobType ?? "")"
        }
        """

        return """
        You are CineMyst's candidate-shortlisting assistant for directors.
        Evaluate all applicants for this one job and rank them by best overall fit.

        Use meaning, not just exact keywords. Compare the job with each actor profile.
        Weight the final score out of 100 using:
        - skill match: 30
        - experience match: 20
        - location match: 15
        - portfolio quality: 20
        - activity and reliability: 15

        Job:
        \(jobSummary)

        Applicants:
        \(applicantsJSON)

        Return ONLY valid JSON in this exact shape:
        {
          "matches": [
            {
              "actor_id": "uuid",
              "match_score": 92,
              "explanation": "short human explanation",
              "breakdown": {
                "skill_match": 28,
                "experience_match": 17,
                "location_match": 12,
                "portfolio_quality": 19,
                "activity_reliability": 14
              }
            }
          ]
        }

        Rules:
        - Include every applicant exactly once.
        - Sort matches from highest score to lowest score.
        - Keep explanations concise and specific.
        - Do not include markdown or code fences.
        """
    }

    private func parseMatches(from answer: String) throws -> [AIApplicantMatchResult] {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8) {
            if let object = try? JSONDecoder().decode(AIApplicantMatchEnvelope.self, from: data) {
                return object.matches
            }
            if let array = try? JSONDecoder().decode([AIApplicantMatchResult].self, from: data) {
                return array
            }
        }

        let candidates = [extractJSONObject(from: trimmed), extractJSONArray(from: trimmed)].compactMap { $0 }
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let object = try? JSONDecoder().decode(AIApplicantMatchEnvelope.self, from: data) {
                return object.matches
            }
            if let array = try? JSONDecoder().decode([AIApplicantMatchResult].self, from: data) {
                return array
            }
        }

        throw NSError(domain: "ApplicantAIScoringService", code: 2, userInfo: [NSLocalizedDescriptionKey: "AI shortlist response was not valid JSON."])
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end])
    }

    private func extractJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]") else { return nil }
        return String(text[start...end])
    }
}

class ApplicationsViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    private var applications: [ApplicationCard] = []
    private var filteredApplications: [ApplicationCard] = []
    private var isFilteredByAI = false
    private let backgroundGradient = CAGradientLayer()
    private let aiScoringService = ApplicantAIScoringService()
    // Raw data for debug/info display
    private var dbApplicationsRaw: [Application] = []
    private var taskSubmissionsMap: [UUID: [TaskSubmission]] = [:]
    private var applicationProfileCache: [UUID: UserProfileData] = [:]
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var aiLoaderDotCenterXConstraints: [NSLayoutConstraint] = []
    
    // Use shared authenticated supabase client from Supabase.swift
    // Local instance was causing RLS policy violations (error 42501)
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Lead Actor - Drama Series \"City of Dre"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        lbl.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let searchBar: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search by name, location, or email..."
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.46)
        tf.layer.cornerRadius = 18
        tf.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.14).cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowOffset = CGSize(width: 0, height: 8)
        tf.layer.shadowRadius = 18
        tf.layer.borderWidth = 1
        tf.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 50))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.42)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let filtersButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(" Filters", for: .normal)
        btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        btn.layer.shadowOpacity = 0.06
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.layer.shadowRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let filterIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "slider.horizontal.3")
        iv.tintColor = CineMystTheme.brandPlum
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let topApplicantsButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("All Applicants", for: .normal)
        btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        btn.layer.shadowOpacity = 0.06
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.layer.shadowRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let chevronIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = CineMystTheme.brandPlum
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let aiFilterButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Filtered by AI", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = CineMystTheme.brandPlum
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.3).cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 10
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let countLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "25 applications"
        lbl.font = .systemFont(ofSize: 21, weight: .bold)
        lbl.textColor = CineMystTheme.ink
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tv
    }()

    private let aiLoadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        view.alpha = 0
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let aiLoadingCard: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let view = UIVisualEffectView(effect: effect)
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let aiLoadingTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI is filtering applicants"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = CineMystTheme.ink
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let aiLoadingSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Comparing skills, experience, portfolio, and reliability..."
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.78)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let aiLoadingRing: UIView = {
        let view = UIView()
        view.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        view.layer.cornerRadius = 32
        view.layer.borderWidth = 1.5
        view.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.18).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let aiLoadingCore: UIView = {
        let view = UIView()
        view.backgroundColor = CineMystTheme.brandPlum
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let aiLoadingCoreIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "sparkles"))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let aiLoadingDotsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        setupNavigationBar()
        setupUI()
        setupAILoadingOverlay()
        loadApplicationsForJob()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Applications"
        if let jobTitle = job?.title {
            subtitleLabel.text = jobTitle
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialLight)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.68)
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .foregroundColor: CineMystTheme.ink,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: CineMystTheme.ink,
            .font: UIFont.systemFont(ofSize: 22, weight: .bold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let profileBtn = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(profileTapped))
        profileBtn.tintColor = CineMystTheme.brandPlum
        navigationItem.rightBarButtonItem = profileBtn
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        backBtn.tintColor = CineMystTheme.brandPlum
        navigationItem.leftBarButtonItem = backBtn
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func profileTapped() {
        let vc = ShortlistedViewController()
        vc.job = job
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.backgroundColor = .clear
        
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(searchBar)
        searchBar.addSubview(searchIcon)
        contentView.addSubview(filtersButton)
        filtersButton.addSubview(filterIcon)
        contentView.addSubview(topApplicantsButton)
        contentView.addSubview(aiFilterButton)
        contentView.addSubview(countLabel)
        contentView.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ApplicationCell.self, forCellReuseIdentifier: "ApplicationCell")
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            searchBar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            
            searchIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchIcon.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 16),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            filtersButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            filtersButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            filtersButton.heightAnchor.constraint(equalToConstant: 38),
            
            filterIcon.centerYAnchor.constraint(equalTo: filtersButton.centerYAnchor),
            filterIcon.leadingAnchor.constraint(equalTo: filtersButton.leadingAnchor, constant: 12),
            filterIcon.widthAnchor.constraint(equalToConstant: 18),
            filterIcon.heightAnchor.constraint(equalToConstant: 18),
            
            topApplicantsButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            topApplicantsButton.leadingAnchor.constraint(equalTo: filtersButton.trailingAnchor, constant: 10),
            topApplicantsButton.heightAnchor.constraint(equalToConstant: 38),

            aiFilterButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            aiFilterButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            aiFilterButton.heightAnchor.constraint(equalToConstant: 38),
            
            countLabel.topAnchor.constraint(equalTo: filtersButton.bottomAnchor, constant: 20),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            tableView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 1)
        tableViewHeightConstraint?.isActive = true
        updateFilterButtons()
    }

    private func setupAILoadingOverlay() {
        view.addSubview(aiLoadingOverlay)
        aiLoadingOverlay.addSubview(aiLoadingCard)
        aiLoadingCard.contentView.addSubview(aiLoadingRing)
        aiLoadingRing.addSubview(aiLoadingCore)
        aiLoadingCore.addSubview(aiLoadingCoreIcon)
        aiLoadingCard.contentView.addSubview(aiLoadingTitleLabel)
        aiLoadingCard.contentView.addSubview(aiLoadingSubtitleLabel)
        aiLoadingCard.contentView.addSubview(aiLoadingDotsStack)

        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.28)
            dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
            aiLoadingDotsStack.addArrangedSubview(dot)
        }

        NSLayoutConstraint.activate([
            aiLoadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            aiLoadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aiLoadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aiLoadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            aiLoadingCard.centerXAnchor.constraint(equalTo: aiLoadingOverlay.centerXAnchor),
            aiLoadingCard.centerYAnchor.constraint(equalTo: aiLoadingOverlay.centerYAnchor),
            aiLoadingCard.leadingAnchor.constraint(greaterThanOrEqualTo: aiLoadingOverlay.leadingAnchor, constant: 28),
            aiLoadingCard.trailingAnchor.constraint(lessThanOrEqualTo: aiLoadingOverlay.trailingAnchor, constant: -28),
            aiLoadingCard.widthAnchor.constraint(equalToConstant: 280),

            aiLoadingRing.topAnchor.constraint(equalTo: aiLoadingCard.contentView.topAnchor, constant: 24),
            aiLoadingRing.centerXAnchor.constraint(equalTo: aiLoadingCard.contentView.centerXAnchor),
            aiLoadingRing.widthAnchor.constraint(equalToConstant: 64),
            aiLoadingRing.heightAnchor.constraint(equalToConstant: 64),

            aiLoadingCore.centerXAnchor.constraint(equalTo: aiLoadingRing.centerXAnchor),
            aiLoadingCore.centerYAnchor.constraint(equalTo: aiLoadingRing.centerYAnchor),
            aiLoadingCore.widthAnchor.constraint(equalToConstant: 24),
            aiLoadingCore.heightAnchor.constraint(equalToConstant: 24),

            aiLoadingCoreIcon.centerXAnchor.constraint(equalTo: aiLoadingCore.centerXAnchor),
            aiLoadingCoreIcon.centerYAnchor.constraint(equalTo: aiLoadingCore.centerYAnchor),
            aiLoadingCoreIcon.widthAnchor.constraint(equalToConstant: 12),
            aiLoadingCoreIcon.heightAnchor.constraint(equalToConstant: 12),

            aiLoadingTitleLabel.topAnchor.constraint(equalTo: aiLoadingRing.bottomAnchor, constant: 18),
            aiLoadingTitleLabel.leadingAnchor.constraint(equalTo: aiLoadingCard.contentView.leadingAnchor, constant: 18),
            aiLoadingTitleLabel.trailingAnchor.constraint(equalTo: aiLoadingCard.contentView.trailingAnchor, constant: -18),

            aiLoadingSubtitleLabel.topAnchor.constraint(equalTo: aiLoadingTitleLabel.bottomAnchor, constant: 8),
            aiLoadingSubtitleLabel.leadingAnchor.constraint(equalTo: aiLoadingCard.contentView.leadingAnchor, constant: 18),
            aiLoadingSubtitleLabel.trailingAnchor.constraint(equalTo: aiLoadingCard.contentView.trailingAnchor, constant: -18),

            aiLoadingDotsStack.topAnchor.constraint(equalTo: aiLoadingSubtitleLabel.bottomAnchor, constant: 18),
            aiLoadingDotsStack.centerXAnchor.constraint(equalTo: aiLoadingCard.contentView.centerXAnchor),
            aiLoadingDotsStack.bottomAnchor.constraint(equalTo: aiLoadingCard.contentView.bottomAnchor, constant: -22)
        ])
    }

    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1).cgColor,
            CineMystTheme.plumMist.cgColor,
            UIColor(red: 0.936, green: 0.892, blue: 0.917, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.45, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    private func loadApplicationsForJob() {
        Task {
            do {
                guard let job = job else {
                    print("❌ No job provided to ApplicationsViewController")
                    return
                }
                
                print("🔍 Loading applications for job:")
                print("  - Job ID: \(job.id.uuidString)")
                print("  - Job Title: \(job.title)")
                
                // Fetch applications for this job
                let dbApplications: [Application] = try await supabase
                    .from("applications")
                    .select()
                    .eq("job_id", value: job.id.uuidString)
                    .execute()
                    .value
                
                print("  - Applications found: \(dbApplications.count)")
                for (idx, app) in dbApplications.enumerated() {
                    print("    [\(idx+1)] App ID: \(app.id.uuidString), Actor: \(app.actorId.uuidString), Status: \(app.status)")
                }
                
                self.dbApplicationsRaw = dbApplications
                self.taskSubmissionsMap.removeAll()
                
                // Fetch submissions for each application
                for app in dbApplications {
                    do {
                        let subs: [TaskSubmission] = try await supabase
                            .from("task_submissions")
                            .select()
                            .eq("application_id", value: app.id.uuidString)
                            .order("submitted_at", ascending: false)
                            .execute()
                            .value
                        self.taskSubmissionsMap[app.id] = subs
                    } catch {
                        print("⚠️ Could not fetch submissions for app \(app.id): \(error)")
                    }
                }
                
                // Fetch user profiles
                var userProfiles: [UUID: String] = [:]
                for app in dbApplications {
                    if let name = try? await self.fetchUserName(userId: app.actorId) {
                        userProfiles[app.actorId] = name
                    }
                }
                
                // Convert to ApplicationCard with real names
                self.applications = dbApplications.map { app in
                    ApplicationCard(
                        id: app.id.uuidString,
                        actorId: app.actorId,
                        name: userProfiles[app.actorId] ?? "User \(app.actorId.uuidString.prefix(8))",
                        location: "India",
                        timeAgo: self.timeAgoString(from: app.appliedAt),
                        profileImage: "avatar_placeholder",
                        isConnected: false,
                        hasSubmittedTask: app.status == .taskSubmitted || app.status == .selected || app.status == .shortlisted,
                        isShortlisted: app.status == .shortlisted || app.status == .selected
                    )
                }
                
                self.filteredApplications = self.applications
                
                DispatchQueue.main.async {
                    self.countLabel.text = "\(self.applications.count) applications"
                    self.updateTableHeight()
                    self.updateFilterButtons()
                    self.tableView.reloadData()
                    print("✅ Applications loaded and displayed: \(self.applications.count)")
                }
            } catch {
                print("❌ Error loading applications: \(error)")
            }
        }
    }
    
    private func fetchUserName(userId: UUID) async throws -> String {
        struct UserProfile: Codable {
            let fullName: String?
            let username: String?
            
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case username
            }
        }
        
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            let name = profile.fullName ?? profile.username ?? "User \(userId.uuidString.prefix(8))"
            print("✅ Fetched user \(userId.uuidString.prefix(8)): \(name)")
            return name
        } catch {
            print("⚠️ Could not fetch profile for \(userId.uuidString.prefix(8)): \(error)")
            return "User \(userId.uuidString.prefix(8))"
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }
    
    private func setupActions() {
        filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        topApplicantsButton.addTarget(self, action: #selector(showAllApplicantsTapped), for: .touchUpInside)
        aiFilterButton.addTarget(self, action: #selector(aiFilterTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func showAppData() {
    guard let job = job else { return }
    var lines: [String] = []
    lines.append("Job: \(job.title) (\(job.id.uuidString))")
    lines.append("Applications: \(dbApplicationsRaw.count)")
    for app in dbApplicationsRaw {
    let status = app.status.rawValue
    let subs = taskSubmissionsMap[app.id] ?? []
    let latestURL = subs.first?.submissionUrl ?? "-"
    lines.append("• App \(app.id.uuidString.prefix(8)) status=\(status) submissions=\(subs.count) latest=\(latestURL)")
    }
    let message = lines.joined(separator: "\n")
    let alert = UIAlertController(title: "Application Data", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
    }
    
    
    @objc private func filtersTapped() {
        showFilterMenu()
    }
    
    @objc private func showAllApplicantsTapped() {
        isFilteredByAI = false
        filteredApplications = applications
        countLabel.text = "\(filteredApplications.count) applications"
        updateFilterButtons()
        updateTableHeight()
        tableView.reloadData()
    }
    
    @objc private func aiFilterTapped() {
        if isFilteredByAI {
            showAllApplicantsTapped()
            return
        }

        runAIShortlist()
    }
    
    private func showFilterMenu() {
        let alert = UIAlertController(title: "Filter Applications", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All Applications", style: .default, handler: { _ in
            self.isFilteredByAI = false
            self.filteredApplications = self.applications
            self.countLabel.text = "\(self.filteredApplications.count) applications"
            self.updateFilterButtons()
            self.updateTableHeight()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "By location", style: .default))
        alert.addAction(UIAlertAction(title: "Task Submitted", style: .default, handler: { _ in
            self.isFilteredByAI = false
            self.filteredApplications = self.applications.filter { $0.hasSubmittedTask }
            self.countLabel.text = "\(self.filteredApplications.count) applications"
            self.updateFilterButtons()
            self.updateTableHeight()
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Connections (100+)", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func updateFilterButtons() {
        styleToggleButton(topApplicantsButton, isActive: !isFilteredByAI, activeTitleColor: .white)
        styleToggleButton(aiFilterButton, isActive: isFilteredByAI, activeTitleColor: .white)
    }

    private func styleToggleButton(_ button: UIButton, isActive: Bool, activeTitleColor: UIColor = CineMystTheme.brandPlum) {
        if isActive {
            button.backgroundColor = CineMystTheme.brandPlum
            button.setTitleColor(activeTitleColor, for: .normal)
            button.layer.borderColor = UIColor.clear.cgColor
        } else {
            button.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            button.setTitleColor(CineMystTheme.brandPlum, for: .normal)
            button.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        }
    }

    private func updateTableHeight() {
        let rowHeight: CGFloat = 132
        let total = max(CGFloat(filteredApplications.count) * rowHeight, 1)
        tableViewHeightConstraint?.constant = total
        view.layoutIfNeeded()
    }

    private func runAIShortlist() {
        guard let job else { return }

        aiFilterButton.isEnabled = false
        aiFilterButton.setTitle("Ranking...", for: .normal)
        setAILoadingVisible(true)

        Task {
            let rankedApplications = await buildAIRankedApplications(for: job)

            await MainActor.run {
                self.isFilteredByAI = true
                self.filteredApplications = rankedApplications
                self.countLabel.text = "\(rankedApplications.count) AI-ranked applicants"
                self.aiFilterButton.isEnabled = true
                self.aiFilterButton.setTitle("Filtered by AI", for: .normal)
                self.updateFilterButtons()
                self.updateTableHeight()
                self.tableView.reloadData()
                self.setAILoadingVisible(false)
            }
        }
    }

    private func setAILoadingVisible(_ visible: Bool) {
        if visible {
            aiLoadingOverlay.isHidden = false
            view.bringSubviewToFront(aiLoadingOverlay)
            animateAILoader()
            UIView.animate(withDuration: 0.22) {
                self.aiLoadingOverlay.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.22, animations: {
                self.aiLoadingOverlay.alpha = 0
            }, completion: { _ in
                self.aiLoadingOverlay.isHidden = true
                self.aiLoadingRing.layer.removeAllAnimations()
                self.aiLoadingCore.layer.removeAllAnimations()
                self.aiLoadingDotsStack.arrangedSubviews.forEach { $0.layer.removeAllAnimations() }
            })
        }
    }

    private func animateAILoader() {
        let ringPulse = CABasicAnimation(keyPath: "transform.scale")
        ringPulse.fromValue = 1.0
        ringPulse.toValue = 1.12
        ringPulse.duration = 0.9
        ringPulse.autoreverses = true
        ringPulse.repeatCount = .infinity
        ringPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        aiLoadingRing.layer.add(ringPulse, forKey: "ringPulse")

        let corePulse = CABasicAnimation(keyPath: "opacity")
        corePulse.fromValue = 0.65
        corePulse.toValue = 1.0
        corePulse.duration = 0.75
        corePulse.autoreverses = true
        corePulse.repeatCount = .infinity
        aiLoadingCore.layer.add(corePulse, forKey: "corePulse")

        for (index, dot) in aiLoadingDotsStack.arrangedSubviews.enumerated() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.25
            animation.toValue = 1.0
            animation.duration = 0.55
            animation.beginTime = CACurrentMediaTime() + (Double(index) * 0.12)
            animation.autoreverses = true
            animation.repeatCount = .infinity
            dot.layer.add(animation, forKey: "dotPulse\(index)")
        }
    }

    private func buildAIRankedApplications(for job: Job) async -> [ApplicationCard] {
        let contexts = await buildApplicantContexts()
        let currentUserId = supabase.auth.currentSession?.user.id.uuidString ?? job.directorId?.uuidString ?? "director"

        do {
            let aiResults = try await aiScoringService.scoreApplicants(userId: currentUserId, job: job, applicants: contexts)
            let contextByActor = Dictionary(uniqueKeysWithValues: contexts.map { ($0.actor_id, $0) })
            let aiByActor = Dictionary(uniqueKeysWithValues: aiResults.map { ($0.actor_id, $0) })

            let ranked = applications.map { application -> ApplicationCard in
                var updated = application
                if let aiResult = aiByActor[application.actorId.uuidString] {
                    updated.aiMatchScore = max(0, min(100, aiResult.match_score))
                    updated.aiScoreBreakdown = ApplicantAIScoreBreakdown(
                        skill: aiResult.breakdown?.skill_match ?? 0,
                        experience: aiResult.breakdown?.experience_match ?? 0,
                        location: aiResult.breakdown?.location_match ?? 0,
                        portfolio: aiResult.breakdown?.portfolio_quality ?? 0,
                        reliability: aiResult.breakdown?.activity_reliability ?? 0
                    )
                    updated.aiScoreExplanation = makeAIScoreExplanation(
                        name: application.name,
                        explanation: aiResult.explanation,
                        breakdown: updated.aiScoreBreakdown
                    )
                } else if let context = contextByActor[application.actorId.uuidString] {
                    let fallback = fallbackMatch(for: context, job: job)
                    updated.aiMatchScore = fallback.score
                    updated.aiScoreBreakdown = fallback.breakdown
                    updated.aiScoreExplanation = makeAIScoreExplanation(
                        name: application.name,
                        explanation: fallback.explanation,
                        breakdown: fallback.breakdown
                    )
                }
                return updated
            }.sorted { ($0.aiMatchScore ?? 0) > ($1.aiMatchScore ?? 0) }

            return ranked
        } catch {
            print("⚠️ AI shortlist failed, using local fallback: \(error)")
            return applications.map { application in
                var updated = application
                if let context = contexts.first(where: { $0.actor_id == application.actorId.uuidString }) {
                    let fallback = fallbackMatch(for: context, job: job)
                    updated.aiMatchScore = fallback.score
                    updated.aiScoreBreakdown = fallback.breakdown
                    updated.aiScoreExplanation = makeAIScoreExplanation(
                        name: application.name,
                        explanation: fallback.explanation,
                        breakdown: fallback.breakdown
                    )
                }
                return updated
            }.sorted { ($0.aiMatchScore ?? 0) > ($1.aiMatchScore ?? 0) }
        }
    }

    private func buildApplicantContexts() async -> [AIApplicantContext] {
        var contexts: [AIApplicantContext] = []
        for application in applications {
            if let context = await buildApplicantContext(for: application) {
                contexts.append(context)
            }
        }
        return contexts
    }

    private func buildApplicantContext(for application: ApplicationCard) async -> AIApplicantContext? {
        let profileData: UserProfileData
        if let cached = applicationProfileCache[application.actorId] {
            profileData = cached
        } else {
            do {
                let fetched = try await ProfileService.shared.fetchUserProfile(userId: application.actorId)
                applicationProfileCache[application.actorId] = fetched
                profileData = fetched
            } catch {
                print("⚠️ Could not fetch applicant profile for AI ranking: \(error)")
                profileData = UserProfileData(
                    profile: SupabaseProfileData(
                        id: application.actorId,
                        username: nil,
                        fullName: application.name,
                        bio: nil,
                        role: nil,
                        profilePictureUrl: nil,
                        bannerUrl: nil,
                        location: application.location,
                        isVerified: false,
                        connectionCount: 0,
                        email: nil,
                        phoneNumber: nil
                    ),
                    artistProfile: nil,
                    projectCount: 0,
                    rating: nil
                )
            }
        }

        let rawApplication = dbApplicationsRaw.first(where: { $0.id.uuidString == application.id })
        let role = profileData.profile.role ?? profileData.artistProfile?.primaryRoles?.first ?? "Actor"
        let location = profileData.profile.location ?? application.location
        let bio = profileData.profile.bio ?? ""
        let skills = profileData.artistProfile?.skills ?? []
        let years = profileData.artistProfile?.yearsOfExperience ?? 0
        let hasPortfolio = rawApplication?.portfolioUrl?.isEmpty == false || profileData.projectCount > 0

        return AIApplicantContext(
            application_id: application.id,
            actor_id: application.actorId.uuidString,
            name: application.name,
            role: role,
            location: location,
            bio: bio,
            skills: skills,
            years_of_experience: years,
            portfolio_project_count: profileData.projectCount,
            has_portfolio: hasPortfolio,
            has_submitted_task: application.hasSubmittedTask,
            connection_count: profileData.profile.connectionCount,
            current_status: rawApplication?.status.rawValue ?? "portfolio_submitted"
        )
    }

    private func fallbackMatch(for applicant: AIApplicantContext, job: Job) -> ApplicantAIMatch {
        let jobText = [job.title, job.description, job.requirements, job.location, job.jobType]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let skillScore = skillMatchScore(skills: applicant.skills, jobText: jobText)
        let experienceScore = experienceMatchScore(years: applicant.years_of_experience, jobText: jobText)
        let locationScore = locationMatchScore(applicantLocation: applicant.location, jobLocation: job.location ?? "")
        let portfolioScore = portfolioQualityScore(projectCount: applicant.portfolio_project_count, hasPortfolio: applicant.has_portfolio)
        let reliabilityScore = reliabilityScore(hasSubmittedTask: applicant.has_submitted_task, connectionCount: applicant.connection_count, status: applicant.current_status)

        let weighted = Int(round(
            Double(skillScore) * 0.30 +
            Double(experienceScore) * 0.20 +
            Double(locationScore) * 0.15 +
            Double(portfolioScore) * 0.20 +
            Double(reliabilityScore) * 0.15
        ))

        let breakdown = ApplicantAIScoreBreakdown(
            skill: Int(round(Double(skillScore) * 0.30)),
            experience: Int(round(Double(experienceScore) * 0.20)),
            location: Int(round(Double(locationScore) * 0.15)),
            portfolio: Int(round(Double(portfolioScore) * 0.20)),
            reliability: Int(round(Double(reliabilityScore) * 0.15))
        )

        let explanation = """
        Strongest signals came from \(applicant.skills.isEmpty ? "overall profile fit" : "skills and profile fit"), \(applicant.has_portfolio ? "portfolio presence" : "limited portfolio depth"), and \(applicant.has_submitted_task ? "task submission reliability" : "basic application reliability").
        """

        return ApplicantAIMatch(score: max(0, min(100, weighted)), explanation: explanation, breakdown: breakdown)
    }

    private func skillMatchScore(skills: [String], jobText: String) -> Int {
        guard !jobText.isEmpty else { return skills.isEmpty ? 55 : 78 }
        guard !skills.isEmpty else { return 35 }
        let matched = skills.filter { jobText.contains($0.lowercased()) }.count
        if matched == 0 { return 45 }
        return min(100, 45 + (matched * 20))
    }

    private func experienceMatchScore(years: Int, jobText: String) -> Int {
        if years <= 0 { return 45 }
        let targetYears = parseYearsRequirement(from: jobText) ?? 2
        if years >= targetYears { return 90 }
        if years + 1 >= targetYears { return 75 }
        return 55
    }

    private func parseYearsRequirement(from text: String) -> Int? {
        let digits = text
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return digits.first(where: { $0 <= 30 })
    }

    private func locationMatchScore(applicantLocation: String, jobLocation: String) -> Int {
        guard !jobLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 70 }
        let applicant = applicantLocation.lowercased()
        let job = jobLocation.lowercased()
        if applicant.contains(job) || job.contains(applicant) { return 95 }
        let applicantParts = applicant.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let jobParts = job.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if applicantParts.contains(where: { jobParts.contains($0) }) { return 75 }
        return 45
    }

    private func portfolioQualityScore(projectCount: Int, hasPortfolio: Bool) -> Int {
        guard hasPortfolio else { return 30 }
        switch projectCount {
        case 8...: return 95
        case 4...7: return 82
        case 1...3: return 68
        default: return 55
        }
    }

    private func reliabilityScore(hasSubmittedTask: Bool, connectionCount: Int, status: String) -> Int {
        var score = hasSubmittedTask ? 82 : 58
        if status == "shortlisted" || status == "selected" { score += 8 }
        if connectionCount >= 5 { score += 5 }
        return min(score, 100)
    }

    private func makeAIScoreExplanation(name: String, explanation: String?, breakdown: ApplicantAIScoreBreakdown?) -> String {
        var lines: [String] = ["\(name) was evaluated against this job using CineMyst AI ranking."]
        if let explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("")
            lines.append(explanation)
        }
        if let breakdown {
            lines.append("")
            lines.append("Score breakdown")
            lines.append("Skill match: \(breakdown.skill) / 30")
            lines.append("Experience match: \(breakdown.experience) / 20")
            lines.append("Location match: \(breakdown.location) / 15")
            lines.append("Portfolio quality: \(breakdown.portfolio) / 20")
            lines.append("Activity / reliability: \(breakdown.reliability) / 15")
        }
        return lines.joined(separator: "\n")
    }

    private func showAIScoreExplanation(for application: ApplicationCard) {
        let title = application.aiMatchScore.map { "\($0)% match" } ?? "Match score"
        let message = application.aiScoreExplanation ?? "This candidate has not been AI-ranked yet."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    
    private func navigateToPortfolio(actorId: UUID) {
        print("🎭 Navigating to portfolio for actor: \(actorId.uuidString)")
        
        // Fetch actor's portfolio and navigate
        Task {
            do {
                struct ActorPortfolio: Codable {
                    let id: String
                    let userId: String
                    
                    enum CodingKeys: String, CodingKey {
                        case id
                        case userId = "user_id"
                    }
                }
                
                let portfolio: ActorPortfolio = try await supabase
                    .from("portfolios") 
                    .select("id, user_id")
                    .eq("user_id", value: actorId.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    let portfolioVC = PortfolioViewController()
                    portfolioVC.isOwnProfile = false
                    portfolioVC.portfolioId = portfolio.id
                    self.navigationController?.pushViewController(portfolioVC, animated: true)
                }
            } catch {
                print("❌ Error loading portfolio: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Portfolio Not Found",
                        message: "This user hasn't created a portfolio yet.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func viewSubmittedTask(applicationId: String) {
        print("📹 Viewing task submission for application: \(applicationId)")
        
        guard let appUUID = UUID(uuidString: applicationId) else {
            print("❌ Invalid application ID")
            return
        }
        
        // Fetch task submission
        Task {
            do {
                let submissions: [TaskSubmission] = try await supabase
                    .from("task_submissions")
                    .select()
                    .eq("application_id", value: appUUID.uuidString)
                    .order("submitted_at", ascending: false)
                    .execute()
                    .value
                
                guard let latestSubmission = submissions.first else {
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "No Submission",
                            message: "Task submission not found.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                await MainActor.run {
                    let videoVC = TaskVideoPlayerViewController()
                    videoVC.videoURL = latestSubmission.submissionUrl
                    videoVC.actorNotes = latestSubmission.actorNotes
                    self.navigationController?.pushViewController(videoVC, animated: true)
                }
            } catch {
                print("❌ Error loading task submission: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Could not load task submission.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ApplicationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredApplications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as! ApplicationCell
        let application = filteredApplications[indexPath.row]
        cell.configure(with: application)
        
        // Portfolio tap action
        cell.portfolioTapAction = { [weak self] in
            self?.navigateToPortfolio(actorId: application.actorId)
        }
        
        // Task tap action
        cell.taskTapAction = { [weak self] in
            if application.hasSubmittedTask {
                self?.viewSubmittedTask(applicationId: application.id)
            }
        }

        cell.scoreTapAction = { [weak self] in
            self?.showAIScoreExplanation(for: application)
        }
        
        cell.shortlistAction = { [weak self] in
            self?.toggleShortlist(at: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 132
    }
    
    private func toggleShortlist(at indexPath: IndexPath) {
        let application = filteredApplications[indexPath.row]
        let newShortlistStatus = !application.isShortlisted
        
        // Update locally
        filteredApplications[indexPath.row].isShortlisted = newShortlistStatus
        if let originalIndex = applications.firstIndex(where: { $0.id == application.id }) {
            applications[originalIndex].isShortlisted = newShortlistStatus
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        // Persist to database
        Task {
            await updateApplicationShortlistStatus(applicationId: application.id, isShortlisted: newShortlistStatus)
        }
    }
    
    private func updateApplicationShortlistStatus(applicationId: String, isShortlisted: Bool) async {
        do {
            guard let appUUID = UUID(uuidString: applicationId) else {
                print("❌ Invalid application ID")
                return
            }
            
            // Find the raw application
            guard let appIndex = dbApplicationsRaw.firstIndex(where: { $0.id.uuidString == applicationId }) else {
                print("❌ Application not found in raw data")
                return
            }
            
            let app = dbApplicationsRaw[appIndex]
            
            print("🔄 Updating application \(applicationId.prefix(8))")
            print("   Job ID: \(app.jobId.uuidString)")
            print("   Current status: \(app.status.rawValue)")
            print("   Shortlisting: \(isShortlisted)")
            
            // Determine new status - keep original status if unshortlisting
            let newStatus: Application.ApplicationStatus
            if isShortlisted {
                newStatus = .shortlisted
            } else {
                // When unshortlisting, revert to appropriate status based on what was submitted
                if let _ = app.portfolioUrl {
                    newStatus = .portfolioSubmitted
                } else {
                    newStatus = .taskSubmitted
                }
            }
            
            // Create updated application
            let updatedApp = Application(
                id: app.id,
                jobId: app.jobId,
                actorId: app.actorId,
                status: newStatus,
                portfolioUrl: app.portfolioUrl,
                portfolioSubmittedAt: app.portfolioSubmittedAt,
                appliedAt: app.appliedAt,
                updatedAt: Date()
            )
            
            // Update in database
            print("📤 Sending UPDATE to database for app: \(appUUID.uuidString)")
            try await supabase
                .from("applications")
                .update(updatedApp)
                .eq("id", value: appUUID.uuidString)
                .execute()
            
            print("✅ Database UPDATE completed")
            
            // Verify the update by fetching the record back
            let verifyApp: Application = try await supabase
                .from("applications")
                .select()
                .eq("id", value: appUUID.uuidString)
                .single()
                .execute()
                .value
            
            print("🔍 Verification fetch: App \(verifyApp.id.uuidString.prefix(8)) status = \(verifyApp.status.rawValue)")
            
            // AUTOMATIC JOB STATE TRANSITION: ACTIVE -> PENDING
            // If we just shortlisted someone, ensure the job moves to pending status
            if isShortlisted {
                do {
                    print("🔄 Checking job state transition for job: \(app.jobId.uuidString)")
                    // Simple update: always set to pending if we are shortlisting
                    // Use eq id to update the jobs table
                    try await supabase
                        .from("jobs")
                        .update(["status": "pending"])
                        .eq("id", value: app.jobId.uuidString)
                        // .eq("status", value: "active") // Optional: only if currently active
                        .execute()
                    
                    print("✅ Job status updated to PENDING for \(app.jobId.uuidString.prefix(8))")
                } catch {
                    print("⚠️ Note: Failed to update job status to pending (might already be pending/private/completed): \(error)")
                }
            }
            
            // Update local cache
            dbApplicationsRaw[appIndex] = updatedApp
            
            print("✅ Application \(applicationId.prefix(8)) shortlist status updated to: \(isShortlisted), new status: \(newStatus.rawValue)")
            
            // If shortlisting, update job status to pending
            if isShortlisted {
                print("📤 Calling updateJobStatusToPending for job: \(app.jobId.uuidString)")
                await updateJobStatusToPending(jobId: app.jobId)
            }
        } catch {
            print("❌ Error updating shortlist status: \(error)")
        }
    }
    
    private func updateJobStatusToPending(jobId: UUID) async {
        do {
            print("📥 Fetching current job status for: \(jobId.uuidString)")
            
            // Debug: Check authenticated user
            if let currentUser = supabase.auth.currentUser {
                print("🔐 Authenticated user ID: \(currentUser.id.uuidString)")
            } else {
                print("⚠️ No authenticated user found!")
            }
            
            // Fetch the current job from database to get latest status
            let currentJob: Job = try await supabase
                .from("jobs")
                .select()
                .eq("id", value: jobId.uuidString)
                .single()
                .execute()
                .value
            
            print("📋 Current job status: '\(currentJob.status?.rawValue ?? "nil")'")
            print("   Job title: \(currentJob.title ?? "Untitled")")
            print("   Job director_id: \(currentJob.directorId?.uuidString ?? "nil")")
            print("   Is active? \(currentJob.status == .active)")
            
            // Only update if job is currently active
            if currentJob.status == .active {
                print("🔄 Updating job from active to pending...")
                
                // Use raw SQL update via Supabase RPC as workaround for RLS
                struct UpdateJobStatusParams: Encodable {
                    let job_id: String
                    let new_status: String
                }
                
                let params = UpdateJobStatusParams(
                    job_id: jobId.uuidString,
                    new_status: "pending"
                )
                
                // Try direct update first
                do {
                    try await supabase.rpc("update_job_status", params: params).execute()
                    print("✅ Job \(jobId.uuidString.prefix(8)) status updated via RPC")
                } catch {
                    print("⚠️ RPC failed, trying direct update: \(error)")
                    
                    // Fallback to direct update with minimal payload
                    struct JobStatusUpdate: Encodable {
                        let status: String
                        let updated_at: String
                    }
                    
                    let update = JobStatusUpdate(
                        status: "pending",
                        updated_at: ISO8601DateFormatter().string(from: Date())
                    )
                    
                    try await supabase
                        .from("jobs")
                        .update(update)
                        .eq("id", value: jobId.uuidString)
                        .execute()
                    
                    print("✅ Job \(jobId.uuidString.prefix(8)) status updated via direct UPDATE")
                }
            } else {
                print("ℹ️ Job \(jobId.uuidString.prefix(8)) already has status: '\(currentJob.status?.rawValue ?? "nil")', not updating")
            }
        } catch {
            print("❌ Error updating job status: \(error)")
            print("   Error details: \(String(describing: error))")
            print("⚠️ NOTE: This is likely a Supabase RLS policy issue.")
            print("   The application was shortlisted successfully.")
        }
    }
}

import UIKit

class ApplicationCell: UITableViewCell {
    
    var shortlistAction: (() -> Void)?
    var portfolioTapAction: (() -> Void)?
    var taskTapAction: (() -> Void)?
    var scoreTapAction: (() -> Void)?
    
    private var taskLeadingWithConnected: NSLayoutConstraint!
    private var taskLeadingWithoutConnected: NSLayoutConstraint!
    
    private let themePlum = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0)
    
    // MARK: - UI Components
    
    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0).cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let portfolioLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "View Portfolio"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0)
        lbl.isUserInteractionEnabled = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let locationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let locationIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin.and.ellipse")
        iv.tintColor = .gray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let timeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let timeIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "clock")
        iv.tintColor = .gray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let connectedBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.12)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let connectedLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Connected"
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let taskBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 0.15)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let taskLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Task Submitted"
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(red: 0.15, green: 0.68, blue: 0.38, alpha: 1.0)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let scoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.10)
        btn.layer.cornerRadius = 13
        btn.layer.borderWidth = 1
        btn.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.16).cgColor
        btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        return btn
    }()
    
    
    // MARK: - Updated Shortlist Button
    
    private let shortlistButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 24
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        // Modern shadow
        btn.layer.shadowColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.3).cgColor
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 10
        
        return btn
    }()
    
    private let checkmarkIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        iv.image = UIImage(systemName: "checkmark", withConfiguration: config)
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    
    // MARK: Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    
    // MARK: Layout
    
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Add card container first
        contentView.addSubview(cardContainerView)
        
        // Add all subviews to card container
        cardContainerView.addSubview(profileImageView)
        cardContainerView.addSubview(nameLabel)
        cardContainerView.addSubview(portfolioLabel)
        cardContainerView.addSubview(locationIcon)
        cardContainerView.addSubview(locationLabel)
        cardContainerView.addSubview(timeIcon)
        cardContainerView.addSubview(timeLabel)
        
        cardContainerView.addSubview(connectedBadge)
        connectedBadge.addSubview(connectedLabel)
        
        cardContainerView.addSubview(taskBadge)
        taskBadge.addSubview(taskLabel)
        cardContainerView.addSubview(scoreButton)
        
        cardContainerView.addSubview(shortlistButton)
        shortlistButton.addSubview(checkmarkIcon)
        shortlistButton.addTarget(self, action: #selector(shortlistTapped), for: .touchUpInside)
        scoreButton.addTarget(self, action: #selector(scoreTapped), for: .touchUpInside)
        
        // Add tap gestures
        let portfolioTap = UITapGestureRecognizer(target: self, action: #selector(portfolioTapped))
        portfolioLabel.addGestureRecognizer(portfolioTap)
        
        let taskTap = UITapGestureRecognizer(target: self, action: #selector(taskBadgeTapped))
        taskBadge.addGestureRecognizer(taskTap)
        taskBadge.isUserInteractionEnabled = true
        
        
        NSLayoutConstraint.activate([
            // Card container constraints
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Profile image - larger and more prominent
            profileImageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 64),
            profileImageView.heightAnchor.constraint(equalToConstant: 64),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            
            portfolioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            portfolioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            locationIcon.topAnchor.constraint(equalTo: portfolioLabel.bottomAnchor, constant: 6),
            locationIcon.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 12),
            locationIcon.heightAnchor.constraint(equalToConstant: 12),
            
            locationLabel.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 4),
            
            timeIcon.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            timeIcon.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 10),
            timeIcon.widthAnchor.constraint(equalToConstant: 12),
            timeIcon.heightAnchor.constraint(equalToConstant: 12),
            
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timeIcon.trailingAnchor, constant: 4),
            
            
            // Connected badge
            connectedBadge.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 8),
            connectedBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            connectedBadge.heightAnchor.constraint(equalToConstant: 24),
            
            connectedLabel.centerYAnchor.constraint(equalTo: connectedBadge.centerYAnchor),
            connectedLabel.leadingAnchor.constraint(equalTo: connectedBadge.leadingAnchor, constant: 10),
            connectedLabel.trailingAnchor.constraint(equalTo: connectedBadge.trailingAnchor, constant: -10),
            
            
            // Task badge
            taskBadge.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 8),
            taskBadge.heightAnchor.constraint(equalToConstant: 24),
            
            taskLabel.centerYAnchor.constraint(equalTo: taskBadge.centerYAnchor),
            taskLabel.leadingAnchor.constraint(equalTo: taskBadge.leadingAnchor, constant: 10),
            taskLabel.trailingAnchor.constraint(equalTo: taskBadge.trailingAnchor, constant: -10),

            scoreButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 14),
            scoreButton.trailingAnchor.constraint(equalTo: shortlistButton.leadingAnchor, constant: -10),
            scoreButton.heightAnchor.constraint(equalToConstant: 28),
            
            
            // Shortlist Button - modern floating style
            shortlistButton.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor),
            shortlistButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -16),
            shortlistButton.widthAnchor.constraint(equalToConstant: 48),
            shortlistButton.heightAnchor.constraint(equalToConstant: 48),
            
            checkmarkIcon.centerXAnchor.constraint(equalTo: shortlistButton.centerXAnchor),
            checkmarkIcon.centerYAnchor.constraint(equalTo: shortlistButton.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 16),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        
        // Dual constraints for task badge
        taskLeadingWithConnected =
            taskBadge.leadingAnchor.constraint(equalTo: connectedBadge.trailingAnchor, constant: 6)
        
        taskLeadingWithoutConnected =
            taskBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor)
        
        taskLeadingWithConnected.isActive = true
    }
    
    
    // MARK: Configure
    
    func configure(with application: ApplicationCard) {
        nameLabel.text = application.name
        locationLabel.text = application.location
        timeLabel.text = application.timeAgo
        profileImageView.image = UIImage(named: application.profileImage)
        
        
        // Connected badge visibility
        connectedBadge.isHidden = !application.isConnected
        
        // Task badge visibility
        taskBadge.isHidden = !application.hasSubmittedTask
        
        if application.isConnected {
            taskLeadingWithoutConnected.isActive = false
            taskLeadingWithConnected.isActive = true
        } else {
            taskLeadingWithConnected.isActive = false
            taskLeadingWithoutConnected.isActive = true
        }

        if let aiScore = application.aiMatchScore {
            scoreButton.isHidden = false
            scoreButton.setTitle("\(aiScore)% match", for: .normal)
        } else {
            scoreButton.isHidden = true
            scoreButton.setTitle(nil, for: .normal)
        }
        
        
        // Shortlist UI
        if application.isShortlisted {
            shortlistButton.backgroundColor = themePlum
            shortlistButton.layer.shadowOpacity = 0
            checkmarkIcon.tintColor = .white
        } else {
            shortlistButton.backgroundColor = .white
            shortlistButton.layer.shadowOpacity = 0.25
            checkmarkIcon.tintColor = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
        }
    }
    
    
    @objc private func shortlistTapped() {
        shortlistAction?()
    }
    
    @objc private func portfolioTapped() {
        portfolioTapAction?()
    }
    
    @objc private func taskBadgeTapped() {
        taskTapAction?()
    }

    @objc private func scoreTapped() {
        scoreTapAction?()
    }
}
