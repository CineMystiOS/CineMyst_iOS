//
//  ShortlistedViewController.swift
//  CineMystApp
//
import UIKit
import Supabase

// MARK: - Model
struct ShortlistedCandidate {
    let actorId: UUID
    let name: String
    let experience: String
    let location: String
    let daysAgo: String
    let isConnected: Bool
    let isTaskSubmitted: Bool
    let profileImage: UIImage?
}


// MARK: - Custom Cell
final class ShortlistedCell: UITableViewCell {

    static let id = "ShortlistedCell"

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 28
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let experienceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .darkGray
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

    private let clockLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let connectedTag: UILabel = {
        let lbl = UILabel()
        lbl.text = "Connected"
        lbl.textColor = UIColor(red: 160/255, green: 80/255, blue: 235/255, alpha: 1)
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textAlignment = .center
        lbl.backgroundColor = UIColor(red: 245/255, green: 235/255, blue: 255/255, alpha: 1)
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let taskSubmittedTag: UILabel = {
        let lbl = UILabel()
        lbl.text = "Task Submitted"
        lbl.textColor = UIColor(red: 61/255, green: 160/255, blue: 80/255, alpha: 1)
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textAlignment = .center
        lbl.backgroundColor = UIColor(red: 225/255, green: 255/255, blue: 230/255, alpha: 1)
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let selectionCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.lightGray.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    func setSelection(_ isSelected: Bool) {
        innerCircle.isHidden = !isSelected
        selectionCircle.layer.borderColor = isSelected ? UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1).cgColor : UIColor.lightGray.cgColor
    }
    
    private let innerCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 7
        v.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let chatButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "bubble.left.and.bubble.right"), for: .normal)
        btn.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    var onChatTapped: (() -> Void)?

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }


    // MARK: Configure
    func configure(with candidate: ShortlistedCandidate) {
        profileImageView.image = candidate.profileImage
        nameLabel.text = candidate.name
        experienceLabel.text = candidate.experience
        locationLabel.attributedText = iconText("mappin.and.ellipse", text: candidate.location)
        clockLabel.attributedText = iconText("clock", text: candidate.daysAgo)

        connectedTag.isHidden = !candidate.isConnected
        taskSubmittedTag.isHidden = !candidate.isTaskSubmitted
    }
    
    @objc private func chatButtonTapped() {
        onChatTapped?()
    }


    // MARK: Tag + Icon builder
    private func iconText(_ icon: String, text: String) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: icon)
        attachment.bounds = CGRect(x: 0, y: -2, width: 12, height: 12)

        let attr = NSMutableAttributedString(attachment: attachment)
        attr.append(NSAttributedString(string: "  \(text)"))
        return attr
    }


    // MARK: Layout
    private func setupUI() {
        contentView.addSubview(selectionCircle)
        selectionCircle.addSubview(innerCircle)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(experienceLabel)
        contentView.addSubview(locationLabel)
        contentView.addSubview(clockLabel)
        contentView.addSubview(connectedTag)
        contentView.addSubview(taskSubmittedTag)
        contentView.addSubview(chatButton)
        
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([

            selectionCircle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectionCircle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionCircle.widthAnchor.constraint(equalToConstant: 24),
            selectionCircle.heightAnchor.constraint(equalToConstant: 24),

            innerCircle.centerXAnchor.constraint(equalTo: selectionCircle.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: selectionCircle.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 14),
            innerCircle.heightAnchor.constraint(equalToConstant: 14),

            profileImageView.leadingAnchor.constraint(equalTo: selectionCircle.trailingAnchor, constant: 12),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            profileImageView.widthAnchor.constraint(equalToConstant: 56),
            profileImageView.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),

            experienceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            experienceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: experienceLabel.bottomAnchor, constant: 6),

            clockLabel.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 14),
            clockLabel.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),

            connectedTag.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            connectedTag.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            connectedTag.heightAnchor.constraint(equalToConstant: 20),
            connectedTag.widthAnchor.constraint(equalToConstant: 85),

            taskSubmittedTag.leadingAnchor.constraint(equalTo: connectedTag.trailingAnchor, constant: 10),
            taskSubmittedTag.centerYAnchor.constraint(equalTo: connectedTag.centerYAnchor),
            taskSubmittedTag.heightAnchor.constraint(equalToConstant: 20),
            taskSubmittedTag.widthAnchor.constraint(equalToConstant: 110),

            chatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.bottomAnchor.constraint(equalTo: connectedTag.bottomAnchor, constant: 16)
        ])
    }
}



// MARK: - ShortlistedViewController
final class ShortlistedViewController: UIViewController {

    var job: Job?
    var showOnlySelected: Bool = false
    private var tableView = UITableView(frame: .zero, style: .plain)
    private var candidates: [ShortlistedCandidate] = []
    private let backgroundGradient = CAGradientLayer()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "2 applications"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let cueCastLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Cue Cast"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = CineMystTheme.ink
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let hireNowButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Hire This Actor", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 24
        btn.alpha = 0.5
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var selectedActorId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CineMystTheme.pinkPale
        setupTheme()
        setupNavBar()
        setupUI()
        setupTable()
        loadShortlistedCandidates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadShortlistedCandidates() // Refresh when view appears
    }


    // MARK: Navigation Bar
    private func setupNavBar() {

        navigationItem.title = "Cue Cast"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: CineMystTheme.ink,
            .font: UIFont.systemFont(ofSize: 22, weight: .bold)
        ]

        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backAction)
        )

        backBtn.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        navigationItem.leftBarButtonItem = backBtn
    }

    private func setupTheme() {
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

    @objc private func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Load Shortlisted
    private func loadShortlistedCandidates() {
        Task {
            do {
                guard let job = job else {
                    print("❌ No job provided to ShortlistedViewController")
                    return
                }
                
                print("🔍 Loading shortlisted candidates for job: \(job.id.uuidString)")
                
                // Fetch shortlisted/selected applications
                var query = supabase
                    .from("applications")
                    .select()
                    .eq("job_id", value: job.id.uuidString)
                
                if showOnlySelected {
                    query = query.eq("status", value: "selected")
                } else {
                    query = query.in("status", values: ["shortlisted", "selected"])
                }
                
                let shortlistedApps: [Application] = try await query
                    .execute()
                    .value
                
                print("📊 Found \(shortlistedApps.count) shortlisted applications")
                for app in shortlistedApps {
                    print("   - App \(app.id.uuidString.prefix(8)): status=\(app.status.rawValue)")
                }
                
                // Fetch user profiles for all actors
                var userProfiles: [UUID: (name: String, avatar: UIImage?)] = [:]
                for app in shortlistedApps {
                    if let profile = try? await self.fetchUserProfile(userId: app.actorId) {
                        userProfiles[app.actorId] = profile
                    }
                }
                
                // Convert to ShortlistedCandidate with real user data
                self.candidates = shortlistedApps.map { app in
                    let userData = userProfiles[app.actorId]
                    return ShortlistedCandidate(
                        actorId: app.actorId,
                        name: userData?.name ?? "Applicant \(app.id.uuidString.prefix(8))",
                        experience: "Task Submitted",
                        location: "India",
                        daysAgo: self.timeAgoString(from: app.appliedAt),
                        isConnected: false,
                        isTaskSubmitted: app.status == .taskSubmitted || app.status == .shortlisted || app.status == .selected,
                        profileImage: userData?.avatar ?? UIImage(named: "avatar_placeholder")
                    )
                }
                
                print("✅ Mapped \(self.candidates.count) candidates")
                
                DispatchQueue.main.async {
                    print("🔄 Updating UI: \(self.candidates.count) applications")
                    self.subtitleLabel.text = "\(self.candidates.count) applications"
                    self.tableView.reloadData()
                    print("✅ TableView reloaded")
                }
            } catch {
                print("❌ Error loading shortlisted candidates: \(error)")
            }
        }
    }
    
    private func fetchUserProfile(userId: UUID) async throws -> (name: String, avatar: UIImage?) {
        struct UserProfile: Codable {
            let fullName: String?
            let username: String?
            let avatarUrl: String?
            
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case username
                case avatarUrl = "avatar_url"
            }
        }
        
        let profile: UserProfile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        let name = profile.fullName ?? profile.username ?? "User \(userId.uuidString.prefix(8))"
        
        // Load avatar if URL exists
        var avatar: UIImage?
        if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                avatar = image
            }
        }
        
        return (name, avatar)
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


    // MARK: UI
    private func setupUI() {
        view.addSubview(cueCastLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(hireNowButton)

        NSLayoutConstraint.activate([
            cueCastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cueCastLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: cueCastLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: cueCastLabel.bottomAnchor, constant: 4),

            hireNowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            hireNowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            hireNowButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            hireNowButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        hireNowButton.addTarget(self, action: #selector(didTapHireNow), for: .touchUpInside)
    }

    private func setupTable() {
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(ShortlistedCell.self, forCellReuseIdentifier: ShortlistedCell.id)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: hireNowButton.topAnchor, constant: -10)
        ])
    }

    @objc private func didTapHireNow() {
        guard let actorId = selectedActorId,
              let candidate = candidates.first(where: { $0.actorId == actorId }) else { return }
        finalizeHiring(candidate: candidate)
    }
    
    // MARK: - Finalize Hiring
    
    private func finalizeHiring(candidate: ShortlistedCandidate) {
        let alert = UIAlertController(
            title: "Finalize Role",
            message: "Are you sure you want to select \(candidate.name) for this role? This will mark the job as completed.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes, Hire", style: .default) { [weak self] _ in
            self?.executeHiring(candidate: candidate)
        })
        
        present(alert, animated: true)
    }
    
    private func executeHiring(candidate: ShortlistedCandidate) {
        Task {
            do {
                guard let job = job else { return }
                
                // 1. Update application status to 'selected'
                try await supabase
                    .from("applications")
                    .update(["status": "selected"])
                    .eq("job_id", value: job.id.uuidString)
                    .eq("actor_id", value: candidate.actorId.uuidString)
                    .execute()
                
                // 2. Update job status to 'completed'
                try await supabase
                    .from("jobs")
                    .update(["status": "completed"])
                    .eq("id", value: job.id.uuidString)
                    .execute()
                
                print("🏆 Hiring finalized for \(candidate.name)! Job \(job.id.uuidString.prefix(8)) is now COMPLETED.")
                
                await MainActor.run {
                    let success = UIAlertController(title: "Success", message: "\(candidate.name) has been hired! The job is now moved to Completed.", preferredStyle: .alert)
                    success.addAction(UIAlertAction(title: "Awesome", style: .default) { [weak self] _ in
                        guard let self = self, let nav = self.navigationController else { return }
                        if let dashboard = nav.viewControllers.first(where: { $0 is PostedJobsDashboardViewController }) {
                            nav.popToViewController(dashboard, animated: true)
                        } else {
                            nav.popViewController(animated: true)
                        }
                    })
                    self.present(success, animated: true)
                }
            } catch {
                print("❌ Hiring failed: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to finalize hiring: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Messaging
    
    private func openChatWithApplicant(actorId: UUID, name: String) {
        Task {
            do {
                let conversation = try await MessagesService.shared.getOrCreateConversation(withUserId: actorId)
                
                await MainActor.run {
                    let chatVC = ChatViewController()
                    chatVC.conversationId = conversation.id
                    chatVC.otherUserName = name
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to start conversation: \(error.localizedDescription)")
                }
            }
        }
    }
}


// MARK: - Table Delegate
extension ShortlistedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let candidate = candidates[indexPath.row]
        selectedActorId = candidate.actorId
        
        // Update Hire button state
        hireNowButton.alpha = 1.0
        hireNowButton.isEnabled = true
        
        tableView.reloadData()
    }
}

// MARK: - Table DataSource
extension ShortlistedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("📊 TableView asking for row count: \(candidates.count)")
        return candidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShortlistedCell.id, for: indexPath) as! ShortlistedCell
        let candidate = candidates[indexPath.row]

        cell.configure(with: candidate)
        cell.setSelection(candidate.actorId == selectedActorId)
        cell.selectionStyle = .none
        
        // Set chat button action
        cell.onChatTapped = { [weak self] in
            self?.openChatWithApplicant(actorId: candidate.actorId, name: candidate.name)
        }
        
        return cell
    }
}
