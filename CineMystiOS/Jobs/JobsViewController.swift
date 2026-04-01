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
final class jobsViewController: UIViewController, UIScrollViewDelegate {
    
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
        l.font = UIFont(name: "Georgia-Bold", size: 28) ?? UIFont.boldSystemFont(ofSize: 28)
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
        l.font = UIFont(name: "Georgia-Bold", size: 21) ?? UIFont.boldSystemFont(ofSize: 21)
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
        // Reload job cards when view appears
        reloadJobCards()
    }
    
    // MARK: - ScrollView & Content
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
    
    // Title bar at top of content
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
    
    // Search bar below title
    private func setupSearchBar() {
        contentView.addSubview(searchBarContainer)
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.backgroundColor = UIColor.white.withAlphaComponent(0.38)
        searchBarContainer.layer.cornerRadius = 18
        searchBarContainer.layer.borderWidth = 1
        searchBarContainer.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.15).cgColor
        makeShadow(on: searchBarContainer, radius: 18, yOffset: 8, opacity: 0.08)
        
        // Add the search bar to the container
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
        textField.attributedPlaceholder = NSAttributedString(
            string: "Search jobs",
            attributes: [.foregroundColor: CineMystTheme.ink.withAlphaComponent(0.38)]
        )
    }
    
    // Post buttons row
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
    
    // Curated header + job list
    private func setupCuratedAndJobs() {
        [curatedLabel, curatedSubtitle, jobListStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Add separator line
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
    
    // Ensure bottom spacing
    private func setupBottomSpacing() {
        // add a spacer view so contentView has a bottom constraint for scrolling
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
    
    // MARK: - Job Cards Management
    private func reloadJobCards() {
        // Clear existing cards
        jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // If we have cached jobs, reload from filtered list
        if !allJobs.isEmpty {
            Task { [weak self] in
                await self?.displayFilteredJobs()
            }
        } else {
            // Load new cards from API
            Task { [weak self] in
                await self?.addJobCards()
            }
        }
    }
    
    private func displayFilteredJobs() async {
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            
            // Clear existing job cards
            self.jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for job in self.filteredJobs {
                let card = JobCardView()
                
                // Fetch production house data and application count
                Task {
                    let (productionHouse, profilePictureUrl) = await self.fetchProductionHouse(directorId: job.directorId)
                    let applicationCount = await self.fetchApplicationCount(jobId: job.id)
                    
                    await MainActor.run {
                        // Load profile image asynchronously
                        if let urlString = profilePictureUrl,
                           let url = URL(string: urlString) {
                            Task {
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: url)
                                    if let image = UIImage(data: data) {
                                        await MainActor.run {
                                            card.configure(
                                                image: image,
                                                title: job.title,
                                                company: productionHouse,
                                                location: job.location,
                                                salary: "₹ \(job.ratePerDay)/day",
                                                daysLeft: job.daysLeftText,
                                                tag: job.jobType,
                                                appliedCount: "\(applicationCount) applied"
                                            )
                                        }
                                    }
                                } catch {
                                    print("⚠️ Failed to load profile image: \(error)")
                                }
                            }
                        }
                        
                        // Set initial configuration with default image
                        card.configure(
                            image: UIImage(named: "avatar_placeholder"),
                            title: job.title,
                            company: productionHouse,
                            location: job.location,
                            salary: "₹ \(job.ratePerDay)/day",
                            daysLeft: job.daysLeftText,
                            tag: job.jobType,
                            appliedCount: "\(applicationCount) applied"
                        )
                    }
                }
                
                // Set initial bookmark state
                let isBookmarked = BookmarkManager.shared.isBookmarked(job.id)
                card.updateBookmark(isBookmarked: isBookmarked)
                
                // Set up card tap handler
                card.onTap = { [weak self] in
                    let detailVC = JobDetailsViewController()
                    detailVC.job = job
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
                
                // Set up apply button handler
                card.onApplyTap = { [weak self] in
                    let applyVC = ApplicationStartedViewController()
                    applyVC.job = job
                    self?.navigationController?.pushViewController(applyVC, animated: true)
                }
                
                // Set up bookmark tap handler
                card.onBookmarkTap = { [weak self] in
                    let newState = BookmarkManager.shared.toggle(job.id)
                    card.updateBookmark(isBookmarked: newState)
                    
                    // Sync to backend
                    Task {
                        do {
                            try await JobsService.shared.toggleBookmark(jobId: job.id)
                            print("✅ Bookmark synced to backend for job: \(job.title)")
                        } catch {
                            print("❌ Failed to sync bookmark: \(error)")
                        }
                    }
                }
                
                self.jobListStack.addArrangedSubview(card)
            }
        }
    }
    
    // MARK: - Sample job cards (uses your JobCardView)
    private func addJobCards() async {
        do {
            let jobs = try await JobsService.shared.fetchActiveJobs()
            
            print("📋 Loaded \(jobs.count) active jobs")
            for (index, job) in jobs.enumerated() {
                print("   Job \(index + 1): '\(job.title)' - Location: '\(job.location)' - Company: '\(job.companyName)'")
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                // Store all jobs and initialize filtered jobs
                self.allJobs = jobs
                self.filteredJobs = jobs
                
                // Clear existing job cards
                self.jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                for job in self.filteredJobs {
                    let card = JobCardView()
                    
                    // Fetch production house data and application count
                    Task {
                        let (productionHouse, profilePictureUrl) = await self.fetchProductionHouse(directorId: job.directorId)
                        let applicationCount = await self.fetchApplicationCount(jobId: job.id)
                        
                        await MainActor.run {
                            // Load profile image asynchronously
                            if let urlString = profilePictureUrl,
                               let url = URL(string: urlString) {
                                Task {
                                    do {
                                        let (data, _) = try await URLSession.shared.data(from: url)
                                        if let image = UIImage(data: data) {
                                            await MainActor.run {
                                                card.configure(
                                                    image: image,
                                                    title: job.title,
                                                    company: productionHouse,
                                                    location: job.location,
                                                    salary: "₹ \(job.ratePerDay)/day",
                                                    daysLeft: job.daysLeftText,
                                                    tag: job.jobType,
                                                    appliedCount: "\(applicationCount) applied"
                                                )
                                            }
                                        }
                                    } catch {
                                        print("⚠️ Failed to load profile image: \(error)")
                                    }
                                }
                            }
                            
                            // Set initial configuration with default image
                            card.configure(
                                image: UIImage(named: "avatar_placeholder"),
                                title: job.title,
                                company: productionHouse,
                                location: job.location,
                                salary: "₹ \(job.ratePerDay)/day",
                                daysLeft: job.daysLeftText,
                                tag: job.jobType,
                                appliedCount: "\(applicationCount) applied"
                            )
                        }
                    }
                    
                    // Set initial bookmark state
                    let isBookmarked = BookmarkManager.shared.isBookmarked(job.id)
                    card.updateBookmark(isBookmarked: isBookmarked)
                    
                    // Set up card tap handler
                    card.onTap = { [weak self] in
                        let detailVC = JobDetailsViewController()
                        detailVC.job = job // Pass job data
                        self?.navigationController?.pushViewController(detailVC, animated: true)
                    }
                    
                    // Set up apply button handler
                    card.onApplyTap = { [weak self] in
                        let applyVC = ApplicationStartedViewController()
                        applyVC.job = job // Pass job data
                        self?.navigationController?.pushViewController(applyVC, animated: true)
                    }
                    
                    // Set up bookmark tap handler
                    card.onBookmarkTap = { [weak self] in
                        let newState = BookmarkManager.shared.toggle(job.id)
                        card.updateBookmark(isBookmarked: newState)
                        
                        // Sync to backend
                        Task {
                            do {
                                try await JobsService.shared.toggleBookmark(jobId: job.id)
                                print("✅ Bookmark synced to backend for job: \(job.title)")
                            } catch {
                                print("❌ Failed to sync bookmark: \(error)")
                            }
                        }
                    }

                    self.jobListStack.addArrangedSubview(card)
                }
            }
        } catch {
            print("Error loading jobs: \(error)")
        }
    }
    
    private func fetchProductionHouse(directorId: UUID) async -> (companyName: String, profilePictureUrl: String?) {
        // Fetch company name from casting_profiles
        var companyName = "Production House"
        do {
            struct CastingProfile: Codable {
                let companyName: String?
                
                enum CodingKeys: String, CodingKey {
                    case companyName = "company_name"
                }
            }
            
            let profile: CastingProfile = try await supabase
                .from("casting_profiles")
                .select("company_name")
                .eq("id", value: directorId.uuidString)
                .single()
                .execute()
                .value
            
            if let name = profile.companyName, !name.isEmpty {
                companyName = name
            }
        } catch {
            print("⚠️ Could not fetch company name: \(error)")
        }
        
        // Fetch profile picture from profiles table
        var profilePictureUrl: String?
        do {
            struct Profile: Codable {
                let profilePictureUrl: String?
                
                enum CodingKeys: String, CodingKey {
                    case profilePictureUrl = "profile_picture_url"
                }
            }
            
            let profile: Profile = try await supabase
                .from("profiles")
                .select("profile_picture_url")
                .eq("id", value: directorId.uuidString)
                .single()
                .execute()
                .value
            
            profilePictureUrl = profile.profilePictureUrl
        } catch {
            print("⚠️ Could not fetch profile picture: \(error)")
        }
        
        print("✅ Fetched production house: '\(companyName)', Profile pic: \(profilePictureUrl != nil ? "Yes" : "No")")
        return (companyName, profilePictureUrl)
    }
    
    private func fetchApplicationCount(jobId: UUID) async -> Int {
        do {
            struct ApplicationCount: Codable {
                let count: Int
            }
            
            // Get count of applications for this job
            let response = try await supabase
                .from("applications")
                .select("*", head: false, count: .exact)
                .eq("job_id", value: jobId.uuidString)
                .execute()
            
            return response.count ?? 0
        } catch {
            print("⚠️ Could not fetch application count for job \(jobId): \(error)")
            return 0
        }
    }


    
    // MARK: - Actions
    @objc private func postJobTapped() {
        // Check if user has already filled profile information
        Task {
            let hasProfile = await checkIfProfileExists()
            await MainActor.run {
                if hasProfile {
                    // Profile exists, go directly to PostJobViewController
                    let vc = PostJobViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    // No profile, show ProfileInfoViewController first
                    let vc = ProfileInfoViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    private func checkIfProfileExists() async -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            print("❌ User not authenticated")
            return false
        }
        
        do {
            let response = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            // If we successfully got a response, profile exists
            let profile = try JSONDecoder().decode(CastingProfileRecord.self, from: response.data)
            print("✅ Profile exists: \(profile.companyName ?? "N/A")")
            return true
        } catch {
            print("ℹ️ No profile found: \(error)")
            return false
        }
    }
    @objc private func myJobsTapped() {
        let vc = MyApplicationsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func didTapPosted() {
        let vc = PostedJobsDashboardViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func openSavedPosts() {
        let vc = SavedPostViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Filter sheet
    @objc private func openFilter() {
        let vc = FilterScrollViewController()
        filterVC = vc
        
        // Set up filter callback
        vc.onFiltersApplied = { [weak self] role, position, project, earning in
            self?.activeRoleFilter = role
            self?.activePositionFilter = position
            self?.activeProjectFilter = project
            self?.activeEarningFilter = earning
            
            // Apply filters
            self?.applyFilters()
            
            // Close filter sheet
            self?.closeFilter()
        }
        
        dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        view.addSubview(dimView)
        dimView.alpha = 0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeFilter))
        dimView.addGestureRecognizer(tap)
        
        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        let height: CGFloat = view.frame.height * 0.72
        vc.view.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        vc.view.layer.cornerRadius = 20
        vc.view.clipsToBounds = true
        
        UIView.animate(withDuration: 0.28) {
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.32)
            self.dimView.alpha = 1
            vc.view.frame.origin.y = self.view.frame.height - height
        }
    }
    
    @objc private func closeFilter() {
        guard let vc = filterVC else { return }
        let height = vc.view.frame.height
        UIView.animate(withDuration: 0.25, animations: {
            self.dimView.alpha = 0
            vc.view.frame.origin.y = self.view.frame.height
        }) { _ in
            self.dimView.removeFromSuperview()
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }
    
    // MARK: - Apply Filters
    private func applyFilters() {
        var filtered = allJobs
        
        // Apply role filter
        if let role = activeRoleFilter {
            filtered = filtered.filter { job in
                job.jobType.lowercased().contains(role.lowercased())
            }
        }
        
        // Apply position filter  
        if let position = activePositionFilter {
            filtered = filtered.filter { job in
                job.title.lowercased().contains(position.lowercased())
            }
        }
        
        // Apply project type filter
        if let project = activeProjectFilter {
            filtered = filtered.filter { job in
                // Check if job description or title contains project type
                job.title.lowercased().contains(project.lowercased()) ||
                job.jobType.lowercased().contains(project.lowercased())
            }
        }
        
        // Apply earning filter
        if let earning = activeEarningFilter, earning > 0 {
            filtered = filtered.filter { job in
                job.ratePerDay >= Int(earning)
            }
        }
        
        filteredJobs = filtered
        reloadJobCards()
    }
    
    // Scroll fade header
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

// MARK: - UISearchBarDelegate
extension jobsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Start with all jobs or apply existing filters first
        var jobsToFilter = allJobs
        
        // Apply active filters first
        if activeRoleFilter != nil || activePositionFilter != nil || activeProjectFilter != nil || activeEarningFilter != nil {
            if let role = activeRoleFilter {
                jobsToFilter = jobsToFilter.filter { $0.jobType.lowercased().contains(role.lowercased()) }
            }
            if let position = activePositionFilter {
                jobsToFilter = jobsToFilter.filter { $0.title.lowercased().contains(position.lowercased()) }
            }
            if let project = activeProjectFilter {
                jobsToFilter = jobsToFilter.filter { 
                    $0.title.lowercased().contains(project.lowercased()) ||
                    $0.jobType.lowercased().contains(project.lowercased())
                }
            }
            if let earning = activeEarningFilter, earning > 0 {
                jobsToFilter = jobsToFilter.filter { $0.ratePerDay >= Int(earning) }
            }
        }
        
        // Then apply search text filter
        if searchText.isEmpty {
            filteredJobs = jobsToFilter
        } else {
            filteredJobs = jobsToFilter.filter { job in
                job.title.lowercased().contains(searchText.lowercased()) ||
                job.companyName.lowercased().contains(searchText.lowercased()) ||
                job.location.lowercased().contains(searchText.lowercased()) ||
                job.jobType.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Reload job cards with filtered results
        reloadJobCards()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
