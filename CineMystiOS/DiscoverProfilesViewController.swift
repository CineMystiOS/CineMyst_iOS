import UIKit
import Supabase

class DiscoverProfilesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Properties
    private var profiles: [DiscoveryProfile] = []
    private var loadTask: Task<Void, Never>?
    
    // MARK: Subviews
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 12
        let width = (UIScreen.main.bounds.width - (spacing * 3)) / 2
        layout.itemSize = CGSize(width: width, height: 210)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 16, left: spacing, bottom: 16, right: spacing)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(hex: "#FAF0F6")
        cv.register(DiscoveryMiniCardCell.self, forCellWithReuseIdentifier: DiscoveryMiniCardCell.reuseId)
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(hex: "#431631")
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadRecommendedProfiles()
    }

    deinit {
        loadTask?.cancel()
    }
    
    // MARK: Setup
    private func setupNavigationBar() {
        view.backgroundColor = UIColor(hex: "#FAF0F6")
        title = "Discover Profiles"
        navigationController?.navigationBar.tintColor = UIColor(hex: "#431631")
        
        // Add a nice back button if pushed, or close if presented modally
        if let nav = navigationController, nav.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeTapped))
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 24),
            emptyLabel.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -24)
        ])
    }
    
    // MARK: Data
    private func loadRecommendedProfiles() {
        loadTask?.cancel()

        guard let currentUserId = supabase.auth.currentUser?.id else {
            showEmptyState("Complete sign-in to get suggestions.")
            return
        }

        if let cachedProfiles = RecommendationsService.shared.cachedDiscoveryProfiles(for: currentUserId) {
            profiles = cachedProfiles
            collectionView.reloadData()
            emptyLabel.isHidden = !cachedProfiles.isEmpty
            emptyLabel.text = cachedProfiles.isEmpty ? "No suggested profiles available yet." : nil
            activityIndicator.stopAnimating()
            return
        }

        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        profiles = []
        collectionView.reloadData()

        loadTask = Task { [weak self] in
            do {
                let profiles = try await RecommendationsService.shared.fetchDiscoveryProfiles(for: currentUserId)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.activityIndicator.stopAnimating()
                    self?.profiles = profiles
                    self?.collectionView.reloadData()
                    self?.emptyLabel.isHidden = !profiles.isEmpty
                    self?.emptyLabel.text = profiles.isEmpty ? "No suggested profiles available yet." : nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("❌ Failed to fetch discover profiles: \(error)")
                await MainActor.run {
                    self?.showEmptyState("No suggested profiles available yet.")
                }
            }
        }
    }

    private func showEmptyState(_ message: String) {
        activityIndicator.stopAnimating()
        profiles = []
        collectionView.reloadData()
        emptyLabel.text = message
        emptyLabel.isHidden = false
    }
    
    // MARK: UICollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoveryMiniCardCell.reuseId, for: indexPath) as? DiscoveryMiniCardCell else {
            fatalError()
        }
        let profile = profiles[indexPath.item]
        cell.configure(with: profile)
        cell.onViewTapped = { [weak self] in
            self?.navigateToProfile(profile)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profile = profiles[indexPath.item]
        navigateToProfile(profile)
    }
    
    private func navigateToProfile(_ profile: DiscoveryProfile) {
        let vc = ActorProfileViewController(userId: profile.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
