//
//  SearchViewController.swift
//  CineMystApp
//
//  LinkedIn-style user search

import UIKit
import Supabase

struct UserSearchResult {
    let id: String
    let username: String
    let fullName: String?
    let profilePictureUrl: String?
    let role: String?
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
    
    private var searchResults: [UserSearchResult] = []
    private var isSearching = false
    private var searchTask: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Find People"
        
        setupSearchController()
        setupTableView()
        setupEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupSearchController() {
        searchController.searchBar.placeholder = "Search by name or username"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
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
        emptyStateLabel.text = "Search for people to connect"
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
                }
            } catch {
                print("❌ Error searching users: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.tableView.reloadData()
                    self.isSearching = false
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
            emptyStateLabel.isHidden = false
            tableView.reloadData()
            return
        }
        
        emptyStateLabel.isHidden = true
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
        
        // Navigate to other user's profile
        let profileVC = ProfileViewController()
        profileVC.viewingUserId = result.id // Pass the user ID
        navigationController?.pushViewController(profileVC, animated: true)
    }
}
