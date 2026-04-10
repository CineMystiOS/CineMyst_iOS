import UIKit
import Supabase
import AVFoundation

class SwipeScreenViewController: UIViewController {

    var job: Job?
    private var cardData: [CandidateModel] = []
    private var taskSubmissions: [TaskSubmission] = []
    private var applications: [Application] = []
    private var cardViews: [CandidateCardView] = []
    private let maxCardsOnScreen = 3
    private var cardsLoaded = false
    private var activeCardCenter: CGPoint = .zero
    
    // Use shared Supabase client defined in auth/Supabase.swift

    // MARK: - NEW COUNTERS
    private var shortlistedCount = 0
    private var passedCount = 0
    private let backgroundGradient = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CineMystTheme.deepPlumDark
        setupTheme()
        
        configureAudioSession()
        setupNavigationBar()
        setupUI()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    private func setupTheme() {
        backgroundGradient.colors = [
            CineMystTheme.deepPlumDark.cgColor,
            CineMystTheme.deepPlum.cgColor,
            CineMystTheme.deepPlumMid.cgColor
        ]
        backgroundGradient.locations = [0, 0.5, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // Reload submissions when view appears
        loadSubmissions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds

        if !cardsLoaded {
            loadCards()
            cardsLoaded = true
        }
    }

    // MARK: Navigation Bar
    private func setupNavigationBar() {

        let titleLabel = UILabel()
        titleLabel.text = "Shortlist Candidates"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = job?.title ?? "Loading..."
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center

        navigationItem.titleView = stack

        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = .white
        backBtn.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)

        let listBtn = UIButton(type: .system)
        listBtn.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        listBtn.tintColor = .white
        listBtn.addTarget(self, action: #selector(openApplicationsScreen), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: listBtn)
    }

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: UI Elements

    private let shortlistedContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return v
    }()

    private let passedContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return v
    }()

    private let shortlistedCountLabel = SwipeScreenViewController.makeCountLabel()
    private let passedCountLabel = SwipeScreenViewController.makeCountLabel()

    private static func makeCountLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text = "0"
        lbl.textColor = .white
        lbl.font = .boldSystemFont(ofSize: 20)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    private let shortlistedTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Shortlisted"
        lbl.textColor = .white.withAlphaComponent(0.7)
        lbl.font = .systemFont(ofSize: 13)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let passedTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Passed"
        lbl.textColor = .white.withAlphaComponent(0.7)
        lbl.font = .systemFont(ofSize: 13)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let dislikeButton: UIButton = {
        let btn = SwipeScreenViewController.makeCircleButton(symbol: "xmark", tint: .white)
        return btn
    }()

    private let likeButton: UIButton = {
        let btn = SwipeScreenViewController.makeCircleButton(symbol: "heart.fill", tint: .systemPink)
        return btn
    }()

    private static func makeCircleButton(symbol: String, tint: UIColor) -> UIButton {

        let size: CGFloat = 70
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        btn.setImage(UIImage(systemName: symbol), for: .normal)
        btn.tintColor = tint

        btn.backgroundColor = .clear
        btn.clipsToBounds = false
        btn.layer.cornerRadius = size / 2

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(x: 0, y: 0, width: size, height: size)
        blurView.layer.cornerRadius = size / 2
        blurView.clipsToBounds = true
        blurView.alpha = 0.22
        btn.insertSubview(blurView, at: 0)

        btn.layer.shadowColor = tint.withAlphaComponent(0.25).cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowRadius = 6
        btn.layer.shadowOffset = .zero

        btn.layer.borderWidth = 1.0
        btn.layer.borderColor = tint.withAlphaComponent(0.35).cgColor

        return btn
    }

    // MARK: UI Setup
    private func setupUI() {
        
        view.addSubview(shortlistedContainer)
        view.addSubview(passedContainer)
        view.addSubview(dislikeButton)
        view.addSubview(likeButton)

        shortlistedContainer.addSubview(shortlistedCountLabel)
        shortlistedContainer.addSubview(shortlistedTextLabel)
        passedContainer.addSubview(passedCountLabel)
        passedContainer.addSubview(passedTextLabel)

        NSLayoutConstraint.activate([
            shortlistedContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            shortlistedContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),

            shortlistedContainer.widthAnchor.constraint(equalToConstant: 150),
            shortlistedContainer.heightAnchor.constraint(equalToConstant: 38),

            shortlistedCountLabel.centerYAnchor.constraint(equalTo: shortlistedContainer.centerYAnchor),
            shortlistedCountLabel.leadingAnchor.constraint(equalTo: shortlistedContainer.leadingAnchor, constant: 12),

            shortlistedTextLabel.centerYAnchor.constraint(equalTo: shortlistedContainer.centerYAnchor),
            shortlistedTextLabel.leadingAnchor.constraint(equalTo: shortlistedCountLabel.trailingAnchor, constant: 6),

            passedContainer.leadingAnchor.constraint(equalTo: shortlistedContainer.trailingAnchor, constant: 15),
            passedContainer.topAnchor.constraint(equalTo: shortlistedContainer.topAnchor),
            passedContainer.widthAnchor.constraint(equalToConstant: 150),
            passedContainer.heightAnchor.constraint(equalToConstant: 38),

            passedCountLabel.centerYAnchor.constraint(equalTo: passedContainer.centerYAnchor),
            passedCountLabel.leadingAnchor.constraint(equalTo: passedContainer.leadingAnchor, constant: 12),

            passedTextLabel.centerYAnchor.constraint(equalTo: passedContainer.centerYAnchor),
            passedTextLabel.leadingAnchor.constraint(equalTo: passedCountLabel.trailingAnchor, constant: 6),

            dislikeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -70),
            dislikeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            dislikeButton.widthAnchor.constraint(equalToConstant: 70),
            dislikeButton.heightAnchor.constraint(equalToConstant: 70),

            likeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 70),
            likeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            likeButton.widthAnchor.constraint(equalToConstant: 70),
            likeButton.heightAnchor.constraint(equalToConstant: 70),
        ])

        dislikeButton.addTarget(self, action: #selector(handleDislike), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
    }

    // MARK: Load Cards
    private func loadCards() {
        // Remove any existing cards from view
        view.subviews.filter { $0 is CandidateCardView }.forEach { $0.removeFromSuperview() }
        
        // Remove any empty state labels
        view.subviews.compactMap { $0 as? UILabel }.filter { $0.tag == 4040 }.forEach { $0.removeFromSuperview() }
        
        cardViews.removeAll()

        let models = Array(cardData.prefix(maxCardsOnScreen))
        if models.isEmpty {
            // Show empty state
            let lbl = UILabel()
            lbl.tag = 4040
            lbl.text = "No candidates to review yet"
            lbl.textColor = UIColor.white.withAlphaComponent(0.7)
            lbl.font = .systemFont(ofSize: 16, weight: .medium)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)
            ])
            bringUIElementsToFront()
            return
        }

        for (index, model) in models.reversed().enumerated() {
            let card = makeCard(for: model)
            let position = models.count - 1 - index
            applyStackLayout(to: card, position: position)
            view.addSubview(card)
            cardViews.append(card)
        }

        bringUIElementsToFront()
    }
    
    // MARK: - Load Submissions
    private func loadSubmissions() {
        Task {
            do {
                guard let job = job else {
                    print("❌ No job provided to SwipeScreenViewController")
                    return
                }
                
                print("📥 Loading submissions for job: \(job.id.uuidString)")
                
                // Fetch ALL applications for this job — no status filter so nothing is silently excluded
                let allApplications: [Application] = try await supabase
                    .from("applications")
                    .select()
                    .eq("job_id", value: job.id.uuidString)
                    .execute()
                    .value

                // Exclude only terminal statuses (already decided). Show everything else.
                let applications: [Application] = allApplications.filter {
                    $0.status != .selected && $0.status != .rejected
                }

                print("📥 Total applications: \(allApplications.count), reviewable: \(applications.count)")
                for app in allApplications {
                    print("   status='\(app.status.rawValue)' actor=\(app.actorId.uuidString.prefix(8))")
                }

                // Deduping by actorId to ensure one card per candidate
                let dedupedApplications = Dictionary(grouping: applications, by: \.actorId)
                    .compactMap { _, actorApplications in
                        actorApplications.max(by: {
                            ($0.updatedAt ?? $0.appliedAt) < ($1.updatedAt ?? $1.appliedAt)
                        })
                    }
                    .sorted(by: {
                        ($0.updatedAt ?? $0.appliedAt) > ($1.updatedAt ?? $1.appliedAt)
                    })

                self.applications = dedupedApplications
                print("✅ Fetched \(applications.count) applications for job, using \(dedupedApplications.count) unique applicants")
                for app in dedupedApplications {
                    print("   - App \(app.id.uuidString.prefix(8)): Actor=\(app.actorId.uuidString.prefix(8)), Status=\(app.status)")
                }
                
                // Fetch task submissions for all applications
                var submissions: [TaskSubmission] = []
                for app in dedupedApplications {
                    do {
                        let appSubmissions: [TaskSubmission] = try await supabase
                            .from("task_submissions")
                            .select()
                            .eq("application_id", value: app.id.uuidString)
                            .order("submitted_at", ascending: false)
                            .execute()
                            .value
                        submissions.append(contentsOf: appSubmissions)
                    } catch {
                        print("⚠️ Warning: Could not fetch submissions for app \(app.id): \(error)")
                    }
                }
                
                self.taskSubmissions = submissions
                print("✅ Fetched \(submissions.count) task submissions")
                
                // Fetch user profiles
                var userProfiles: [UUID: (name: String, imageUrl: String?)] = [:]
                for app in dedupedApplications {
                    do {
                        let profile = try await self.fetchUserProfile(userId: app.actorId)
                        userProfiles[app.actorId] = profile
                    } catch {
                        print("⚠️ Could not fetch profile for actor \(app.actorId): \(error)")
                        userProfiles[app.actorId] = ("User \(app.actorId.uuidString.prefix(8))", nil)
                    }
                }
                
                // Build cards for ALL applications (not just those with submissions)
                let submissionsByApp = Dictionary(grouping: submissions, by: { $0.applicationId })
                
                print("🔍 Building card data:")
                print("  - Total applications: \(dedupedApplications.count)")
                print("  - Applications with submissions: \(submissionsByApp.count)")
                
                self.cardData = dedupedApplications.compactMap { app in
                    let profile = userProfiles[app.actorId] ?? ("User \(app.actorId.uuidString.prefix(8))", nil)
                    let userName = profile.name
                    let profileImageUrl = profile.imageUrl
                    
                    // Check if there are task submissions
                    if let appSubs = submissionsByApp[app.id], let latest = appSubs.first {
                        let videoURL = latest.submissionUrl
                        guard !videoURL.isEmpty else {
                            // No video URL, show profile image
                            print("  ✅ Card with empty submission URL (showing profile image): \(app.id.uuidString.prefix(8))")
                            return CandidateModel(
                                applicationId: app.id,
                                actorId: app.actorId,
                                name: userName,
                                videoURL: nil,
                                profileImageUrl: profileImageUrl,
                                location: "India",
                                experience: "Portfolio Submitted",
                                portfolioURL: app.portfolioUrl
                            )
                        }
                        
                        print("  ✅ Card with video submission: \(app.id.uuidString.prefix(8)), Status: \(app.status)")
                        
                        return CandidateModel(
                            applicationId: app.id,
                            actorId: app.actorId,
                            name: userName,
                            videoURL: URL(string: videoURL),
                            profileImageUrl: profileImageUrl,
                            location: "India",
                            experience: "Task Submitted",
                            portfolioURL: app.portfolioUrl
                        )
                    } else {
                        // No task submission - show profile image
                        print("  ✅ Card without submission (showing profile image): \(app.id.uuidString.prefix(8)), Status: \(app.status)")
                        
                        return CandidateModel(
                            applicationId: app.id,
                            actorId: app.actorId,
                            name: userName,
                            videoURL: nil,
                            profileImageUrl: profileImageUrl,
                            location: "India",
                            experience: "Portfolio Submitted",
                            portfolioURL: app.portfolioUrl
                        )
                    }
                }
                
                print("✅ Prepared \(self.cardData.count) card models for rendering")
                
                DispatchQueue.main.async {
                    // Clear old cards
                    self.cardViews.forEach { $0.removeFromSuperview() }
                    self.cardViews.removeAll()
                    self.cardsLoaded = false
                    
                    // Reload cards
                    self.loadCards()
                }
            } catch {
                print("❌ Error loading submissions: \(error)")
            }
        }
    }

    private func bringUIElementsToFront() {
        view.bringSubviewToFront(shortlistedContainer)
        view.bringSubviewToFront(passedContainer)
        view.bringSubviewToFront(dislikeButton)
        view.bringSubviewToFront(likeButton)
    }
    
    private func fetchUserProfile(userId: UUID) async throws -> (name: String, imageUrl: String?) {
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
        return (name, profile.avatarUrl)
    }

    private func makeCard(for model: CandidateModel) -> CandidateCardView {
        let card = CandidateCardView(model: model)
        card.onProfileTapped = { [weak self] in
            let profileVC = ActorProfileViewController(userId: model.actorId)
            profileVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(profileVC, animated: true)
        }
        card.onPortfolioTapped = { [weak self] in
            let portfolioVC = PortfolioViewController()
            portfolioVC.targetUserId = model.actorId.uuidString
            portfolioVC.isOwnProfile = false
            let nav = UINavigationController(rootViewController: portfolioVC)
            nav.modalPresentationStyle = .fullScreen
            self?.present(nav, animated: true)
        }
        addPanGesture(to: card)
        return card
    }

    private func baseCardFrame() -> CGRect {
        let horizontalInset: CGFloat = 52
        let cardWidth = view.bounds.width - (horizontalInset * 2)
        let topY: CGFloat = max(146, view.safeAreaInsets.top + 118)
        let controlsTop = view.bounds.height - view.safeAreaInsets.bottom - 30 - 70
        let bottomGap: CGFloat = 34
        let cardHeight = min(430, controlsTop - topY - bottomGap)

        return CGRect(
            x: (view.bounds.width - cardWidth) / 2,
            y: topY,
            width: cardWidth,
            height: cardHeight
        )
    }

    private func applyStackLayout(to card: UIView, position: Int) {
        let baseFrame = baseCardFrame()

        // Progressive vertical offset — each card peeks further down
        let verticalOffset = CGFloat(position) * 12
        // Progressive scale — background cards are slightly smaller
        let scaleValues: [CGFloat] = [1.0, 0.94, 0.88]
        let scale = position < scaleValues.count ? scaleValues[position] : 0.88
        // Progressive alpha — background cards are slightly dimmed but VISIBLE
        let alphaValues: [CGFloat] = [1.0, 0.88, 0.72]
        let alpha = position < alphaValues.count ? alphaValues[position] : 0.0

        card.frame = baseFrame.offsetBy(dx: 0, dy: verticalOffset)
        card.transform = CGAffineTransform(scaleX: scale, y: scale)
        card.alpha = alpha
        card.isUserInteractionEnabled = position == 0

        if let candidateCard = card as? CandidateCardView {
            if position == 0 {
                candidateCard.playVideo()
            } else {
                candidateCard.pauseVideo()
            }
        }
    }

    private func addPanGesture(to card: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        card.addGestureRecognizer(pan)
    }

    // MARK: Swipe handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view as? CandidateCardView else { return }
        guard card === cardViews.last else { return }

        let translation = gesture.translation(in: view)
        let percent = translation.x / view.bounds.width

        switch gesture.state {
        case .began:
            activeCardCenter = card.center

        case .changed:
            card.center = CGPoint(
                x: activeCardCenter.x + translation.x,
                y: activeCardCenter.y + translation.y
            )
            card.transform = CGAffineTransform(rotationAngle: percent * 0.3)

        case .ended:
            if translation.x > 120 { animateSwipe(card, direction: 1) }
            else if translation.x < -120 { animateSwipe(card, direction: -1) }
            else { resetCard(card) }

        default: break
        }
    }

    // MARK: - UPDATED SWIPE LOGIC WITH COUNTERS AND SHORTLIST
    private func animateSwipe(_ card: CandidateCardView, direction: CGFloat) {
        guard let model = cardData.first else { return }

        // 👉 UPDATE COUNTERS AND SHORTLIST
        if direction > 0 {
            // Swiped right - shortlist the candidate
            shortlistedCount += 1
            shortlistedCountLabel.text = "\(shortlistedCount)"
            
            // Update application status to shortlisted in backend
            Task {
                await updateApplicationStatus(applicationId: model.applicationId, status: .shortlisted)
            }
        } else {
            // Swiped left - pass the candidate
            passedCount += 1
            passedCountLabel.text = "\(passedCount)"

            Task {
                await updateApplicationStatus(applicationId: model.applicationId, status: .rejected)
            }
        }

        UIView.animate(withDuration: 0.3, animations: {
            card.center.x += direction * 500
            card.transform = card.transform.rotated(by: direction * 0.12)
            card.alpha = 0
        }, completion: { _ in
            card.removeFromSuperview()
            
            // Check if job needs to move to 'pending' if it was 'active' and something was shortlisted
            if direction > 0 {
                self.ensureJobIsPending()
            }
            
            self.pushNextCard()
        })
    }
    
    private func ensureJobIsPending() {
        guard let job = job, job.status == .active else { return }
        
        Task {
            do {
                try await supabase
                    .from("jobs")
                    .update(["status": "pending"])
                    .eq("id", value: job.id.uuidString)
                    .execute()
                print("✅ Job state transitioned: ACTIVE -> PENDING for job \(job.id.uuidString.prefix(8))")
                // Update local job model too
                // self.job?.status = .pending // job is a var but we should handle it
            } catch {
                print("⚠️ Failed to update job status to pending: \(error)")
            }
        }
    }
    
    private func updateApplicationStatus(applicationId: UUID, status: Application.ApplicationStatus) async {
        do {
            struct ApplicationUpdate: Encodable {
                let status: String
            }
            
            let update = ApplicationUpdate(status: status.rawValue)
            
            try await supabase
                .from("applications")
                .update(update)
                .eq("id", value: applicationId.uuidString)
                .execute()
            
            print("✅ Updated application \(applicationId.uuidString.prefix(8)) to status: \(status.rawValue)")
        } catch {
            print("❌ Failed to update application status: \(error)")
        }
    }

    private func resetCard(_ card: CandidateCardView) {
        guard let cardIndex = cardViews.firstIndex(of: card) else { return }
        let position = (cardViews.count - 1) - cardIndex

        UIView.animate(withDuration: 0.25) {
            self.applyStackLayout(to: card, position: position)
        }
    }

    private func pushNextCard() {
        if cardViews.isEmpty { return }

        cardViews.removeLast()
        guard !cardData.isEmpty else { return }
        cardData.removeFirst()

        for (i, card) in cardViews.enumerated() {
            let position = cardViews.count - 1 - i
            UIView.animate(withDuration: 0.2) {
                self.applyStackLayout(to: card, position: position)
            }
        }

        if cardViews.count < maxCardsOnScreen && cardViews.count < cardData.count {
            let model = cardData[cardViews.count]
            let newCard = makeCard(for: model)
            applyStackLayout(to: newCard, position: cardViews.count)

            view.insertSubview(newCard, at: 0)
            cardViews.insert(newCard, at: 0)
        }

        bringUIElementsToFront()
    }

    // MARK: Button Actions
    @objc private func handleDislike() {
        guard let top = cardViews.last else { return }
        animateSwipe(top, direction: -1)
    }

    @objc private func handleLike() {
        guard let top = cardViews.last else { return }
        animateSwipe(top, direction: 1)
    }

    @objc private func openApplicationsScreen() {
        let vc = ApplicationsViewController()
        vc.job = job
        navigationController?.pushViewController(vc, animated: true)
    }
}
