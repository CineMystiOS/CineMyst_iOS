//
//  PeopleTagViewController.swift
//  CineMystApp
//
//  Tagging UI - Searchable user list
//

import UIKit

protocol PeopleTagDelegate: AnyObject {
    func didSelectUsers(_ users: [ProfileRecord])
}

class PeopleTagViewController: UIViewController {
    
    weak var delegate: PeopleTagDelegate?
    private var following: [ProfileRecord] = []
    private var searchResults: [ProfileRecord] = []
    private var selectedUsers: [ProfileRecord] = []
    
    private var isSearching: Bool {
        return searchBar.text?.isEmpty == false
    }
    
    // MARK: - UI Elements
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for a user..."
        sb.searchBarStyle = .minimal
        sb.backgroundColor = .systemBackground
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Init
    init(selectedUsers: [ProfileRecord]) {
        self.selectedUsers = selectedUsers
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchInitialData()
    }
    
    private func setupUI() {
        title = "Tag People"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func fetchInitialData() {
        loadingIndicator.startAnimating()
        Task {
            do {
                following = try await ConnectionService.shared.fetchFollowing()
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    @objc private func doneTapped() {
        delegate?.didSelectUsers(selectedUsers)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension PeopleTagViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : following.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = isSearching ? searchResults[indexPath.row] : following[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = user.username ?? user.fullName ?? "Unknown User"
        config.secondaryText = user.fullName
        
        // Placeholder image
        config.image = UIImage(systemName: "person.circle.fill")
        config.imageProperties.tintColor = .systemGray
        
        if let urlStr = user.profilePictureUrl ?? user.avatarUrl, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        var updatedConfig = cell.defaultContentConfiguration()
                        updatedConfig.text = user.username ?? user.fullName
                        updatedConfig.secondaryText = user.fullName
                        updatedConfig.image = img
                        updatedConfig.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                        updatedConfig.imageProperties.cornerRadius = 20
                        cell.contentConfiguration = updatedConfig
                    }
                }
            }.resume()
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = selectedUsers.contains(where: { $0.id == user.id }) ? .checkmark : .none
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = isSearching ? searchResults[indexPath.row] : following[indexPath.row]
        
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}

// MARK: - UISearchBarDelegate
extension PeopleTagViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        Task {
            do {
                searchResults = try await ConnectionService.shared.searchUsers(query: searchText)
                await MainActor.run {
                    self.tableView.reloadData()
                }
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
}
