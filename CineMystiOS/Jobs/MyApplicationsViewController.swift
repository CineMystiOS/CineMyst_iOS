import UIKit
import Supabase

class MyApplicationsViewController: UIViewController {

    // MARK: - Properties
    private var applications: [Application] = []
    private var jobs: [Job] = []
    private let backgroundGradient = CAGradientLayer()

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "My Applications"
        lbl.font = UIFont.boldSystemFont(ofSize: 26)
        lbl.textColor = UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1)
        return lbl
    }()
    
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Track your casting journey in one place"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .gray
        return lbl
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupTheme()
        setupLayout()
        loadApplications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        loadApplications()
    }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            // Restore tab bar only
            tabBarController?.tabBar.isHidden = false

            // Restore floating button if you hid it above:
            // if let tb = tabBarController as? CineMystTabBarController {
            //     tb.setFloatingButton(hidden: false)
            // }
        }


    // MARK: - Layout Setup
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        [titleLabel, subtitleLabel, stackView].forEach {
            contentView.addSubview($0)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
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
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = CineMystTheme.ink
        subtitleLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
    }

    // MARK: - Segment Changed

    // MARK: - Load Applications
    private func loadApplications() {
        Task {
            do {
                guard let currentUser = supabase.auth.currentUser else {
                    print("❌ No current user found for applications")
                    return
                }
                
                let actorId = currentUser.id.uuidString
                print("📋 Fetching applications for actor: \(actorId)")
                
                // Fetch applications for current user
                let apps: [Application] = try await supabase
                    .from("applications")
                    .select()
                    .eq("actor_id", value: actorId)
                    .execute()
                    .value
                
                print("✅ Fetched \(apps.count) applications")
                self.applications = apps
                
                // Fetch all jobs
                print("📋 Fetching all jobs for matching...")
                let fetchedJobs: [Job] = try await supabase
                    .from("jobs")
                    .select()
                    .execute()
                    .value
                
                print("✅ Fetched \(fetchedJobs.count) jobs total")
                self.jobs = fetchedJobs
                
                // Load cards on main actor
                await MainActor.run {
                    self.displayAllApplications()
                }
            } catch {
                print("❌ Error loading applications/jobs: \(error)")
                await MainActor.run {
                    self.displayAllApplications()
                }
            }
        }
    }

    @MainActor
    private func displayAllApplications() {
        print("🎴 Loading all application cards")
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if applications.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "You haven't applied to any jobs yet."
            emptyLabel.textColor = .gray
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 15)
            emptyLabel.numberOfLines = 0
            stackView.addArrangedSubview(emptyLabel)
            return
        }

        // Sort by date (newest first)
        let sortedApps = applications.sorted { $0.appliedAt > $1.appliedAt }

        for app in sortedApps {
            if let job = jobs.first(where: { $0.id == app.jobId }) {
                stackView.addArrangedSubview(
                    makeJobCard(job: job, application: app)
                )
            }
        }
    }

    // MARK: - Cards by Status

    // MARK: - Card View Builder
    private func makeJobCard(job: Job, application: Application) -> UIView {
        
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.layer.shadowRadius = 6
        
        let title = UILabel()
        title.text = job.title ?? "Untitled Job"
        title.numberOfLines = 2
        title.font = UIFont.boldSystemFont(ofSize: 16)
        
        let company = UILabel()
        company.text = job.companyName ?? "CineMyst Production"
        company.font = UIFont.systemFont(ofSize: 14)
        company.textColor = .gray
        
        let locationIcon = UIImageView(image: UIImage(systemName: "location.fill"))
        locationIcon.tintColor = .gray
        locationIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        
        let locationLabel = UILabel()
        locationLabel.text = job.location ?? "Remote"
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        
        let payLabel = UILabel()
        payLabel.text = "₹\(job.ratePerDay ?? 0)/day"
        payLabel.font = UIFont.systemFont(ofSize: 14)

        let tag1 = makeTag(job.jobType ?? "Project")
        let statusTag = makeTag(application.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)

        let appliedLabel = UILabel()
        appliedLabel.text = "Applied \(timeAgoString(from: application.appliedAt))"
        appliedLabel.font = UIFont.systemFont(ofSize: 13)
        appliedLabel.textColor = .gray
        
        let trackButton = UIButton(type: .system)
        trackButton.setTitle("Track Status", for: .normal)
        trackButton.setTitleColor(.white, for: .normal)
        trackButton.backgroundColor = CineMystTheme.brandPlum
        trackButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        trackButton.layer.cornerRadius = 10
        trackButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Store application ID as tag string using objc_setAssociatedObject
        // Store application ID
        trackButton.accessibilityIdentifier = application.id.uuidString
        trackButton.addTarget(self, action: #selector(trackButtonTapped(_:)), for: .touchUpInside)


        let h1 = UIStackView(arrangedSubviews: [locationIcon, locationLabel, payLabel])
        h1.axis = .horizontal
        h1.spacing = 6
        h1.alignment = .center
        
        let tagsRow = UIStackView(arrangedSubviews: [tag1, statusTag, UIView()])
        tagsRow.axis = .horizontal
        tagsRow.spacing = 8
        tagsRow.alignment = .center
        
        
        let footer = UIStackView(arrangedSubviews: [appliedLabel, UIView(), trackButton])
        footer.axis = .horizontal
        footer.alignment = .center

        let stack = UIStackView(arrangedSubviews: [title, company, h1, tagsRow, footer])
        stack.axis = .vertical
        stack.spacing = 10
        
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    @objc private func trackButtonTapped(_ sender: UIButton) {
        guard let appId = sender.accessibilityIdentifier,
              let appUUID = UUID(uuidString: appId),
              let app = applications.first(where: { $0.id == appUUID }),
              let job = jobs.first(where: { $0.id == app.jobId }) else { return }
        
        let status = app.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        
        let message = """
        Job: \(job.title ?? "Project")
        Status: \(status)
        Applied: \(timeAgoString(from: app.appliedAt))
        """
        
        showAlert(title: "Application Status", message: message)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }


    private func makeTag(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)

        container.setContentHuggingPriority(.required, for: .horizontal)
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6)

        ])

        return container
    }
}

extension UILabel {
    func padding(_ vertical: CGFloat, _ horizontal: CGFloat) {
        self.drawText(in: self.bounds.insetBy(dx: -horizontal, dy: -vertical))
    }
}
