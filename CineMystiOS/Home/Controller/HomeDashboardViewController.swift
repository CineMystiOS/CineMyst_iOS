//
//  HomeDashboardViewController.swift
//  CineMystApp
//
//  Updated: swipeable promo banner instead of stories,
//           fixed media grid (only renders cells for real images),
//           smooth entrance animations.
//

import UIKit
import SwiftUI
import PhotosUI

// MARK: - Design Tokens
enum CineMystTheme {
    static let brandPlum     = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 1)
    static let deepPlum      = UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1)
    static let deepPlumMid   = UIColor(red: 0.353, green: 0.118, blue: 0.259, alpha: 1)
    static let deepPlumDark  = UIColor(red: 0.176, green: 0.043, blue: 0.118, alpha: 1)
    static let pink          = UIColor(red: 0.804, green: 0.447, blue: 0.659, alpha: 1)
    static let pinkLight     = UIColor(red: 0.929, green: 0.796, blue: 0.878, alpha: 1)
    static let pinkPale      = UIColor(red: 0.969, green: 0.941, blue: 0.961, alpha: 1)
    static let accent        = UIColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1)
    static let gold          = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1)
    static let butterCream   = UIColor(red: 0.991, green: 0.965, blue: 0.865, alpha: 1)
    static let warmCream     = UIColor(red: 0.998, green: 0.984, blue: 0.941, alpha: 1)
    static let softMint      = UIColor(red: 0.760, green: 0.914, blue: 0.902, alpha: 1)
    static let softLavender  = UIColor(red: 0.855, green: 0.780, blue: 0.945, alpha: 1)
    static let peach         = UIColor(red: 0.977, green: 0.835, blue: 0.705, alpha: 1)
    static let ink           = UIColor(red: 0.181, green: 0.165, blue: 0.154, alpha: 1)
    static let plumMist      = UIColor(red: 0.957, green: 0.937, blue: 0.949, alpha: 1)
    static let plumHaze      = UIColor(red: 0.831, green: 0.733, blue: 0.784, alpha: 1)
    static let plumGlass     = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.10)
    static let cardRadius: CGFloat   = 22
    static let cardRadiusSm: CGFloat = 14
    static let homeCardInset: CGFloat = 14
}

// MARK: - Models
enum FeedItem {
    case promoBanner
    case communityHeader
    case post(Post)
    case job(Job)
    case ad(AdItem)
}

struct PromoCard {
    let title: String
    let subtitle: String
    let gradientStart: UIColor
    let gradientEnd: UIColor
    let ctaText: String

    static let all: [PromoCard] = [
        PromoCard(
            title: "Find Your Next Role",
            subtitle: "Browse casting calls from top production houses across India.",
            gradientStart: UIColor(red: 0.176, green: 0.043, blue: 0.118, alpha: 1),
            gradientEnd:   UIColor(red: 0.353, green: 0.118, blue: 0.259, alpha: 1),
            ctaText: "Browse Castings"
        ),
        PromoCard(
            title: "Connect with Directors",
            subtitle: "Build your network with directors and film professionals.",
            gradientStart: UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1),
            gradientEnd:   UIColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1),
            ctaText: "Start Networking"
        ),
        PromoCard(
            title: "Showcase Your Reel",
            subtitle: "Upload your portfolio and get discovered by casting teams.",
            gradientStart: UIColor(red: 0.5, green: 0.1, blue: 0.35, alpha: 1),
            gradientEnd:   UIColor(red: 0.804, green: 0.447, blue: 0.659, alpha: 1),
            ctaText: "Upload Reel"
        ),
        PromoCard(
            title: "Audition Coach",
            subtitle: "1-on-1 coaching with a free first session.",
            gradientStart: UIColor(red: 0.2, green: 0.05, blue: 0.35, alpha: 1),
            gradientEnd:   UIColor(red: 0.48, green: 0.23, blue: 0.93, alpha: 1),
            ctaText: "Book Session"
        ),
    ]
}

struct AdItem {
    let id: UUID
    let title: String
    let subtitle: String
    let ctaText: String
    let gradientStart: UIColor
    let gradientEnd: UIColor
    let emoji: String

    static func sample() -> [AdItem] { [
        AdItem(id: UUID(), title: "FilmSchool Online",
               subtitle: "Learn cinematography from award-winning directors",
               ctaText: "Explore Courses",
               gradientStart: CineMystTheme.deepPlum, gradientEnd: CineMystTheme.pink, emoji: "🎓"),
        AdItem(id: UUID(), title: "Script Coverage Pro",
               subtitle: "Professional feedback on your screenplay in 48 hours",
               ctaText: "Submit Script",
               gradientStart: UIColor(red: 0.3, green: 0.05, blue: 0.5, alpha: 1),
               gradientEnd: CineMystTheme.accent, emoji: "📝")
    ] }
}

struct HomeQuickLink {
    let title: String
    let tint: UIColor
    let accent: UIColor
    let icon: String

    static let all: [HomeQuickLink] = [
        .init(title: "Casting Calls", tint: UIColor(red: 0.918, green: 0.878, blue: 0.911, alpha: 1), accent: UIColor(red: 0.852, green: 0.780, blue: 0.872, alpha: 1), icon: "theatermasks.fill"),
        .init(title: "Portfolios", tint: UIColor(red: 0.928, green: 0.868, blue: 0.902, alpha: 1), accent: UIColor(red: 0.858, green: 0.768, blue: 0.828, alpha: 1), icon: "sparkles.tv.fill"),
        .init(title: "Directors", tint: UIColor(red: 0.894, green: 0.836, blue: 0.914, alpha: 1), accent: UIColor(red: 0.812, green: 0.735, blue: 0.845, alpha: 1), icon: "person.2.fill"),
        .init(title: "Auditions", tint: UIColor(red: 0.886, green: 0.902, blue: 0.948, alpha: 1), accent: UIColor(red: 0.792, green: 0.816, blue: 0.902, alpha: 1), icon: "music.mic")
    ]
}

// MARK: - HomeDashboardViewController
final class HomeDashboardViewController: UIViewController {

    private let tableView      = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowTop = UIView()
    private let ambientGlowBottom = UIView()
    private weak var chatBadgeLabel: UILabel?
    private var unreadMessagesSubscription: MessagesRealtimeSubscription?
    private var unreadMessagesCount = 0
    private var feedItems: [FeedItem] = []
    private var posts: [Post] = []
    private var jobs:  [Job]  = []
    private var ads = AdItem.sample()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        setupNavigationBar()
        setupTable()
        setupFloatingMenu()
        loadPosts()
        startUnreadMessageUpdates()
        navigationItem.backButtonTitle = ""
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        loadPosts()
        refreshUnreadMessageBadge()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowTop.layer.cornerRadius = ambientGlowTop.bounds.width / 2
        ambientGlowBottom.layer.cornerRadius = ambientGlowBottom.bounds.width / 2
        updateTableHeaderLayoutIfNeeded()
    }

    deinit {
        unreadMessagesSubscription?.cancel()
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

        ambientGlowTop.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.18)
        ambientGlowTop.layer.shadowColor = CineMystTheme.brandPlum.cgColor
        ambientGlowTop.layer.shadowOpacity = 0.24
        ambientGlowTop.layer.shadowRadius = 80
        ambientGlowTop.layer.shadowOffset = .zero

        ambientGlowBottom.backgroundColor = CineMystTheme.deepPlumMid.withAlphaComponent(0.12)
        ambientGlowBottom.layer.shadowColor = CineMystTheme.deepPlumMid.cgColor
        ambientGlowBottom.layer.shadowOpacity = 0.18
        ambientGlowBottom.layer.shadowRadius = 90
        ambientGlowBottom.layer.shadowOffset = .zero

        [ambientGlowTop, ambientGlowBottom].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ambientGlowTop.widthAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.heightAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.topAnchor.constraint(equalTo: view.topAnchor, constant: -40),
            ambientGlowTop.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 70),

            ambientGlowBottom.widthAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.heightAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -80),
            ambientGlowBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 40)
        ])
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {

        // Clear default items
        navigationItem.leftBarButtonItem = nil
        navigationItem.titleView = nil

        guard let navBar = navigationController?.navigationBar else { return }

        // MARK: - Find correct content view (CRITICAL FIX)
        guard let contentView = navBar.subviews.first(where: {
            String(describing: type(of: $0)).contains("ContentView")
        }) else { return }

        // MARK: - Add title safely (avoid duplicates)
        if contentView.viewWithTag(999) == nil {

            let titleLabel = UILabel()
            titleLabel.text = "CineMyst"
            titleLabel.font = UIFont(name: "Georgia-Bold", size: 26) ?? .boldSystemFont(ofSize: 26)
            titleLabel.textColor = CineMystTheme.ink
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.tag = 999

            contentView.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
            ])
        }

        // MARK: - Right Buttons
        navigationItem.rightBarButtonItems = [makeChatBarButton(), makeBellBarButton()]

        // MARK: - Search
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.placeholder = "Search posts or jobs"
        search.obscuresBackgroundDuringPresentation = false
        search.searchResultsUpdater = self
        search.searchBar.delegate = self
        let searchField = search.searchBar.searchTextField
        searchField.backgroundColor = UIColor.white.withAlphaComponent(0.34)
        searchField.textColor = CineMystTheme.ink
        searchField.tintColor = CineMystTheme.brandPlum
        searchField.layer.cornerRadius = 18
        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.18).cgColor
        searchField.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        searchField.layer.shadowOpacity = 1
        searchField.layer.shadowRadius = 18
        searchField.layer.shadowOffset = CGSize(width: 0, height: 8)
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search posts or jobs",
            attributes: [.foregroundColor: CineMystTheme.ink.withAlphaComponent(0.4)]
        )
        searchField.leftView?.tintColor = CineMystTheme.ink.withAlphaComponent(0.55)
        navigationItem.searchController = search
        definesPresentationContext = true

        // MARK: - Appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1)
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func removeInjectedHomeTitleIfNeeded() {
        guard let navBar = navigationController?.navigationBar,
              let contentView = navBar.subviews.first(where: {
                  String(describing: type(of: $0)).contains("ContentView")
              }) else { return }

        contentView.viewWithTag(999)?.removeFromSuperview()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeInjectedHomeTitleIfNeeded()
    }
    
    private func makeChatBarButton() -> UIBarButtonItem {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: 46))
        container.backgroundColor = .clear
        container.clipsToBounds = false

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        blur.frame = CGRect(x: 4, y: 4, width: 38, height: 38)
        blur.layer.cornerRadius = 19
        blur.clipsToBounds = true
        blur.layer.borderWidth = 1
        blur.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        container.addSubview(blur)

        let button = UIButton(type: .system)
        button.frame = blur.bounds
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: config), for: .normal)
        button.tintColor = CineMystTheme.ink.withAlphaComponent(0.78)
        button.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
        blur.contentView.addSubview(button)

        let badge = UILabel(frame: CGRect(x: 28, y: 1, width: 22, height: 22))
        badge.backgroundColor = CineMystTheme.brandPlum
        badge.textColor = .white
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 11
        badge.layer.masksToBounds = true
        badge.layer.borderWidth = 2
        badge.layer.borderColor = UIColor.white.withAlphaComponent(0.96).cgColor
        badge.layer.shadowColor = CineMystTheme.deepPlumDark.cgColor
        badge.layer.shadowOpacity = 0.16
        badge.layer.shadowRadius = 6
        badge.layer.shadowOffset = CGSize(width: 0, height: 2)
        badge.isHidden = true
        container.addSubview(badge)
        chatBadgeLabel = badge
        applyUnreadMessageBadge()
        return UIBarButtonItem(customView: container)
    }

    private func startUnreadMessageUpdates() {
        unreadMessagesSubscription?.cancel()
        unreadMessagesSubscription = MessagesService.shared.subscribeToConversationChanges { [weak self] in
            self?.refreshUnreadMessageBadge()
        }
        refreshUnreadMessageBadge()
    }

    private func refreshUnreadMessageBadge() {
        Task {
            let unreadCount = (try? await MessagesService.shared.fetchUnreadMessageCount()) ?? 0
            await MainActor.run {
                self.unreadMessagesCount = unreadCount
                self.applyUnreadMessageBadge()
            }
        }
    }

    private func applyUnreadMessageBadge() {
        guard let chatBadgeLabel else { return }
        if unreadMessagesCount > 0 {
            chatBadgeLabel.isHidden = false
            chatBadgeLabel.text = unreadMessagesCount > 99 ? "99+" : "\(unreadMessagesCount)"
            let text = chatBadgeLabel.text ?? ""
            let width = max(22, text.size(withAttributes: [.font: chatBadgeLabel.font as Any]).width + 10)
            chatBadgeLabel.frame = CGRect(x: 50 - width, y: 1, width: width, height: 22)
            chatBadgeLabel.layer.cornerRadius = 11
        } else {
            chatBadgeLabel.isHidden = true
            chatBadgeLabel.text = nil
        }
    }

    private func makeBellBarButton() -> UIBarButtonItem {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        blur.frame = CGRect(x: 0, y: 0, width: 38, height: 38)
        blur.layer.cornerRadius = 19
        blur.clipsToBounds = true
        blur.layer.borderWidth = 1
        blur.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor

        let button = UIButton(type: .system)
        button.frame = blur.bounds
        button.setImage(UIImage(systemName: "bell"), for: .normal)
        button.tintColor = CineMystTheme.ink.withAlphaComponent(0.78)
        button.addTarget(self, action: #selector(bellTapped), for: .touchUpInside)
        blur.contentView.addSubview(button)
        return UIBarButtonItem(customView: blur)
    }

    // MARK: - Table
    private func setupTable() {
        tableView.dataSource  = self; tableView.delegate = self
        tableView.separatorStyle = .none; tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.tableHeaderView = makeTableHeader()
        refreshControl.tintColor = CineMystTheme.pink
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(PromoBannerCell.self,  forCellReuseIdentifier: PromoBannerCell.reuseId)
        tableView.register(FeedSectionHeaderCell.self, forCellReuseIdentifier: FeedSectionHeaderCell.reuseId)
        tableView.register(CastingFeedCell.self,  forCellReuseIdentifier: CastingFeedCell.reuseId)
        tableView.register(PostFeedCell.self,     forCellReuseIdentifier: PostFeedCell.reuseId)
        tableView.register(AdBannerCell.self,     forCellReuseIdentifier: AdBannerCell.reuseId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeTableHeader() -> UIView {
        let header = HomeEditorialHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 252))
        header.translatesAutoresizingMaskIntoConstraints = false
        header.frame.size.width = view.bounds.width
        header.layoutIfNeeded()
        return header
    }

    private func updateTableHeaderLayoutIfNeeded() {
        guard let header = tableView.tableHeaderView else { return }
        var frame = header.frame
        if abs(frame.width - tableView.bounds.width) > 0.5 {
            frame.size.width = tableView.bounds.width
            header.frame = frame
            tableView.tableHeaderView = header
        }
    }

    private func setupFloatingMenu() {
        let sv = FloatingMenuButton(
            didTapCamera:  { [weak self] in self?.openCameraForPost() },
            didTapGallery: { [weak self] in self?.openGalleryForPost() },
            didTapAI: { [weak self] in self?.openAIAssistant() })
        let host = UIHostingController(rootView: sv)
        host.view.backgroundColor = .clear; host.view.isOpaque = false
        addChild(host); view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            host.view.widthAnchor.constraint(equalToConstant: 300),
            host.view.heightAnchor.constraint(equalToConstant: 320)
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Data
    @objc private func handleRefresh() { loadPosts() }

    private func loadPosts() {
        Task {
            do {
                let fetched = try await PostManager.shared.fetchPosts(limit: 50, offset: 0)
                await MainActor.run {
                    self.posts = fetched; self.rebuildFeed()
                    self.tableView.reloadData(); self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run { self.loadDummyData(); self.refreshControl.endRefreshing() }
            }
        }
    }

    private func rebuildFeed() {
        feedItems = [.promoBanner]
        if !posts.isEmpty {
            feedItems.append(.communityHeader)
        }
        var adIdx = 0
        for (i, post) in posts.enumerated() {
            feedItems.append(.post(post))
            if (i + 1) % 4 == 0, adIdx < ads.count { feedItems.append(.ad(ads[adIdx])); adIdx += 1 }
        }
        for job in jobs { feedItems.append(.job(job)) }
        if posts.isEmpty { feedItems.append(.ad(ads[0])) }
    }

    private func loadDummyData() {
        posts = []
        jobs = [
            Job(id: UUID(), directorId: UUID(), title: "Lead Actor - City of Dreams",
                companyName: "YRF Casting", location: "Mumbai", ratePerDay: 5000, jobType: "Web Series",
                description: "Looking for a lead actor for a web series.",
                requirements: "Acting experience preferred", referenceMaterialUrl: nil, status: .active,
                applicationDeadline: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
                createdAt: Date(), updatedAt: Date()),
            Job(id: UUID(), directorId: UUID(), title: "Assistant Director - Feature Film",
                companyName: "Red Chillies Entertainment", location: "Mumbai", ratePerDay: 3000, jobType: "Film",
                description: "Assist director during film production.", requirements: "Prior AD experience",
                referenceMaterialUrl: nil, status: .active,
                applicationDeadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                createdAt: Date(), updatedAt: Date())
        ]
        rebuildFeed(); tableView.reloadData()
    }

    @objc private func chatTapped() {
        let vc = MessagesViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func bellTapped() {
        let vc = NotificationsViewController(); vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    func openComments(for post: Post) {
        let vc = CommentViewController(post: post); vc.modalPresentationStyle = .pageSheet
        if let s = vc.sheetPresentationController { s.detents = [.medium(), .large()]; s.prefersGrabberVisible = true }
        present(vc, animated: true)
    }
    func openShareSheet(for post: Post) {
        let vc = ShareBottomSheetController(post: post); vc.modalPresentationStyle = .pageSheet
        if let s = vc.sheetPresentationController { s.detents = [.medium(), .large()]; s.prefersGrabberVisible = true }
        present(vc, animated: true)
    }
    private func openCameraForPost() { let vc = CameraViewController(); vc.modalPresentationStyle = .fullScreen; present(vc, animated: true) }
    private func openAIAssistant() {
        let vc = AIAssistantViewController()
        vc.hidesBottomBarWhenPushed = true
        if let navigationController {
            navigationController.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    private func openGalleryForPost() {
        var c = PHPickerConfiguration(); c.selectionLimit = 10; c.filter = .any(of: [.images, .videos])
        let p = PHPickerViewController(configuration: c); p.delegate = self; present(p, animated: true)
    }
    private func openPostComposer(with media: [DraftMedia]) {
        let c = PostComposerViewController(initialMedia: media); c.delegate = self
        c.modalPresentationStyle = .fullScreen; present(c, animated: true)
    }
}

private final class HomeEditorialHeaderView: UIView {
    private let contentColumn = UIView()
    private let panelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
    private let accentOrb = UIView()
    private let introLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let gridStack = UIStackView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear

        accentOrb.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        accentOrb.layer.borderWidth = 0
        addSubview(accentOrb)
        accentOrb.translatesAutoresizingMaskIntoConstraints = false

        panelView.layer.cornerRadius = 26
        panelView.clipsToBounds = true
        panelView.layer.borderWidth = 1
        panelView.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.14).cgColor
        panelView.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        panelView.layer.shadowOpacity = 1
        panelView.layer.shadowRadius = 22
        panelView.layer.shadowOffset = CGSize(width: 0, height: 12)
        panelView.contentView.backgroundColor = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.05)
        addSubview(panelView)
        panelView.translatesAutoresizingMaskIntoConstraints = false

        introLabel.text = "Today on CineMyst"
        introLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        introLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        introLabel.textAlignment = .center

        titleLabel.text = "Discover your next scene"
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 23) ?? .boldSystemFont(ofSize: 23)
        titleLabel.textColor = CineMystTheme.ink
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Elegant casting opportunities for you"
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.54)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.textAlignment = .center

        panelView.contentView.addSubview(contentColumn)
        contentColumn.translatesAutoresizingMaskIntoConstraints = false

        gridStack.axis = .vertical
        gridStack.spacing = 10
        gridStack.distribution = .fillEqually

        [introLabel, titleLabel, subtitleLabel, gridStack].forEach {
            contentColumn.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            accentOrb.widthAnchor.constraint(equalToConstant: 190),
            accentOrb.heightAnchor.constraint(equalToConstant: 190),
            accentOrb.topAnchor.constraint(equalTo: topAnchor, constant: -116),
            accentOrb.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 34),

            panelView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            panelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CineMystTheme.homeCardInset),
            panelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CineMystTheme.homeCardInset),
            panelView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            contentColumn.topAnchor.constraint(equalTo: panelView.contentView.topAnchor, constant: 12),
            contentColumn.leadingAnchor.constraint(equalTo: panelView.contentView.leadingAnchor, constant: 18),
            contentColumn.trailingAnchor.constraint(equalTo: panelView.contentView.trailingAnchor, constant: -18),
            contentColumn.bottomAnchor.constraint(equalTo: panelView.contentView.bottomAnchor, constant: -12)
        ])

        let rows = stride(from: 0, to: HomeQuickLink.all.count, by: 2).map {
            Array(HomeQuickLink.all[$0..<min($0 + 2, HomeQuickLink.all.count)])
        }

        for rowItems in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 14
            row.distribution = .fillEqually
            rowItems.forEach { row.addArrangedSubview(QuickLinkBubbleView(link: $0)) }
            gridStack.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: contentColumn.topAnchor, constant: 0),
            introLabel.leadingAnchor.constraint(equalTo: contentColumn.leadingAnchor),
            introLabel.trailingAnchor.constraint(equalTo: contentColumn.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: contentColumn.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentColumn.trailingAnchor, constant: -10),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentColumn.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentColumn.trailingAnchor, constant: -10),

            gridStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            gridStack.leadingAnchor.constraint(equalTo: contentColumn.leadingAnchor, constant: 10),
            gridStack.trailingAnchor.constraint(equalTo: contentColumn.trailingAnchor, constant: -10),
            gridStack.bottomAnchor.constraint(equalTo: contentColumn.bottomAnchor, constant: -2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accentOrb.layer.cornerRadius = accentOrb.bounds.width / 2
    }
}

private final class QuickLinkBubbleView: UIView {
    private let iconWrap = UIView()

    init(link: HomeQuickLink) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup(link: link)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup(link: HomeQuickLink) {
        let blob = BlobShapeView(colors: [link.tint, link.accent])
        addSubview(blob)
        blob.translatesAutoresizingMaskIntoConstraints = false

        iconWrap.backgroundColor = UIColor.white.withAlphaComponent(0.45)
        iconWrap.layer.cornerRadius = 21
        iconWrap.layer.borderWidth = 1
        iconWrap.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        iconWrap.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        iconWrap.layer.shadowOpacity = 1
        iconWrap.layer.shadowRadius = 14
        iconWrap.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(iconWrap)
        iconWrap.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: link.icon))
        iconView.tintColor = CineMystTheme.ink.withAlphaComponent(0.82)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconWrap.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = link.title
        label.font = UIFont(name: "Georgia", size: 12.5) ?? .systemFont(ofSize: 12.5, weight: .medium)
        label.textColor = CineMystTheme.ink
        label.textAlignment = .center
        label.numberOfLines = 2
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 84),

            blob.topAnchor.constraint(equalTo: topAnchor),
            blob.centerXAnchor.constraint(equalTo: centerXAnchor),
            blob.widthAnchor.constraint(equalToConstant: 72),
            blob.heightAnchor.constraint(equalToConstant: 56),

            iconWrap.centerXAnchor.constraint(equalTo: blob.centerXAnchor),
            iconWrap.centerYAnchor.constraint(equalTo: blob.centerYAnchor, constant: -1),
            iconWrap.widthAnchor.constraint(equalToConstant: 44),
            iconWrap.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),

            label.topAnchor.constraint(equalTo: blob.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        ])
    }
}

private final class BlobShapeView: UIView {
    private let gradient = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
        layer.shadowColor = CineMystTheme.ink.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        let path = UIBezierPath()
        let w = bounds.width
        let h = bounds.height
        path.move(to: CGPoint(x: 0.18 * w, y: 0.08 * h))
        path.addCurve(to: CGPoint(x: 0.82 * w, y: 0.12 * h), controlPoint1: CGPoint(x: 0.35 * w, y: -0.02 * h), controlPoint2: CGPoint(x: 0.67 * w, y: -0.01 * h))
        path.addCurve(to: CGPoint(x: 0.92 * w, y: 0.52 * h), controlPoint1: CGPoint(x: 1.02 * w, y: 0.18 * h), controlPoint2: CGPoint(x: 1.0 * w, y: 0.4 * h))
        path.addCurve(to: CGPoint(x: 0.68 * w, y: 0.94 * h), controlPoint1: CGPoint(x: 0.85 * w, y: 0.82 * h), controlPoint2: CGPoint(x: 0.82 * w, y: 1.02 * h))
        path.addCurve(to: CGPoint(x: 0.2 * w, y: 0.86 * h), controlPoint1: CGPoint(x: 0.5 * w, y: 0.88 * h), controlPoint2: CGPoint(x: 0.3 * w, y: 1.0 * h))
        path.addCurve(to: CGPoint(x: 0.08 * w, y: 0.34 * h), controlPoint1: CGPoint(x: 0.0 * w, y: 0.72 * h), controlPoint2: CGPoint(x: -0.02 * w, y: 0.48 * h))
        path.close()
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        layer.mask = shape
        layer.shadowPath = path.cgPath
    }
}

private final class ScallopDividerView: UIView {
    private let inverted: Bool

    init(inverted: Bool) {
        self.inverted = inverted
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setFillColor(CineMystTheme.plumMist.withAlphaComponent(0.8).cgColor)
        let radius: CGFloat = 18
        let circleCount = Int(ceil(rect.width / (radius * 2)))
        for index in 0...circleCount {
            let x = CGFloat(index) * radius * 2
            let y = inverted ? 0 : rect.height - radius * 2
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
        }
    }
}

extension HomeDashboardViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationController?.pushViewController(SearchViewController(), animated: true); return false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // Search functionality is handled by SearchViewController
    }
}

extension HomeDashboardViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { feedItems.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch feedItems[indexPath.row] {
        case .promoBanner:
            return tableView.dequeueReusableCell(withIdentifier: PromoBannerCell.reuseId, for: indexPath) as! PromoBannerCell
        case .communityHeader:
            return tableView.dequeueReusableCell(withIdentifier: FeedSectionHeaderCell.reuseId, for: indexPath) as! FeedSectionHeaderCell
        case .post(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostFeedCell.reuseId, for: indexPath) as! PostFeedCell
            cell.configure(with: post)
            cell.onComment = { [weak self] in self?.openComments(for: post) }
            cell.onShare   = { [weak self] in self?.openShareSheet(for: post) }
            cell.onProfile = { [weak self] in self?.navigationController?.pushViewController(ActorProfileViewController(), animated: true) }
            return cell
        case .job(let job):
            let cell = tableView.dequeueReusableCell(withIdentifier: CastingFeedCell.reuseId, for: indexPath) as! CastingFeedCell
            cell.configure(with: job); return cell
        case .ad(let ad):
            let cell = tableView.dequeueReusableCell(withIdentifier: AdBannerCell.reuseId, for: indexPath) as! AdBannerCell
            cell.configure(with: ad); return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch feedItems[indexPath.row] {
        case .promoBanner: return 194
        case .communityHeader: return 72
        case .post:        return UITableView.automaticDimension
        case .job:         return UITableView.automaticDimension
        case .ad:          return 110
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch feedItems[indexPath.row] {
        case .promoBanner: return 194
        case .communityHeader: return 72
        case .post:        return 380
        case .job:         return 280
        case .ad:          return 110
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .promoBanner = feedItems[indexPath.row] else {
            cell.transform = CGAffineTransform(translationX: 0, y: 28)
            cell.alpha = 0
            UIView.animate(withDuration: 0.38, delay: 0, options: .curveEaseOut) {
                cell.transform = .identity; cell.alpha = 1
            }
            return
        }
    }
}

private final class FeedSectionHeaderCell: UITableViewCell {
    static let reuseId = "FeedSectionHeaderCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        let capsule = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        capsule.layer.cornerRadius = 18
        capsule.clipsToBounds = true
        capsule.layer.borderWidth = 1
        capsule.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        contentView.addSubview(capsule)
        capsule.translatesAutoresizingMaskIntoConstraints = false

        let eyebrow = UILabel()
        eyebrow.text = "Community"
        eyebrow.font = .systemFont(ofSize: 11, weight: .semibold)
        eyebrow.textColor = CineMystTheme.deepPlum.withAlphaComponent(0.55)

        let title = UILabel()
        title.text = "Latest From Creators"
        title.font = UIFont(name: "Georgia-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        title.textColor = CineMystTheme.ink
        title.numberOfLines = 1

        let dot = UIView()
        dot.backgroundColor = CineMystTheme.pink.withAlphaComponent(0.9)
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let textStack = UIStackView(arrangedSubviews: [eyebrow, title])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [dot, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        capsule.contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            capsule.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            capsule.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            capsule.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            capsule.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            row.topAnchor.constraint(equalTo: capsule.contentView.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: capsule.contentView.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: capsule.contentView.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: capsule.contentView.bottomAnchor, constant: -12)
        ])
    }
}

extension HomeDashboardViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true); guard !results.isEmpty else { return }
        var media: [DraftMedia] = []; let group = DispatchGroup()
        for r in results {
            group.enter()
            if r.itemProvider.canLoadObject(ofClass: UIImage.self) {
                r.itemProvider.loadObject(ofClass: UIImage.self) { img, _ in
                    if let i = img as? UIImage { media.append(DraftMedia(image: i, videoURL: nil, type: .image)) }
                    group.leave()
                }
            } else { group.leave() }
        }
        group.notify(queue: .main) { [weak self] in self?.openPostComposer(with: media) }
    }
}

extension HomeDashboardViewController: PostComposerDelegate {
    func postComposerDidCreatePost(_ post: Post) {
        posts.insert(post, at: 0); rebuildFeed(); tableView.reloadData()
        let alert = UIAlertController(title: "✅ Posted!", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { alert.dismiss(animated: true) }
    }
    func postComposerDidCancel() {}
}


// MARK: ═══════════════════════════════════════════
// MARK: CELL: PromoBannerCell — swipeable cards
// MARK: ═══════════════════════════════════════════
final class PromoBannerCell: UITableViewCell, UIScrollViewDelegate {
    static let reuseId = "PromoBannerCell"

    private let shellView = UIView()
    private let scrollView  = UIScrollView()
    private let pageControl = UIPageControl()
    private let pagePill = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))

    private var autoTimer: Timer?
    private var cardViews: [PromoCardView] = []
    private var currentPage = 0
    private var previousBounds: CGSize = .zero

    // ✅ MATCH HEADER SPACING
    private let horizontalInset: CGFloat = 16

    // ✅ KEEP PEEK BUT HANDLE IT CORRECTLY
    private let cardPeek: CGFloat = 8
    private let cardGap: CGFloat = 14
    private let cardHeight: CGFloat = 154

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { autoTimer?.invalidate() }

    private func setupUI() {
        contentView.addSubview(shellView)
        shellView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.isPagingEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.decelerationRate = .fast

        // ✅ KEEP PEEK VISUAL ONLY
        scrollView.contentInset = UIEdgeInsets(top: 0, left: cardPeek, bottom: 0, right: cardPeek)

        shellView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        pageControl.numberOfPages = PromoCard.all.count
        pageControl.currentPage   = 0
        pageControl.currentPageIndicatorTintColor = CineMystTheme.brandPlum.withAlphaComponent(0.95)
        pageControl.pageIndicatorTintColor        = CineMystTheme.brandPlum.withAlphaComponent(0.12)
        pageControl.backgroundStyle = .minimal
        pageControl.allowsContinuousInteraction = false
        pageControl.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)

        pagePill.layer.cornerRadius = 16
        pagePill.clipsToBounds = true
        pagePill.layer.borderWidth = 1
        pagePill.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        pagePill.contentView.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.46)
        pagePill.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.06).cgColor
        pagePill.layer.shadowOpacity = 1
        pagePill.layer.shadowRadius = 10
        pagePill.layer.shadowOffset = CGSize(width: 0, height: 4)

        shellView.addSubview(pagePill)
        pagePill.contentView.addSubview(pageControl)

        pagePill.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            shellView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // ✅ 🔥 CRITICAL FIX HERE
            // subtract peek so visual edges align
            scrollView.leadingAnchor.constraint(equalTo: shellView.leadingAnchor, constant: horizontalInset - cardPeek),
            scrollView.trailingAnchor.constraint(equalTo: shellView.trailingAnchor, constant: -(horizontalInset - cardPeek)),

            scrollView.topAnchor.constraint(equalTo: shellView.topAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: cardHeight),

            pagePill.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            pagePill.centerXAnchor.constraint(equalTo: shellView.centerXAnchor),
            pagePill.bottomAnchor.constraint(equalTo: shellView.bottomAnchor),
            pagePill.heightAnchor.constraint(equalToConstant: 28),
            pagePill.widthAnchor.constraint(equalToConstant: 72),

            pageControl.centerXAnchor.constraint(equalTo: pagePill.contentView.centerXAnchor),
            pageControl.centerYAnchor.constraint(equalTo: pagePill.contentView.centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard scrollView.bounds.width > 0 else { return }

        if cardViews.isEmpty { buildCards() }

        if previousBounds != scrollView.bounds.size {
            previousBounds = scrollView.bounds.size
            layoutCards()
        }
    }

    private func buildCards() {
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()

        for (i, card) in PromoCard.all.enumerated() {
            let v = PromoCardView(promo: card)
            scrollView.addSubview(v)
            cardViews.append(v)

            v.alpha = 0
            v.transform = CGAffineTransform(translationX: 30, y: 0)

            UIView.animate(withDuration: 0.5,
                           delay: Double(i) * 0.1,
                           usingSpringWithDamping: 0.78,
                           initialSpringVelocity: 0.3) {
                v.alpha = 1
                v.transform = .identity
            }
        }

        layoutCards()
        startAutoScroll()
    }

    private func layoutCards() {
        let cardWidth = scrollView.bounds.width - (cardPeek * 2)

        let contentWidth =
            CGFloat(cardViews.count) * cardWidth +
            CGFloat(cardViews.count - 1) * cardGap

        scrollView.contentSize = CGSize(width: contentWidth, height: cardHeight)

        for (i, card) in cardViews.enumerated() {
            let x = CGFloat(i) * (cardWidth + cardGap)
            card.frame = CGRect(x: x, y: 0, width: cardWidth, height: cardHeight)
        }

        scrollToPage(currentPage, animated: false)
    }

    private func offsetForPage(_ page: Int) -> CGFloat {
        let cardWidth = scrollView.bounds.width - (cardPeek * 2)
        return CGFloat(page) * (cardWidth + cardGap) - cardPeek
    }

    private func scrollToPage(_ page: Int, animated: Bool) {
        scrollView.setContentOffset(
            CGPoint(x: offsetForPage(page), y: 0),
            animated: animated
        )
    }

    // MARK: - Auto scroll

    private func startAutoScroll() {
        autoTimer?.invalidate()

        autoTimer = Timer.scheduledTimer(withTimeInterval: 3.8, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentPage = (self.currentPage + 1) % self.cardViews.count
            self.scrollToPage(self.currentPage, animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let cardWidth = scrollView.bounds.width - (cardPeek * 2)

        let page = Int(round((scrollView.contentOffset.x + cardPeek) / (cardWidth + cardGap)))

        let safePage = max(0, min(page, cardViews.count - 1))

        if pageControl.currentPage != safePage {
            pageControl.currentPage = safePage
            currentPage = safePage
        }
    }
}

// MARK: - Shimmer accent line
private final class ShimmerLineView: UIView {
    private let gl = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        gl.colors = [UIColor.clear.cgColor, UIColor.white.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        gl.locations = [0, 0.5, 1]; gl.startPoint = CGPoint(x: 0, y: 0.5); gl.endPoint = CGPoint(x: 1, y: 0.5)
        gl.frame = frame; layer.addSublayer(gl)
        let a = CABasicAnimation(keyPath: "locations")
        a.fromValue = [-1.0, -0.5, 0.0]; a.toValue = [1.0, 1.5, 2.0]
        a.duration = 2.6; a.repeatCount = .infinity; gl.add(a, forKey: "shimmer")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gl.frame = bounds
    }
    required init?(coder: NSCoder) { fatalError() }
}

private final class PromoCardView: UIView {
    private let promo: PromoCard
    private let contentMaskView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let shimmer = ShimmerLineView(frame: .zero)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let ctaButton = UIButton(type: .system)
    private let ringA = UIView()
    private let ringB = UIView()

    init(promo: PromoCard) {
        self.promo = promo
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = 24
        layer.masksToBounds = false
        layer.shadowColor = CineMystTheme.deepPlumDark.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 28
        layer.shadowOffset = CGSize(width: 0, height: 18)

        contentMaskView.layer.cornerRadius = 24
        contentMaskView.clipsToBounds = true
        contentMaskView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        addSubview(contentMaskView)
        contentMaskView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [promo.gradientStart.cgColor, promo.gradientEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        contentMaskView.layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.colors = [
            UIColor.white.withAlphaComponent(0.28).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        glowLayer.startPoint = CGPoint(x: 0.15, y: 0)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        contentMaskView.layer.insertSublayer(glowLayer, above: gradientLayer)

        [ringA, ringB].forEach {
            $0.backgroundColor = UIColor.white.withAlphaComponent(0.07)
            contentMaskView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        ringA.layer.borderWidth = 1
        ringA.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        ringB.backgroundColor = UIColor.white.withAlphaComponent(0.04)

        titleLabel.text = promo.title
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 19) ?? .boldSystemFont(ofSize: 19)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        contentMaskView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = promo.subtitle
        subtitleLabel.font = .systemFont(ofSize: 12.5, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.numberOfLines = 2
        contentMaskView.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            promo.ctaText,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold)
            ])
        )
        config.image = UIImage(
            systemName: "arrow.up.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
        ctaButton.configuration = config
        ctaButton.tintColor = .white
        ctaButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        ctaButton.layer.cornerRadius = 14
        ctaButton.layer.borderWidth = 1
        ctaButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        ctaButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.14).cgColor
        ctaButton.layer.shadowOpacity = 1
        ctaButton.layer.shadowRadius = 10
        ctaButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        ctaButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        ctaButton.setContentHuggingPriority(.required, for: .horizontal)
        contentMaskView.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        contentMaskView.addSubview(shimmer)
        shimmer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentMaskView.topAnchor.constraint(equalTo: topAnchor),
            contentMaskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentMaskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentMaskView.leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: contentMaskView.topAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentMaskView.trailingAnchor, constant: -18),

            subtitleLabel.leadingAnchor.constraint(equalTo: contentMaskView.leadingAnchor, constant: 18),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentMaskView.trailingAnchor, constant: -18),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: ctaButton.topAnchor, constant: -12),

            ctaButton.leadingAnchor.constraint(equalTo: contentMaskView.leadingAnchor, constant: 18),
            ctaButton.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 12),
            ctaButton.bottomAnchor.constraint(equalTo: contentMaskView.bottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: 30),

            shimmer.leadingAnchor.constraint(equalTo: contentMaskView.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: contentMaskView.trailingAnchor),
            shimmer.bottomAnchor.constraint(equalTo: contentMaskView.bottomAnchor),
            shimmer.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 24).cgPath
    }

    func updateLayout() {
        gradientLayer.frame = contentMaskView.bounds
        glowLayer.frame = contentMaskView.bounds
        ringA.frame = CGRect(x: bounds.width - 132, y: -34, width: 144, height: 144)
        ringB.frame = CGRect(x: bounds.width - 92, y: 60, width: 132, height: 132)
        ringA.layer.cornerRadius = ringA.bounds.width / 2
        ringB.layer.cornerRadius = ringB.bounds.width / 2
        shimmer.frame = CGRect(x: 0, y: bounds.height - 2, width: bounds.width, height: 2)
    }

    func setEmphasis(_ emphasized: Bool) {
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            self.transform = emphasized ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
            self.layer.shadowOpacity = emphasized ? 0.28 : 0.18
        }
    }
}


// MARK: ═══════════════════════════════════════════
// MARK: CELL: PostFeedCell (fixed media grid)
// MARK: ═══════════════════════════════════════════

final class PostFeedCell: UITableViewCell {
    static let reuseId = "PostFeedCell"

    var onComment: (() -> Void)?
    var onShare:   (() -> Void)?
    var onProfile: (() -> Void)?
    
    private var postId: String = ""
    private var userId: String = ""

    private let card           = UIView()
    private let avatarView     = UIView()
    private let avatarImageView = UIImageView()
    private let avatarLabel    = UILabel()
    private let avatarGrad     = CAGradientLayer()
    private let nameLabel      = UILabel()
    private let roleLabel      = UILabel()
    private let timeLabel      = UILabel()
    private let captionLabel   = UILabel()
    private let mediaContainer = UIView()
    private let likeButton     = UIButton(type: .system)
    private let likeCount      = UILabel()
    private let commentButton  = UIButton(type: .system)
    private let commentCountLabel = UILabel()
    private let shareButton    = UIButton(type: .system)
    private var isLiked        = false
    private var currentLikeCount = 0
    private var currentCommentCount = 0

    // Dynamic height for media — set to 0 when no images
    private var mediaHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear; contentView.backgroundColor = .clear
        setupCard()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCard() {
        card.backgroundColor    = .white
        card.backgroundColor    = UIColor(red: 1.0, green: 0.995, blue: 0.985, alpha: 0.96)
        card.layer.cornerRadius  = CineMystTheme.cardRadius
        card.layer.borderWidth   = 0.5
        card.layer.borderColor   = UIColor(red: 0.92, green: 0.87, blue: 0.78, alpha: 1).cgColor
        card.layer.shadowColor   = CineMystTheme.ink.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius  = 16
        card.layer.shadowOffset  = CGSize(width: 0, height: 8)
        card.clipsToBounds = false
        contentView.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false

        // Avatar
        avatarView.layer.cornerRadius = 20; avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        avatarGrad.colors = [CineMystTheme.pink.cgColor, CineMystTheme.accent.cgColor]
        avatarGrad.startPoint = CGPoint(x: 0, y: 0); avatarGrad.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.addSublayer(avatarGrad)
        
        // Profile Image View (on top of gradient as fallback)
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarView.addSubview(avatarImageView); avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor)
        ])
        
        // Avatar Label (fallback text)
        avatarLabel.textColor = .white; avatarLabel.font = .boldSystemFont(ofSize: 14); avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel); avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        // Header
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = CineMystTheme.ink
        roleLabel.font = .systemFont(ofSize: 11, weight: .medium); roleLabel.textColor = CineMystTheme.deepPlum.withAlphaComponent(0.58)
        timeLabel.font = .systemFont(ofSize: 11); timeLabel.textColor = .secondaryLabel
        let dot = UILabel(); dot.text = "·"; dot.font = .systemFont(ofSize: 11); dot.textColor = .secondaryLabel
        let metaRow = UIStackView(arrangedSubviews: [roleLabel, dot, timeLabel])
        metaRow.axis = .horizontal; metaRow.spacing = 4; metaRow.alignment = .center
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, metaRow])
        infoStack.axis = .vertical; infoStack.spacing = 2
        let moreBtn = UIButton(type: .system)
        moreBtn.setImage(UIImage(systemName: "ellipsis"), for: .normal); moreBtn.tintColor = .secondaryLabel
        moreBtn.translatesAutoresizingMaskIntoConstraints = false
        moreBtn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        let headerRow = UIStackView(arrangedSubviews: [avatarView, infoStack, moreBtn])
        headerRow.axis = .horizontal; headerRow.spacing = 10; headerRow.alignment = .center
        card.addSubview(headerRow); headerRow.translatesAutoresizingMaskIntoConstraints = false

        // Caption
        captionLabel.font = UIFont(name: "Georgia", size: 13.5) ?? .systemFont(ofSize: 13.5)
        captionLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.92)
        captionLabel.numberOfLines = 4
        card.addSubview(captionLabel); captionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Media — height controlled by constraint
        mediaContainer.layer.cornerRadius = CineMystTheme.cardRadiusSm; mediaContainer.clipsToBounds = true
        card.addSubview(mediaContainer); mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        mediaHeightConstraint = mediaContainer.heightAnchor.constraint(equalToConstant: 0)
        mediaHeightConstraint.isActive = true

        // Separator
        let sep = UIView(); sep.backgroundColor = UIColor(red: 0.93, green: 0.89, blue: 0.82, alpha: 1)
        card.addSubview(sep); sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        // Reactions
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal); likeButton.tintColor = .secondaryLabel
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        likeCount.font = .systemFont(ofSize: 12); likeCount.textColor = .secondaryLabel
        let likeRow = UIStackView(arrangedSubviews: [likeButton, likeCount])
        likeRow.axis = .horizontal; likeRow.spacing = 4; likeRow.alignment = .center
        commentButton.setImage(UIImage(systemName: "bubble.left"), for: .normal); commentButton.tintColor = .secondaryLabel
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
        commentCountLabel.font = .systemFont(ofSize: 12); commentCountLabel.textColor = .secondaryLabel
        let commentRow = UIStackView(arrangedSubviews: [commentButton, commentCountLabel])
        commentRow.axis = .horizontal; commentRow.spacing = 4; commentRow.alignment = .center
        shareButton.setImage(UIImage(systemName: "paperplane"), for: .normal); shareButton.tintColor = .secondaryLabel
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        let spacer = UIView(); spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let reactionStack = UIStackView(arrangedSubviews: [likeRow, commentRow, spacer, shareButton])
        reactionStack.axis = .horizontal; reactionStack.spacing = 16; reactionStack.alignment = .center
        card.addSubview(reactionStack); reactionStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),

            headerRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            headerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            headerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            captionLabel.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            captionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            mediaContainer.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 10),
            mediaContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            mediaContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),

            sep.topAnchor.constraint(equalTo: mediaContainer.bottomAnchor, constant: 10),
            sep.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            reactionStack.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 10),
            reactionStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            reactionStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            reactionStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }

    // MARK: Configure
    func configure(with post: Post) {
        let name = post.username
        postId = post.id
        userId = post.userId
        nameLabel.text    = name
        roleLabel.text    = "Filmmaker"
        timeLabel.text    = timeAgo(from: post.createdAt)
        captionLabel.text = post.caption ?? ""
        currentLikeCount = post.likesCount
        currentCommentCount = post.commentsCount
        likeCount.text    = "\(post.likesCount)"
        commentCountLabel.text = "\(post.commentsCount)"
        isLiked = false
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .secondaryLabel

        // Load profile picture or show initials as fallback
        avatarLabel.text = String(name.prefix(1)).uppercased()
        if let picUrl = post.userProfilePictureUrl, let url = URL(string: picUrl) {
            loadProfileImage(from: url)
        } else {
            avatarImageView.image = nil
            avatarLabel.isHidden = false
        }

        // Build grid from ONLY the actual media URLs
        buildMediaGrid(urls: post.mediaUrls.map { $0.url })
        
        // Fetch actual counts from database
        Task {
            do {
                let actualCommentCount = try await PostManager.shared.fetchCommentCount(postId: postId)
                let actualLikeCount = try await PostManager.shared.fetchLikeCount(postId: postId)
                
                DispatchQueue.main.async {
                    self.currentCommentCount = actualCommentCount
                    self.currentLikeCount = actualLikeCount
                    self.commentCountLabel.text = "\(actualCommentCount)"
                    self.likeCount.text = "\(actualLikeCount)"
                }
            } catch {
                print("⚠️ Could not fetch actual counts: \(error)")
                // Keep current values if fetch fails
            }
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.avatarImageView.image = nil
                    self?.avatarLabel.isHidden = false
                }
                return
            }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
                self?.avatarLabel.isHidden = true
            }
        }.resume()
    }

    // MARK: Media Grid — only renders as many tiles as there are real images
    private func buildMediaGrid(urls: [String]) {
        mediaContainer.subviews.forEach { $0.removeFromSuperview() }

        guard !urls.isEmpty else {
            // No images → collapse the media area to zero height
            mediaHeightConstraint.constant = 0
            mediaContainer.isHidden = true
            return
        }

        mediaContainer.isHidden = false

        switch urls.count {

        case 1:
            // One image — full width, taller aspect
            mediaHeightConstraint.constant = 220
            let iv = makeImageView()
            iv.layer.cornerRadius = CineMystTheme.cardRadiusSm
            mediaContainer.addSubview(iv); iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
                iv.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor)
            ])
            loadImage(url: urls[0], into: iv)

        case 2:
            // Two images — side by side
            mediaHeightConstraint.constant = 160
            let iv1 = makeImageView(), iv2 = makeImageView()
            iv1.layer.cornerRadius = 8; iv2.layer.cornerRadius = 8
            [iv1, iv2].forEach { mediaContainer.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([
                iv1.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
                iv1.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
                iv1.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
                iv1.trailingAnchor.constraint(equalTo: mediaContainer.centerXAnchor, constant: -1.5),
                iv2.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
                iv2.leadingAnchor.constraint(equalTo: mediaContainer.centerXAnchor, constant: 1.5),
                iv2.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
                iv2.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor)
            ])
            loadImage(url: urls[0], into: iv1); loadImage(url: urls[1], into: iv2)

        default:
            // 3+ — big left, two stacked right
            mediaHeightConstraint.constant = 200
            let iv1 = makeImageView(), iv2 = makeImageView(), iv3 = makeImageView()
            iv1.layer.cornerRadius = 8; iv2.layer.cornerRadius = 8; iv3.layer.cornerRadius = 8

            let rightStack = UIStackView(arrangedSubviews: [iv2, iv3])
            rightStack.axis = .vertical; rightStack.spacing = 3; rightStack.distribution = .fillEqually

            mediaContainer.addSubview(iv1); mediaContainer.addSubview(rightStack)
            iv1.translatesAutoresizingMaskIntoConstraints = false
            rightStack.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                iv1.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
                iv1.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
                iv1.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
                iv1.widthAnchor.constraint(equalTo: mediaContainer.widthAnchor, multiplier: 0.58),

                rightStack.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
                rightStack.leadingAnchor.constraint(equalTo: iv1.trailingAnchor, constant: 3),
                rightStack.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
                rightStack.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor)
            ])
            loadImage(url: urls[0], into: iv1)
            loadImage(url: urls[1], into: iv2)
            loadImage(url: urls[2], into: iv3)

            // "+N more" overlay on the third tile
            if urls.count > 3 {
                let badge = UILabel()
                badge.text = "+\(urls.count - 3)"; badge.font = .boldSystemFont(ofSize: 18)
                badge.textColor = .white; badge.textAlignment = .center
                badge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
                badge.translatesAutoresizingMaskIntoConstraints = false
                iv3.addSubview(badge)
                NSLayoutConstraint.activate([
                    badge.topAnchor.constraint(equalTo: iv3.topAnchor),
                    badge.leadingAnchor.constraint(equalTo: iv3.leadingAnchor),
                    badge.trailingAnchor.constraint(equalTo: iv3.trailingAnchor),
                    badge.bottomAnchor.constraint(equalTo: iv3.bottomAnchor)
                ])
            }
        }
    }

    private func makeImageView() -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.5)
        return iv
    }

    private func loadImage(url: String, into iv: UIImageView) {
        guard let u = URL(string: url) else { return }
        URLSession.shared.dataTask(with: u) { data, _, _ in
            guard let d = data, let img = UIImage(data: d) else { return }
            DispatchQueue.main.async {
                UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) { iv.image = img }
            }
        }.resume()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGrad.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    }

    private func timeAgo(from date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 3600  { return "\(max(s / 60, 1))m" }
        if s < 86400 { return "\(s / 3600)h" }
        return "\(s / 86400)d"
    }

    @objc private func likeTapped() {
        isLiked.toggle()
        likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)
        likeButton.tintColor = isLiked ? .systemRed : .secondaryLabel
        
        // Update like count
        if isLiked {
            currentLikeCount += 1
        } else {
            currentLikeCount = max(0, currentLikeCount - 1)
        }
        likeCount.text = "\(currentLikeCount)"
        
        UIView.animate(withDuration: 0.15, animations: { self.likeButton.transform = CGAffineTransform(scaleX: 1.35, y: 1.35) }) { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 8) {
                self.likeButton.transform = .identity
            }
        }
        
        // Save like/unlike to database
        Task {
            do {
                if isLiked {
                    try await PostManager.shared.likePost(postId: postId)
                } else {
                    try await PostManager.shared.unlikePost(postId: postId)
                }
                print("✅ Like saved successfully")
            } catch {
                print("❌ Error saving like: \(error)")
                // Revert UI if save fails
                DispatchQueue.main.async {
                    self.isLiked.toggle()
                    self.likeButton.setImage(UIImage(systemName: self.isLiked ? "heart.fill" : "heart"), for: .normal)
                    self.likeButton.tintColor = self.isLiked ? .systemRed : .secondaryLabel
                    if self.isLiked {
                        self.currentLikeCount += 1
                    } else {
                        self.currentLikeCount = max(0, self.currentLikeCount - 1)
                    }
                    self.likeCount.text = "\(self.currentLikeCount)"
                }
            }
        }
    }

    @objc private func commentTapped() { onComment?() }
    @objc private func shareTapped()   { onShare?()   }
}


// MARK: ═══════════════════════════════════════════
// MARK: CELL: CastingFeedCell
// MARK: ═══════════════════════════════════════════

final class CastingFeedCell: UITableViewCell {
    static let reuseId = "CastingFeedCell"
    private let card = UIView(); private let cardGrad = CAGradientLayer()
    private let avatarView = UIView(); private let avatarLabel = UILabel()
    private let posterName = UILabel(); private let roleMeta = UILabel(); private let timeMeta = UILabel()
    private let captionLabel = UILabel(); private let bannerView = CastingBannerView()
    private let jobTitleLabel = UILabel(); private let locationLabel = UILabel()
    private let deadlineLabel = UILabel(); private let rateLabel = UILabel()
    private let applyButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear; contentView.backgroundColor = .clear
        build()
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); cardGrad.frame = card.bounds }

    private func build() {
        card.layer.cornerRadius = CineMystTheme.cardRadius; card.clipsToBounds = true
        contentView.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false
        cardGrad.colors = [CineMystTheme.deepPlumDark.cgColor, CineMystTheme.deepPlum.cgColor, CineMystTheme.deepPlumMid.cgColor]
        cardGrad.startPoint = CGPoint(x: 0, y: 0); cardGrad.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(cardGrad, at: 0)

        avatarView.layer.cornerRadius = 20; avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let ag = CAGradientLayer(); ag.frame = CGRect(x:0,y:0,width:40,height:40)
        ag.colors = [CineMystTheme.pink.cgColor, CineMystTheme.accent.cgColor]
        ag.startPoint = CGPoint(x:0,y:0); ag.endPoint = CGPoint(x:1,y:1)
        avatarView.layer.addSublayer(ag)
        avatarLabel.textColor = .white; avatarLabel.font = .boldSystemFont(ofSize: 11); avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel); avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
                                     avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)])

        posterName.font = .systemFont(ofSize: 13, weight: .semibold); posterName.textColor = .white
        let vi = UIImageView(image: UIImage(systemName: "checkmark.seal.fill")); vi.tintColor = .systemBlue
        vi.translatesAutoresizingMaskIntoConstraints = false
        vi.widthAnchor.constraint(equalToConstant: 14).isActive = true; vi.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let nameRow = UIStackView(arrangedSubviews: [posterName, vi]); nameRow.axis = .horizontal; nameRow.spacing = 4; nameRow.alignment = .center
        roleMeta.font = .systemFont(ofSize: 11, weight: .medium); roleMeta.textColor = CineMystTheme.pink
        timeMeta.font = .systemFont(ofSize: 11); timeMeta.textColor = UIColor.white.withAlphaComponent(0.5)
        let dl = UILabel(); dl.text = "·"; dl.textColor = UIColor.white.withAlphaComponent(0.4); dl.font = .systemFont(ofSize: 11)
        let mr = UIStackView(arrangedSubviews: [roleMeta, dl, timeMeta]); mr.axis = .horizontal; mr.spacing = 4; mr.alignment = .center
        let is2 = UIStackView(arrangedSubviews: [nameRow, mr]); is2.axis = .vertical; is2.spacing = 2
        let mb = UIButton(type: .system); mb.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        mb.tintColor = UIColor.white.withAlphaComponent(0.4); mb.translatesAutoresizingMaskIntoConstraints = false
        mb.widthAnchor.constraint(equalToConstant: 28).isActive = true
        let hs = UIStackView(arrangedSubviews: [avatarView, is2, mb]); hs.axis = .horizontal; hs.spacing = 10; hs.alignment = .center
        card.addSubview(hs); hs.translatesAutoresizingMaskIntoConstraints = false

        captionLabel.font = UIFont(name: "Georgia", size: 12.5) ?? .systemFont(ofSize: 12.5)
        captionLabel.textColor = UIColor.white.withAlphaComponent(0.65); captionLabel.numberOfLines = 2
        card.addSubview(captionLabel); captionLabel.translatesAutoresizingMaskIntoConstraints = false

        bannerView.layer.cornerRadius = CineMystTheme.cardRadiusSm; bannerView.clipsToBounds = true
        card.addSubview(bannerView); bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.heightAnchor.constraint(equalToConstant: 130).isActive = true

        jobTitleLabel.font = .systemFont(ofSize: 14, weight: .bold); jobTitleLabel.textColor = .white; jobTitleLabel.numberOfLines = 2
        locationLabel.font = .systemFont(ofSize: 11); locationLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        deadlineLabel.font = .systemFont(ofSize: 11); deadlineLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        rateLabel.font = .systemFont(ofSize: 12, weight: .semibold); rateLabel.textColor = CineMystTheme.pink
        let ds = UIStackView(arrangedSubviews: [jobTitleLabel, locationLabel, deadlineLabel, rateLabel])
        ds.axis = .vertical; ds.spacing = 3

        applyButton.layer.cornerRadius = 22; applyButton.clipsToBounds = true
        applyButton.setImage(UIImage(systemName: "arrow.right"), for: .normal); applyButton.tintColor = .white
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        applyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        let apg = CAGradientLayer(); apg.colors = [CineMystTheme.pink.cgColor, CineMystTheme.accent.cgColor]
        apg.startPoint = CGPoint(x:0,y:0); apg.endPoint = CGPoint(x:1,y:1); apg.cornerRadius = 22
        applyButton.layer.insertSublayer(apg, at: 0)
        DispatchQueue.main.async { apg.frame = self.applyButton.bounds }

        let jr = UIStackView(arrangedSubviews: [ds, applyButton]); jr.axis = .horizontal; jr.spacing = 12; jr.alignment = .center
        card.addSubview(jr); jr.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
            hs.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            hs.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            hs.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            captionLabel.topAnchor.constraint(equalTo: hs.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            captionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            bannerView.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 10),
            bannerView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            bannerView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            jr.topAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: 12),
            jr.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            jr.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            jr.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    func configure(with job: Job) {
        avatarLabel.text = String((job.companyName ?? "CM").prefix(3)).uppercased()
        posterName.text = job.companyName ?? "CineMyst Production"
        roleMeta.text = job.jobType ?? "Project"
        timeMeta.text = "2h"
        captionLabel.text = "CASTING CALL: \(job.title ?? "Untitled"). \(job.description ?? "")"
        jobTitleLabel.text = job.title ?? "Untitled Job"
        locationLabel.text = "📍 \(job.location ?? "Remote")"
        if let d = job.applicationDeadline {
            let f = DateFormatter(); f.dateFormat = "MMM dd, yyyy"
            deadlineLabel.text = "Deadline: \(f.string(from: d))"
        }
        let rate = job.ratePerDay ?? 0
        rateLabel.text = "₹\(rate * 8 / 1000)K – ₹\(rate * 12 / 1000)K"
    }

    @objc private func applyTapped() {
        UIView.animate(withDuration: 0.12, animations: { self.applyButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88) }) { _ in
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6) { self.applyButton.transform = .identity }
        }
    }
}

// MARK: - CastingBannerView
final class CastingBannerView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let castingLabel  = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor(red:0.04,green:0.02,blue:0.08,alpha:1).cgColor,
            UIColor(red:0.08,green:0.02,blue:0.16,alpha:1).cgColor,
            UIColor(red:0.04,green:0.08,blue:0.18,alpha:1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x:0,y:0); gradientLayer.endPoint = CGPoint(x:1,y:1)
        layer.addSublayer(gradientLayer)
        castingLabel.text = "CASTING"
        castingLabel.font = UIFont(name: "Georgia-BoldItalic", size: 36) ?? .boldSystemFont(ofSize: 36)
        castingLabel.textColor = UIColor(red:0.8,green:0.12,blue:0.12,alpha:1); castingLabel.textAlignment = .center
        castingLabel.layer.shadowColor = UIColor.red.cgColor; castingLabel.layer.shadowRadius = 16
        castingLabel.layer.shadowOpacity = 0.7; castingLabel.layer.shadowOffset = .zero
        addSubview(castingLabel); castingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([castingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     castingLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 8)])
        let p = CABasicAnimation(keyPath: "shadowOpacity"); p.fromValue = 0.3; p.toValue = 0.85
        p.duration = 1.5; p.autoreverses = true; p.repeatCount = .infinity; castingLabel.layer.add(p, forKey: "pulse")
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); gradientLayer.frame = bounds }
}


// MARK: ═══════════════════════════════════════════
// MARK: CELL: AdBannerCell
// MARK: ═══════════════════════════════════════════

final class AdBannerCell: UITableViewCell {
    static let reuseId = "AdBannerCell"
    private let card = UIView(); private let cardGrad = CAGradientLayer()
    private let emojiLabel = UILabel(); private let adTag = UILabel()
    private let titleLabel = UILabel(); private let subtitleLabel = UILabel()
    private let ctaButton  = UIButton(type: .system)
    private var gradStart  = CineMystTheme.deepPlum; private var gradEnd = CineMystTheme.pink

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear; contentView.backgroundColor = .clear
        build()
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); cardGrad.frame = card.bounds; cardGrad.colors = [gradStart.cgColor, gradEnd.cgColor] }

    private func build() {
        card.layer.cornerRadius = CineMystTheme.cardRadius; card.clipsToBounds = true
        contentView.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false
        cardGrad.startPoint = CGPoint(x:0,y:0.5); cardGrad.endPoint = CGPoint(x:1,y:0.5)
        card.layer.insertSublayer(cardGrad, at: 0)
        adTag.text = "Sponsored"; adTag.font = .systemFont(ofSize: 9, weight: .semibold)
        adTag.textColor = UIColor.white.withAlphaComponent(0.75); adTag.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        adTag.layer.cornerRadius = 8; adTag.clipsToBounds = true; adTag.textAlignment = .center
        adTag.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(adTag)
        emojiLabel.font = .systemFont(ofSize: 32); emojiLabel.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(emojiLabel)
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold); titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(titleLabel)
        subtitleLabel.font = .systemFont(ofSize: 11); subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.numberOfLines = 2; subtitleLabel.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(subtitleLabel)
        ctaButton.setTitleColor(.white, for: .normal); ctaButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        ctaButton.layer.cornerRadius = 12; ctaButton.layer.borderWidth = 1.5
        ctaButton.layer.borderColor = UIColor.white.withAlphaComponent(0.65).cgColor
        ctaButton.contentEdgeInsets = UIEdgeInsets(top:6,left:14,bottom:6,right:14)
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(ctaButton)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            adTag.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            adTag.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            adTag.widthAnchor.constraint(equalToConstant: 68), adTag.heightAnchor.constraint(equalToConstant: 18),
            emojiLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            ctaButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            ctaButton.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }

    func configure(with ad: AdItem) {
        gradStart = ad.gradientStart; gradEnd = ad.gradientEnd; emojiLabel.text = ad.emoji
        titleLabel.text = ad.title; subtitleLabel.text = ad.subtitle; ctaButton.setTitle(ad.ctaText, for: .normal)
        setNeedsLayout()
    }

    @objc private func ctaTapped() {
        UIView.animate(withDuration: 0.1, animations: { self.ctaButton.transform = CGAffineTransform(scaleX: 0.94, y: 0.94) }) { _ in
            UIView.animate(withDuration: 0.15) { self.ctaButton.transform = .identity }
        }
    }
}
