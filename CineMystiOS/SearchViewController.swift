//
//  SearchViewController.swift
//  CineMystApp
//
//  LinkedIn-style user search and Instagram-style Explore Flicks
//

import UIKit
import Supabase

struct UserSearchResult {
    let id: String
    let username: String
    let fullName: String?
    let profilePictureUrl: String?
    let role: String?
}

// MARK: - Explore Flick Cell
class ExploreFlickCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let playIcon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        playIcon.image = UIImage(systemName: "play.fill")
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow to icon for visibility
        playIcon.layer.shadowColor = UIColor.black.cgColor
        playIcon.layer.shadowOffset = .zero
        playIcon.layer.shadowOpacity = 0.5
        playIcon.layer.shadowRadius = 2
        contentView.addSubview(playIcon)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            playIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            playIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            playIcon.widthAnchor.constraint(equalToConstant: 16),
            playIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configureShimmer() {
        imageView.image = nil
        imageView.backgroundColor = .systemGray5
        playIcon.isHidden = true
        
        UIView.animate(withDuration: 0.8, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            self.imageView.alpha = 0.5
        })
    }
    
    func configure(with flick: Flick) {
        imageView.layer.removeAllAnimations()
        imageView.alpha = 1.0
        imageView.backgroundColor = .systemGray6
        playIcon.isHidden = false
        
        if let urlString = flick.thumbnailUrl, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }.resume()
        } else {
            imageView.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.layer.removeAllAnimations()
        imageView.alpha = 1.0
        imageView.image = nil
        playIcon.isHidden = false
    }
}

// MARK: - Custom Search Result Cell
class SearchUserCell: UITableViewCell {
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let roleLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Username Label
        usernameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        usernameLabel.textColor = .systemGray
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(usernameLabel)
        
        // Role Label
        roleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        roleLabel.textColor = .systemGray2
        roleLabel.numberOfLines = 1
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roleLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            usernameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            roleLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            roleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            roleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with result: UserSearchResult) {
        nameLabel.text = result.fullName ?? result.username
        usernameLabel.text = "@\(result.username)"
        
        let roleText = result.role?.replacingOccurrences(of: "_", with: " ").capitalized ?? "User"
        roleLabel.text = roleText
        
        // Load profile image
        if let urlString = result.profilePictureUrl,
           let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
}

// MARK: - Main Search View Controller
final class SearchViewController: UIViewController {
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()
    
    private lazy var exploreCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.showsVerticalScrollIndicator = false
        cv.register(ExploreFlickCell.self, forCellWithReuseIdentifier: "ExploreFlickCell")
        return cv
    }()
    
    private var searchResults: [UserSearchResult] = []
    private var isSearching = false
    private var searchTask: Task<Void, Never>?
    
    private var exploreFlicks: [Flick] = []
    private var isLoadingFlicks = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Find People"
        navigationItem.backButtonTitle = ""
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = nil
        
        setupSearchController()
        setupExploreGrid()
        setupTableView()
        setupEmptyState()
        
        tableView.isHidden = true
        exploreCollectionView.isHidden = false
        emptyStateLabel.isHidden = true
        
        fetchExploreFlicks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.leftBarButtonItem = nil
        
        // Remove CineMyst logo from navigation bar
        if let navBar = navigationController?.navigationBar {
            if let contentView = navBar.subviews.first(where: {
                String(describing: type(of: $0)).contains("ContentView")
            }) {
                if let titleLabel = contentView.viewWithTag(999) {
                    titleLabel.removeFromSuperview()
                }
            }
        }
    }
    
    private func setupSearchController() {
        searchController.searchBar.placeholder = "Search by name or username"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupExploreGrid() {
        exploreCollectionView.translatesAutoresizingMaskIntoConstraints = false
        exploreCollectionView.delegate = self
        exploreCollectionView.dataSource = self
        view.addSubview(exploreCollectionView)
        
        NSLayoutConstraint.activate([
            exploreCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            exploreCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            exploreCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            exploreCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SearchUserCell.self, forCellReuseIdentifier: "SearchUserCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 66
        tableView.backgroundColor = .systemBackground
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyStateLabel.text = "No results found"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.font = .systemFont(ofSize: 16)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func fetchExploreFlicks() {
        guard !isLoadingFlicks else { return }
        isLoadingFlicks = true
        Task {
            do {
                let flicks = try await FlicksService.shared.fetchFlicks(limit: 30)
                await MainActor.run {
                    self.exploreFlicks = flicks
                    self.exploreCollectionView.reloadData()
                    self.isLoadingFlicks = false
                }
            } catch {
                print("❌ Error fetching explore flicks: \(error)")
                await MainActor.run { self.isLoadingFlicks = false }
            }
        }
    }
    
    private func searchUsers(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        isSearching = true
        emptyStateLabel.isHidden = true
        
        searchTask = Task {
            do {
                // Search in both username, fullName and role
                let response = try await supabase
                    .from("profiles")
                    .select()
                    .or("username.ilike.%\(query)%,full_name.ilike.%\(query)%")
                    .limit(20)
                    .execute()
                
                let decoder = JSONDecoder()
                let results = try decoder.decode([ProfileRecord].self, from: response.data)
                
                await MainActor.run {
                    self.searchResults = results.map { profile in
                        UserSearchResult(
                            id: profile.id,
                            username: profile.username ?? "Unknown",
                            fullName: profile.fullName,
                            profilePictureUrl: profile.profilePictureUrl,
                            role: profile.role
                        )
                    }
                    self.tableView.reloadData()
                    self.isSearching = false
                    self.emptyStateLabel.isHidden = !self.searchResults.isEmpty
                }
            } catch {
                print("❌ Error searching users: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.tableView.reloadData()
                    self.isSearching = false
                    self.emptyStateLabel.isHidden = false
                }
            }
        }
    }
}

extension SearchViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces),
              !text.isEmpty else {
            searchResults.removeAll()
            emptyStateLabel.isHidden = true
            tableView.isHidden = true
            exploreCollectionView.isHidden = false
            tableView.reloadData()
            return
        }
        
        emptyStateLabel.isHidden = true
        exploreCollectionView.isHidden = true
        tableView.isHidden = false
        searchUsers(query: text)
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserCell", for: indexPath) as? SearchUserCell else {
            return UITableViewCell()
        }
        
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < searchResults.count else { return }

        let result = searchResults[indexPath.row]

        // Navigate to the tapped user's profile using the designated init
        let profileVC = ActorProfileViewController(userId: UUID(uuidString: result.id))
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoadingFlicks && exploreFlicks.isEmpty {
            return 15 // Skeleton loading count
        }
        return exploreFlicks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreFlickCell", for: indexPath) as! ExploreFlickCell
        
        if isLoadingFlicks && exploreFlicks.isEmpty {
            cell.configureShimmer()
        } else {
            cell.configure(with: exploreFlicks[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 2 // 1pt between cal 1-2, 1pt between col 2-3
        let width = (collectionView.bounds.width - totalSpacing) / 3
        let height = width * 1.5 // vertical aspect ratio like reels
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Open the full screen viewer
        guard indexPath.item < exploreFlicks.count else { return }
        let reelVC = UserFlicksFeedViewController_FullScreen(flicks: exploreFlicks, startIndex: indexPath.item)
        reelVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(reelVC, animated: true)
    }
}
