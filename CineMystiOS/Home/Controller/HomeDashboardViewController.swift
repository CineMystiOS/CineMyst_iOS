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
    static let deepPlum      = UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1)
    static let deepPlumMid   = UIColor(red: 0.353, green: 0.118, blue: 0.259, alpha: 1)
    static let deepPlumDark  = UIColor(red: 0.176, green: 0.043, blue: 0.118, alpha: 1)
    static let pink          = UIColor(red: 0.804, green: 0.447, blue: 0.659, alpha: 1)
    static let pinkLight     = UIColor(red: 0.929, green: 0.796, blue: 0.878, alpha: 1)
    static let pinkPale      = UIColor(red: 0.969, green: 0.941, blue: 0.961, alpha: 1)
    static let accent        = UIColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1)
    static let gold          = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1)
    static let cardRadius: CGFloat   = 22
    static let cardRadiusSm: CGFloat = 14
}

// MARK: - Models
enum FeedItem {
    case promoBanner
    case post(Post)
    case job(Job)
    case ad(AdItem)
}

struct PromoCard {
    let title: String
    let subtitle: String
    let emoji: String
    let gradientStart: UIColor
    let gradientEnd: UIColor
    let ctaText: String

    static let all: [PromoCard] = [
        PromoCard(
            title: "Find Your Next Role",
            subtitle: "Browse 500+ casting calls from top production houses across India.",
            emoji: "🎬",
            gradientStart: UIColor(red: 0.176, green: 0.043, blue: 0.118, alpha: 1),
            gradientEnd:   UIColor(red: 0.353, green: 0.118, blue: 0.259, alpha: 1),
            ctaText: "Browse Castings"
        ),
        PromoCard(
            title: "Connect with Directors",
            subtitle: "DM industry veterans and build your film network on CineMyst.",
            emoji: "🤝",
            gradientStart: UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1),
            gradientEnd:   UIColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1),
            ctaText: "Start Networking"
        ),
        PromoCard(
            title: "Showcase Your Reel",
            subtitle: "Upload your portfolio and get discovered by casting directors worldwide.",
            emoji: "🎥",
            gradientStart: UIColor(red: 0.5, green: 0.1, blue: 0.35, alpha: 1),
            gradientEnd:   UIColor(red: 0.804, green: 0.447, blue: 0.659, alpha: 1),
            ctaText: "Upload Reel"
        ),
        PromoCard(
            title: "Audition Coach — Free Trial",
            subtitle: "1-on-1 sessions with industry coaches. First session completely free.",
            emoji: "🎤",
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

// MARK: - HomeDashboardViewController
final class HomeDashboardViewController: UIViewController {

    private let tableView      = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private var feedItems: [FeedItem] = []
    private var posts: [Post] = []
    private var jobs:  [Job]  = []
    private var ads = AdItem.sample()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupNavigationBar()
        setupTable()
        setupFloatingMenu()
        loadPosts()
        navigationItem.backButtonTitle = ""
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        loadPosts()
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
            titleLabel.textColor = .white
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.tag = 999

            contentView.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
            ])
        }

        // MARK: - Right Buttons
        let bellBtn = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(bellTapped)
        )
        bellBtn.tintColor = CineMystTheme.pink

        navigationItem.rightBarButtonItems = [makeAvatarBarButton(), bellBtn]

        // MARK: - Search
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.placeholder = "Search posts or jobs"
        search.obscuresBackgroundDuringPresentation = false
        search.searchResultsUpdater = self
        search.searchBar.delegate = self
        navigationItem.searchController = search
        definesPresentationContext = true

        // MARK: - Appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CineMystTheme.deepPlum
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
    
    private func makeAvatarBarButton() -> UIBarButtonItem {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
        v.layer.cornerRadius = 17; v.clipsToBounds = true
        v.layer.borderWidth = 2; v.layer.borderColor = CineMystTheme.pinkLight.cgColor
        let g = CAGradientLayer()
        g.frame = v.bounds
        g.colors = [CineMystTheme.pink.cgColor, CineMystTheme.accent.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0); g.endPoint = CGPoint(x: 1, y: 1)
        v.layer.addSublayer(g)
        let l = UILabel(frame: v.bounds); l.text = "A"; l.textAlignment = .center
        l.font = .boldSystemFont(ofSize: 14); l.textColor = .white
        v.addSubview(l)
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
        v.isUserInteractionEnabled = true
        return UIBarButtonItem(customView: v)
    }

    // MARK: - Table
    private func setupTable() {
        tableView.dataSource  = self; tableView.delegate = self
        tableView.separatorStyle = .none; tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = CineMystTheme.pinkPale
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        refreshControl.tintColor = CineMystTheme.pink
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(PromoBannerCell.self,  forCellReuseIdentifier: PromoBannerCell.reuseId)
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

    private func setupFloatingMenu() {
        let sv = FloatingMenuButton(
            didTapCamera:  { [weak self] in self?.openCameraForPost() },
            didTapGallery: { [weak self] in self?.openGalleryForPost() })
        let host = UIHostingController(rootView: sv)
        host.view.backgroundColor = .clear; host.view.isOpaque = false
        addChild(host); view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 8), // Overlaps or sits just above tab bar
            host.view.widthAnchor.constraint(equalToConstant: 280),
            host.view.heightAnchor.constraint(equalToConstant: 280)
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

    @objc private func profileTapped() { navigationController?.pushViewController(ProfileViewController(), animated: true) }
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
    private func openGalleryForPost() {
        var c = PHPickerConfiguration(); c.selectionLimit = 10; c.filter = .any(of: [.images, .videos])
        let p = PHPickerViewController(configuration: c); p.delegate = self; present(p, animated: true)
    }
    private func openPostComposer(with media: [DraftMedia]) {
        let c = PostComposerViewController(initialMedia: media); c.delegate = self
        c.modalPresentationStyle = .fullScreen; present(c, animated: true)
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
        case .post(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostFeedCell.reuseId, for: indexPath) as! PostFeedCell
            cell.configure(with: post)
            cell.onComment = { [weak self] in self?.openComments(for: post) }
            cell.onShare   = { [weak self] in self?.openShareSheet(for: post) }
            cell.onProfile = { [weak self] in self?.navigationController?.pushViewController(ProfileViewController(), animated: true) }
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
        case .promoBanner: return 210
        case .post:        return UITableView.automaticDimension
        case .job:         return UITableView.automaticDimension
        case .ad:          return 110
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch feedItems[indexPath.row] {
        case .promoBanner: return 210
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

    private let scrollView  = UIScrollView()
    private let pageControl = UIPageControl()
    private var autoTimer: Timer?
    private var cardViews: [UIView] = []
    private var currentPage = 0
    private var didBuildCards = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear; contentView.backgroundColor = .clear
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    deinit { autoTimer?.invalidate() }

    private func setupUI() {
        scrollView.isPagingEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.decelerationRate = .fast
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        pageControl.numberOfPages = PromoCard.all.count
        pageControl.currentPage   = 0
        pageControl.currentPageIndicatorTintColor = CineMystTheme.pink
        pageControl.pageIndicatorTintColor        = CineMystTheme.pink.withAlphaComponent(0.3)
        pageControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        contentView.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 168),

            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didBuildCards, scrollView.bounds.width > 0 else { return }
        didBuildCards = true
        buildCards()
        startAutoScroll()
    }

    private func buildCards() {
        let cardW  = scrollView.bounds.width - 40  // 20pt peek on each side
        let gap: CGFloat = 12
        let totalWidth = 20 + CGFloat(PromoCard.all.count) * (cardW + gap)
        scrollView.contentSize = CGSize(width: totalWidth, height: 168)

        for (i, card) in PromoCard.all.enumerated() {
            let x = 20 + CGFloat(i) * (cardW + gap)
            let v = makeCard(card, frame: CGRect(x: x, y: 0, width: cardW, height: 168))
            scrollView.addSubview(v)
            cardViews.append(v)
            // Stagger entrance
            v.alpha = 0; v.transform = CGAffineTransform(translationX: 30, y: 0)
            UIView.animate(withDuration: 0.5, delay: Double(i) * 0.1,
                           usingSpringWithDamping: 0.78, initialSpringVelocity: 0.3) {
                v.alpha = 1; v.transform = .identity
            }
        }
    }

    private func makeCard(_ promo: PromoCard, frame: CGRect) -> UIView {
        let v = UIView(frame: frame)
        v.layer.cornerRadius = 18; v.clipsToBounds = true

        let grad = CAGradientLayer()
        grad.frame = CGRect(origin: .zero, size: frame.size)
        grad.colors = [promo.gradientStart.cgColor, promo.gradientEnd.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 1)
        v.layer.insertSublayer(grad, at: 0)

        // Decorative circles
        let c1 = UIView(frame: CGRect(x: frame.width - 50, y: -50, width: 130, height: 130))
        c1.backgroundColor = UIColor.white.withAlphaComponent(0.06); c1.layer.cornerRadius = 65
        let c2 = UIView(frame: CGRect(x: frame.width - 90, y: -20, width: 170, height: 170))
        c2.backgroundColor = UIColor.white.withAlphaComponent(0.03); c2.layer.cornerRadius = 85
        v.addSubview(c2); v.addSubview(c1)

        // Shimmer line
        let shimmer = ShimmerLineView(frame: CGRect(x: 0, y: frame.height - 2, width: frame.width, height: 2))
        v.addSubview(shimmer)

        // Content
        let emoji = UILabel(); emoji.text = promo.emoji; emoji.font = .systemFont(ofSize: 36)
        emoji.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(emoji)

        let title = UILabel(); title.text = promo.title
        title.font = UIFont(name: "Georgia-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
        title.textColor = .white; title.numberOfLines = 2
        title.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(title)

        let subtitle = UILabel(); subtitle.text = promo.subtitle
        subtitle.font = .systemFont(ofSize: 12); subtitle.textColor = UIColor.white.withAlphaComponent(0.78)
        subtitle.numberOfLines = 2; subtitle.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(subtitle)

        let cta = UIButton(type: .system)
        cta.setTitle(promo.ctaText, for: .normal); cta.setTitleColor(.white, for: .normal)
        cta.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        cta.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        cta.layer.cornerRadius = 13; cta.layer.borderWidth = 1
        cta.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        cta.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        cta.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(cta)

        NSLayoutConstraint.activate([
            emoji.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 18),
            emoji.topAnchor.constraint(equalTo: v.topAnchor, constant: 16),

            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 18),
            title.topAnchor.constraint(equalTo: emoji.bottomAnchor, constant: 4),
            title.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -18),

            subtitle.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 18),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitle.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -18),

            cta.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 18),
            cta.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -16)
        ])
        return v
    }

    // MARK: - Auto scroll
    private func startAutoScroll() {
        autoTimer?.invalidate()
        autoTimer = Timer.scheduledTimer(withTimeInterval: 3.8, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentPage = (self.currentPage + 1) % PromoCard.all.count
            self.scrollToPage(self.currentPage, animated: true)
        }
    }

    private func scrollToPage(_ page: Int, animated: Bool) {
        guard scrollView.bounds.width > 0 else { return }
        let cardW = scrollView.bounds.width - 40
        let gap: CGFloat = 12
        let x = 20 + CGFloat(page) * (cardW + gap)
        scrollView.setContentOffset(CGPoint(x: max(x, 0), y: 0), animated: animated)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let cardW = scrollView.bounds.width - 40
        let gap: CGFloat = 12
        let page = max(0, min(Int((scrollView.contentOffset.x + cardW / 2 - 20) / (cardW + gap)), PromoCard.all.count - 1))
        if pageControl.currentPage != page {
            pageControl.currentPage = page; currentPage = page
            for (i, v) in cardViews.enumerated() {
                UIView.animate(withDuration: 0.22) {
                    v.transform = (i == page) ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
                }
            }
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { autoTimer?.invalidate(); autoTimer = nil }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { startAutoScroll() }
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
    required init?(coder: NSCoder) { fatalError() }
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
        card.layer.cornerRadius  = CineMystTheme.cardRadius
        card.layer.borderWidth   = 0.5
        card.layer.borderColor   = CineMystTheme.pinkLight.withAlphaComponent(0.6).cgColor
        card.layer.shadowColor   = CineMystTheme.deepPlum.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowRadius  = 8
        card.layer.shadowOffset  = CGSize(width: 0, height: 2)
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
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = UIColor(red: 0.1, green: 0.04, blue: 0.07, alpha: 1)
        roleLabel.font = .systemFont(ofSize: 11); roleLabel.textColor = CineMystTheme.pink.withAlphaComponent(0.8)
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
        captionLabel.font = UIFont(name: "Georgia", size: 13) ?? .systemFont(ofSize: 13)
        captionLabel.textColor = UIColor(red: 0.18, green: 0.07, blue: 0.13, alpha: 1)
        captionLabel.numberOfLines = 4
        card.addSubview(captionLabel); captionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Media — height controlled by constraint
        mediaContainer.layer.cornerRadius = CineMystTheme.cardRadiusSm; mediaContainer.clipsToBounds = true
        card.addSubview(mediaContainer); mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        mediaHeightConstraint = mediaContainer.heightAnchor.constraint(equalToConstant: 0)
        mediaHeightConstraint.isActive = true

        // Separator
        let sep = UIView(); sep.backgroundColor = CineMystTheme.pinkLight.withAlphaComponent(0.5)
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
        iv.backgroundColor = CineMystTheme.pinkPale
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
        avatarLabel.text = String(job.companyName.prefix(3)).uppercased()
        posterName.text = job.companyName; roleMeta.text = job.jobType; timeMeta.text = "2h"
        captionLabel.text = "CASTING CALL: \(job.title). \(job.description)"
        jobTitleLabel.text = job.title; locationLabel.text = "📍 \(job.location)"
        if let d = job.applicationDeadline {
            let f = DateFormatter(); f.dateFormat = "MMM dd, yyyy"
            deadlineLabel.text = "Deadline: \(f.string(from: d))"
        }
        rateLabel.text = "₹\(job.ratePerDay * 8 / 1000)K – ₹\(job.ratePerDay * 12 / 1000)K"
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
