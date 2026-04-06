import UIKit
import Supabase

// MARK: - Colors & Helpers
fileprivate extension UIColor {
    static let themePlum = CineMystTheme.brandPlum
    static let softGrayBg = CineMystTheme.plumMist
}

fileprivate func makeShadow(on view: UIView, radius: CGFloat = 8, yOffset: CGFloat = 2, opacity: Float = 0.08) {
    view.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.18).cgColor
    view.layer.shadowOpacity = opacity
    view.layer.shadowRadius = radius
    view.layer.shadowOffset = CGSize(width: 0, height: yOffset)
    view.layer.masksToBounds = false
}

// MARK: - JobsViewController
final class JobsViewController: UIViewController, UIScrollViewDelegate {
    
    // Theme
    private let themeColor = UIColor.themePlum
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowTop = UIView()
    private let ambientGlowBottom = UIView()
    
    // Core UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Search Bar
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search jobs"
        sb.searchBarStyle = .minimal
        sb.backgroundImage = UIImage()
        return sb
    }()
    
    // Title bar
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Explore Jobs"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = CineMystTheme.ink
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Discover your next role"
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        return l
    }()
    private lazy var bookmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        btn.setImage(UIImage(systemName: "bookmark", withConfiguration: config), for: .normal)
        btn.tintColor = CineMystTheme.brandPlum
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()
    private lazy var filterButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        btn.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config), for: .normal)
        btn.tintColor = CineMystTheme.brandPlum
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()
    
    // Search bar container
    private let searchBarContainer = UIView()
    
    // Post buttons
    private let postButtonsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()
    
    // Curated header
    private let curatedLabel: UILabel = {
        let l = UILabel()
        l.text = "Curated for You"
        l.font = .systemFont(ofSize: 21, weight: .bold)
        l.textColor = CineMystTheme.ink
        return l
    }()
    private let curatedSubtitle: UILabel = {
        let l = UILabel()
        l.text = "Opportunities that match your profile"
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.58)
        l.numberOfLines = 2
        return l
    }()
    
    // Job list
    private let jobListStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        return s
    }()
    
    // Dim + Filter
    private var dimView = UIView()
    private var filterVC: FilterScrollViewController?
    
    // Jobs data
    private var allJobs: [Job] = []
    private var filteredJobs: [Job] = []
    
    // Active filters
    private var activeRoleFilter: String?
    private var activePositionFilter: String?
    private var activeProjectFilter: String?
    private var activeEarningFilter: Float?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        
        searchBar.delegate = self
        setupScrollView()
        setupTitleBar()
        setupSearchBar()
        setupPostButtons()
        setupCuratedAndJobs()
        setupBottomSpacing()
        
        filterButton.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(openSavedPosts), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowTop.layer.cornerRadius = ambientGlowTop.bounds.width / 2
        ambientGlowBottom.layer.cornerRadius = ambientGlowBottom.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadJobCards()
    }
    
    // MARK: - Setup UI
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

        ambientGlowTop.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.16)
        ambientGlowTop.layer.shadowColor = CineMystTheme.brandPlum.cgColor
        ambientGlowTop.layer.shadowOpacity = 0.22
        ambientGlowTop.layer.shadowRadius = 80
        ambientGlowTop.layer.shadowOffset = .zero

        ambientGlowBottom.backgroundColor = CineMystTheme.deepPlumMid.withAlphaComponent(0.11)
        ambientGlowBottom.layer.shadowColor = CineMystTheme.deepPlumMid.cgColor
        ambientGlowBottom.layer.shadowOpacity = 0.16
        ambientGlowBottom.layer.shadowRadius = 90
        ambientGlowBottom.layer.shadowOffset = .zero

        [ambientGlowTop, ambientGlowBottom].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ambientGlowTop.widthAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.heightAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.topAnchor.constraint(equalTo: view.topAnchor, constant: -26),
            ambientGlowTop.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 22),

            ambientGlowBottom.widthAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.heightAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -82),
            ambientGlowBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 42)
        ])
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupTitleBar() {
        styleTopActionButton(bookmarkButton)
        styleTopActionButton(filterButton)

        let titleBar = UIStackView(arrangedSubviews: [titleLabel, UIView(), bookmarkButton, filterButton])
        titleBar.axis = .horizontal
        titleBar.alignment = .center
        titleBar.spacing = 8
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleBar)
        contentView.addSubview(subtitleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupSearchBar() {
        contentView.addSubview(searchBarContainer)
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.backgroundColor = UIColor.white.withAlphaComponent(0.38)
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.layer.borderWidth = 1
        searchBarContainer.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.15).cgColor
        makeShadow(on: searchBarContainer, radius: 18, yOffset: 8, opacity: 0.08)
        
        searchBarContainer.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBarContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            searchBarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchBarContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            searchBarContainer.heightAnchor.constraint(equalToConstant: 52),
            
            searchBar.topAnchor.constraint(equalTo: searchBarContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchBarContainer.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchBarContainer.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: searchBarContainer.bottomAnchor)
        ])

        let textField = searchBar.searchTextField
        textField.backgroundColor = .clear
        textField.textColor = CineMystTheme.ink
        textField.tintColor = CineMystTheme.brandPlum
    }
    
    private func setupPostButtons() {
        contentView.addSubview(postButtonsStack)
        postButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            postButtonsStack.topAnchor.constraint(equalTo: searchBarContainer.bottomAnchor, constant: 16),
            postButtonsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postButtonsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            postButtonsStack.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let titles = ["Post Job", "My Jobs", "Posted"]
        for t in titles {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
            btn.layer.cornerRadius = 14
            btn.backgroundColor = UIColor.white.withAlphaComponent(0.54)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
            makeShadow(on: btn, radius: 16, yOffset: 8, opacity: 0.08)
            
            switch t {
            case "Post Job": btn.addTarget(self, action: #selector(postJobTapped), for: .touchUpInside)
            case "My Jobs": btn.addTarget(self, action: #selector(myJobsTapped), for: .touchUpInside)
            case "Posted": btn.addTarget(self, action: #selector(didTapPosted), for: .touchUpInside)
            default: break
            }
            postButtonsStack.addArrangedSubview(btn)
        }
    }
    
    private func setupCuratedAndJobs() {
        [curatedLabel, curatedSubtitle, jobListStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        let separator = UIView()
        separator.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            curatedLabel.topAnchor.constraint(equalTo: postButtonsStack.bottomAnchor, constant: 32),
            curatedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            curatedSubtitle.topAnchor.constraint(equalTo: curatedLabel.bottomAnchor, constant: 4),
            curatedSubtitle.leadingAnchor.constraint(equalTo: curatedLabel.leadingAnchor),
            curatedSubtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            separator.topAnchor.constraint(equalTo: curatedSubtitle.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            
            jobListStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            jobListStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            jobListStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    private func styleTopActionButton(_ button: UIButton) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.68)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.82).cgColor
        makeShadow(on: button, radius: 14, yOffset: 6, opacity: 0.08)
    }
    
    private func setupBottomSpacing() {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.topAnchor.constraint(equalTo: jobListStack.bottomAnchor),
            spacer.heightAnchor.constraint(equalToConstant: 160),
            spacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            spacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            spacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Logic
    private func reloadJobCards() {
        Task {
            await self.addJobCards()
        }
    }
    
    private func addJobCards() async {
        do {
            let jobs = try await JobsService.shared.fetchActiveJobs()
            self.allJobs = jobs
            self.filteredJobs = jobs
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                for job in self.filteredJobs {
                    let card = JobCardView()
                    
                    Task {
                        let directorUuid = job.directorId ?? UUID()
                        let (productionHouse, _) = await self.fetchProductionHouse(directorId: directorUuid)
                        let applicationCount = await self.fetchApplicationCount(jobId: job.id)
                        let associatedTask = try? await JobsService.shared.fetchTaskForJob(jobId: job.id)
                        
                        await MainActor.run {
                            let hasTask = associatedTask != nil
                            card.configure(
                                image: UIImage(named: "avatar_placeholder"),
                                title: job.title ?? "Untitled",
                                company: productionHouse,
                                location: job.location ?? "Remote",
                                salary: "₹ \(job.ratePerDay ?? 0)/day",
                                daysLeft: job.daysLeftText,
                                tag: job.jobType ?? "Film",
                                appliedCount: "\(applicationCount) applied",
                                hasTask: hasTask
                            )

                            // Apply button
                            card.onApplyTap = { [weak self] in
                                if let task = associatedTask {
                                    let vc = TaskDetailsViewController()
                                    vc.job = job
                                    vc.task = task
                                    self?.navigationController?.pushViewController(vc, animated: true)
                                } else {
                                    self?.directSubmitPortfolio(job: job)
                                }
                            }
                        }
                    }
                    
                    card.onTap = { [weak self] in
                        let detailVC = JobDetailsViewController()
                        detailVC.job = job
                        self?.navigationController?.pushViewController(detailVC, animated: true)
                    }

                    card.onBookmarkTap = { [weak self] in
                        _ = BookmarkManager.shared.toggle(job.id)
                        let current = BookmarkManager.shared.isBookmarked(job.id)
                        card.updateBookmark(isBookmarked: current)
                    }

                    let isBookmarked = BookmarkManager.shared.isBookmarked(job.id)
                    card.updateBookmark(isBookmarked: isBookmarked)
                    
                    self.jobListStack.addArrangedSubview(card)
                }
            }
        } catch {
            print("Error loading jobs: \(error)")
        }
    }

    private func fetchProductionHouse(directorId: UUID) async -> (companyName: String, profilePictureUrl: String?) {
        var companyName = "Production House"
        do {
            struct CastingProfile: Codable {
                let companyName: String?
                enum CodingKeys: String, CodingKey { case companyName = "company_name" }
            }
            let profile: CastingProfile = try await supabase
                .from("casting_profiles")
                .select("company_name")
                .eq("id", value: directorId.uuidString)
                .single()
                .execute()
                .value
            if let name = profile.companyName, !name.isEmpty { companyName = name }
        } catch { print("⚠️ Could not fetch company name: \(error)") }
        
        var profilePictureUrl: String?
        do {
            struct Profile: Codable {
                let profilePictureUrl: String?
                enum CodingKeys: String, CodingKey { case profilePictureUrl = "profile_picture_url" }
            }
            let profile: Profile = try await supabase
                .from("profiles")
                .select("profile_picture_url")
                .eq("id", value: directorId.uuidString)
                .single()
                .execute()
                .value
            profilePictureUrl = profile.profilePictureUrl
        } catch { print("⚠️ Could not fetch profile picture: \(error)") }
        
        return (companyName, profilePictureUrl)
    }
    
    private func fetchApplicationCount(jobId: UUID) async -> Int {
        do {
            let response = try await supabase
                .from("applications")
                .select("*", head: false, count: .exact)
                .eq("job_id", value: jobId.uuidString)
                .execute()
            return response.count ?? 0
        } catch {
            print("⚠️ Could not fetch application count: \(error)")
            return 0
        }
    }

    private func directSubmitPortfolio(job: Job) {
        guard let currentUser = supabase.auth.currentUser else {
            showAlert(title: "Sign In Required", message: "Please sign in to apply.")
            return
        }
        
        let alert = UIAlertController(title: "Confirm Application", message: "Apply to \(job.title ?? "this job") by sending your portfolio?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { _ in
            Task {
                do {
                    let actorId = currentUser.id
                    let existing: [Application] = try await supabase
                        .from("applications")
                        .select()
                        .eq("job_id", value: job.id.uuidString)
                        .eq("actor_id", value: actorId.uuidString)
                        .execute()
                        .value
                    
                    if let app = existing.first {
                         let updated = Application(
                             id: app.id,
                             jobId: app.jobId,
                             actorId: app.actorId,
                             status: .portfolioSubmitted,
                             portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                             portfolioSubmittedAt: Date(),
                             appliedAt: app.appliedAt,
                             updatedAt: Date()
                         )
                         _ = try await supabase.from("applications").update(updated).eq("id", value: app.id.uuidString).execute()
                    } else {
                        let newApp = Application(
                            id: UUID(),
                            jobId: job.id,
                            actorId: actorId,
                            status: .portfolioSubmitted,
                            portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                            portfolioSubmittedAt: Date(),
                            appliedAt: Date(),
                            updatedAt: Date()
                        )
                        _ = try await supabase.from("applications").insert(newApp).execute()
                    }
                    
                    await MainActor.run {
                        self.showAlert(title: "Success", message: "Portfolio sent successfully!")
                    }
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Selectors
    @objc private func postJobTapped() {
        Task {
            let hasProfile = await checkIfProfileExists()
            await MainActor.run {
                if hasProfile {
                    self.navigationController?.pushViewController(PostJobViewController(), animated: true)
                } else {
                    self.navigationController?.pushViewController(ProfileInfoViewController(), animated: true)
                }
            }
        }
    }
    
    private func checkIfProfileExists() async -> Bool {
        guard let userId = supabase.auth.currentUser?.id else { return false }
        do {
            let _ = try await supabase.from("casting_profiles").select().eq("id", value: userId.uuidString).single().execute()
            return true
        } catch { return false }
    }

    @objc private func myJobsTapped() {
        self.navigationController?.pushViewController(MyApplicationsViewController(), animated: true)
    }
    @objc private func didTapPosted() {
        self.navigationController?.pushViewController(PostedJobsDashboardViewController(), animated: true)
    }
    @objc private func openSavedPosts() {
        self.navigationController?.pushViewController(SavedPostViewController(), animated: true)
    }
    @objc private func openFilter() {
        let vc = FilterScrollViewController()
        filterVC = vc
        vc.onFiltersApplied = { [weak self] role, position, project, earning in
            self?.activeRoleFilter = role
            self?.activePositionFilter = position
            self?.activeProjectFilter = project
            self?.activeEarningFilter = earning
            self?.applyFilters()
            self?.closeFilter()
        }
        dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        dimView.alpha = 0
        view.addSubview(dimView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeFilter))
        dimView.addGestureRecognizer(tap)
        
        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        let height = view.frame.height * 0.72
        vc.view.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        vc.view.layer.cornerRadius = 20
        vc.view.clipsToBounds = true
        
        UIView.animate(withDuration: 0.28) {
            self.dimView.alpha = 1
            vc.view.frame.origin.y = self.view.frame.height - height
        }
    }
    
    @objc private func closeFilter() {
        guard let vc = filterVC else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.dimView.alpha = 0
            vc.view.frame.origin.y = self.view.frame.height
        }) { _ in
            self.dimView.removeFromSuperview()
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }
    
    private func applyFilters() {
        var filtered = allJobs
        if let role = activeRoleFilter { filtered = filtered.filter { ($0.jobType ?? "").lowercased().contains(role.lowercased()) } }
        if let position = activePositionFilter { filtered = filtered.filter { ($0.title ?? "").lowercased().contains(position.lowercased()) } }
        if let project = activeProjectFilter { filtered = filtered.filter { ($0.title ?? "").lowercased().contains(project.lowercased()) || ($0.jobType ?? "").lowercased().contains(project.lowercased()) } }
        if let earning = activeEarningFilter, earning > 0 { filtered = filtered.filter { ($0.ratePerDay ?? 0) >= Int(earning) } }
        filteredJobs = filtered
        Task { await displayFilteredJobs() }
    }

    private func displayFilteredJobs() async {
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for job in self.filteredJobs {
                let card = JobCardView()
                // Configure card logic same as addJobCards... (Shortened for brevity but keeping same structure)
                Task {
                    let directorUuid = job.directorId ?? UUID()
                    let (productionHouse, _) = await self.fetchProductionHouse(directorId: directorUuid)
                    let applicationCount = await self.fetchApplicationCount(jobId: job.id)
                    let associatedTask = try? await JobsService.shared.fetchTaskForJob(jobId: job.id)
                    await MainActor.run {
                        let hasTask = associatedTask != nil
                        card.configure(image: UIImage(named: "avatar_placeholder"), title: job.title ?? "Untitled", company: productionHouse, location: job.location ?? "Remote", salary: "₹ \(job.ratePerDay ?? 0)/day", daysLeft: job.daysLeftText, tag: job.jobType ?? "Film", appliedCount: "\(applicationCount) applied", hasTask: hasTask)
                        card.onApplyTap = { [weak self] in
                            if let task = associatedTask {
                                let vc = TaskDetailsViewController()
                                vc.job = job; vc.task = task
                                self?.navigationController?.pushViewController(vc, animated: true)
                            } else { self?.directSubmitPortfolio(job: job) }
                        }
                    }
                }
                card.onTap = { [weak self] in
                    let detailVC = JobDetailsViewController()
                    detailVC.job = job
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
                card.onBookmarkTap = { [weak self] in
                    _ = BookmarkManager.shared.toggle(job.id)
                    card.updateBookmark(isBookmarked: BookmarkManager.shared.isBookmarked(job.id))
                }
                card.updateBookmark(isBookmarked: BookmarkManager.shared.isBookmarked(job.id))
                self.jobListStack.addArrangedSubview(card)
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension JobsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredJobs = allJobs
        } else {
            filteredJobs = allJobs.filter { job in
                (job.title ?? "").lowercased().contains(searchText.lowercased()) ||
                (job.companyName ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        Task { await displayFilteredJobs() }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

