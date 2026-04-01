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
    
    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Active", "Pending", "Completed"])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = .white
        sc.selectedSegmentTintColor = UIColor.white
        sc
            .setTitleTextAttributes(
                [.foregroundColor: UIColor.black],
                for: .selected
            )
        sc.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
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
        
        [titleLabel, segmentedControl, subtitleLabel, stackView].forEach {
            contentView.addSubview($0)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
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

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 42),
            
            subtitleLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
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
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 26) ?? UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = CineMystTheme.ink
        subtitleLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        segmentedControl.selectedSegmentTintColor = CineMystTheme.brandPlum
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: CineMystTheme.brandPlum.withAlphaComponent(0.65)], for: .normal)
    }

    // MARK: - Segment Changed
    @objc private func segmentChanged() {
        loadCardsFor(segment: segmentedControl.selectedSegmentIndex)
    }

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
                
                // Load first segment on main actor
                await MainActor.run {
                    loadCardsFor(segment: segmentedControl.selectedSegmentIndex)
                }
            } catch {
                print("❌ Error loading applications/jobs: \(error)")
                // Fallback: try to show applications even if status mapping fails
                await MainActor.run {
                    loadCardsFor(segment: segmentedControl.selectedSegmentIndex)
                }
            }
        }
    }

    // MARK: - Load Cards by Status
    @MainActor
    private func loadCardsFor(segment: Int) {
        print("🎴 Loading cards for segment: \(segment)")
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch segment {
        case 0: 
            print("🔍 Active segment: Status contains .portfolioSubmitted")
            loadActiveCards()
        case 1: 
            print("🔍 Pending segment: Status contains .taskSubmitted")
            loadPendingCards()
        case 2: 
            print("🔍 Completed segment: Status contains .selected or .shortlisted")
            loadCompletedCards()
        default: break
        }
    }

    // MARK: - Cards by Status
    private func loadActiveCards() {
        // Including portfolioSubmitted and shortlisted in Active
        let activeApps = applications.filter { $0.status == .portfolioSubmitted || $0.status == .shortlisted }
        
        if activeApps.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No active applications"
            emptyLabel.textColor = .gray
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        for app in activeApps {
            if let job = jobs.first(where: { $0.id == app.jobId }) {
                stackView.addArrangedSubview(
                    makeJobCard(
                        job: job,
                        application: app,
                        statusButtonTitle: "Go to Task",
                        statusColor: UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
                    )
                )
            }
        }
    }
    
    private func loadPendingCards() {
        let pendingApps = applications.filter { $0.status == .taskSubmitted }
        
        if pendingApps.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No pending applications"
            emptyLabel.textColor = .gray
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        for app in pendingApps {
            if let job = jobs.first(where: { $0.id == app.jobId }) {
                stackView.addArrangedSubview(
                    makeJobCard(
                        job: job,
                        application: app,
                        statusButtonTitle: "Under Review",
                        statusColor: .systemOrange
                    )
                )
            }
        }
    }
    
    private func loadCompletedCards() {
        // Including shortlisted in completed/successful bucket for now to ensure visibility
        let completedApps = applications.filter { $0.status == .selected || $0.status == .shortlisted }
        
        if completedApps.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No completed applications"
            emptyLabel.textColor = .gray
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        for app in completedApps {
            if let job = jobs.first(where: { $0.id == app.jobId }) {
                stackView.addArrangedSubview(
                    makeJobCard(
                        job: job,
                        application: app,
                        statusButtonTitle: "Booked",
                        statusColor: .systemGreen
                    )
                )
            }
        }
    }

    // MARK: - Card View Builder
    private func makeJobCard(job: Job, application: Application, statusButtonTitle: String, statusColor: UIColor) -> UIView {
        
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
        
        let statusButton = UIButton(type: .system)
        statusButton.setTitle(statusButtonTitle, for: .normal)
        statusButton.setTitleColor(.white, for: .normal)
        statusButton.backgroundColor = statusColor
        statusButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        statusButton.layer.cornerRadius = 10
        statusButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        
        // Store application ID as tag string using objc_setAssociatedObject
        statusButton.accessibilityIdentifier = application.id.uuidString
        statusButton.addTarget(self, action: #selector(statusButtonTapped(_:)), for: .touchUpInside)


        let h1 = UIStackView(arrangedSubviews: [locationIcon, locationLabel, payLabel])
        h1.axis = .horizontal
        h1.spacing = 6
        h1.alignment = .center
        
        let tagsRow = UIStackView(arrangedSubviews: [tag1, statusTag, UIView()])
        tagsRow.axis = .horizontal
        tagsRow.spacing = 8
        tagsRow.alignment = .center
        
        
        let footer = UIStackView(arrangedSubviews: [appliedLabel, UIView(), statusButton])
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
    
    @objc private func statusButtonTapped(_ sender: UIButton) {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Active section - go to task
            let vc = TaskDetailsViewController()
            if let appId = sender.accessibilityIdentifier,
               let appUUID = UUID(uuidString: appId),
               let app = applications.first(where: { $0.id == appUUID }) {
                vc.job = jobs.first(where: { $0.id == app.jobId })
            }
            navigationController?.pushViewController(vc, animated: true)
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
