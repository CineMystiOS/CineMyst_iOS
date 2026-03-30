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
}

class ApplicationsViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    private var applications: [ApplicationCard] = []
    private var filteredApplications: [ApplicationCard] = []
    private var isFilteredByAI = false
    // Raw data for debug/info display
    private var dbApplicationsRaw: [Application] = []
    private var taskSubmissionsMap: [UUID: [TaskSubmission]] = [:]
    
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
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let searchBar: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search by name, location, or email..."
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 16
        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowOffset = CGSize(width: 0, height: 2)
        tf.layer.shadowRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 50))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.tintColor = .gray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let filtersButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(" Filters", for: .normal)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.06
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 8
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let filterIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "slider.horizontal.3")
        iv.tintColor = .black
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let topApplicantsButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Top Applicants ", for: .normal)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.06
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 8
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let chevronIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = .black
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let aiFilterButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Filtered by AI", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0)
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.3).cgColor
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
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        setupNavigationBar()
        setupUI()
        loadApplicationsForJob()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Applications"
        if let jobTitle = job?.title {
            subtitleLabel.text = jobTitle
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let profileBtn = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(profileTapped))
        profileBtn.tintColor = .darkGray
        navigationItem.rightBarButtonItem = profileBtn
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        backBtn.tintColor = .darkGray
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
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(searchBar)
        searchBar.addSubview(searchIcon)
        contentView.addSubview(filtersButton)
        filtersButton.addSubview(filterIcon)
        contentView.addSubview(topApplicantsButton)
        topApplicantsButton.addSubview(chevronIcon)
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
            
            chevronIcon.centerYAnchor.constraint(equalTo: topApplicantsButton.centerYAnchor),
            chevronIcon.trailingAnchor.constraint(equalTo: topApplicantsButton.trailingAnchor, constant: -12),
            chevronIcon.widthAnchor.constraint(equalToConstant: 10),
            chevronIcon.heightAnchor.constraint(equalToConstant: 10),
            
            aiFilterButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            aiFilterButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            aiFilterButton.heightAnchor.constraint(equalToConstant: 38),
            
            countLabel.topAnchor.constraint(equalTo: filtersButton.bottomAnchor, constant: 20),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            tableView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 700)
        ])
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
        topApplicantsButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
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
    
    @objc private func sortTapped() {
        showSortMenu()
    }
    
    @objc private func aiFilterTapped() {
        isFilteredByAI.toggle()
    }
    
    private func showFilterMenu() {
        let alert = UIAlertController(title: "Filter Applications", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All Applications", style: .default, handler: { _ in
            self.filteredApplications = self.applications
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "By location", style: .default))
        alert.addAction(UIAlertAction(title: "Task Submitted", style: .default, handler: { _ in
            self.filteredApplications = self.applications.filter { $0.hasSubmittedTask }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Connections (100+)", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSortMenu() {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Most Recent", style: .default))
        alert.addAction(UIAlertAction(title: "Top Applicants", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
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
        
        cell.shortlistAction = { [weak self] in
            self?.toggleShortlist(at: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
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
            
            print("📋 Current job status: '\(currentJob.status.rawValue)'")
            print("   Job title: \(currentJob.title)")
            print("   Job director_id: \(currentJob.directorId.uuidString)")
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
                print("ℹ️ Job \(jobId.uuidString.prefix(8)) already has status: '\(currentJob.status.rawValue)', not updating")
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
        
        cardContainerView.addSubview(shortlistButton)
        shortlistButton.addSubview(checkmarkIcon)
        shortlistButton.addTarget(self, action: #selector(shortlistTapped), for: .touchUpInside)
        
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
}
