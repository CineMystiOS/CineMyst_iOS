//
//  ConnectionsListViewController.swift
//  CineMystApp
//
//  Shows list of all connections for a user

import UIKit

final class ConnectionsListViewController: UIViewController {
    
    var userId: String?
    private var connections: [ConnectedUser] = []
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Connections"
        
        setupTableView()
        setupEmptyState()
        setupLoadingIndicator()
        
        fetchConnections()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ConnectionCell.self, forCellReuseIdentifier: "ConnectionCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyLabel.text = "No connections yet"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .systemGray
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        emptyLabel.isHidden = true
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func fetchConnections() {
        guard let userId = userId else { return }
        
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let connections = try await ConnectionManager.shared.fetchUserConnections(userId: userId)
                
                await MainActor.run {
                    self.connections = connections
                    self.loadingIndicator.stopAnimating()
                    
                    if connections.isEmpty {
                        self.emptyLabel.isHidden = false
                    } else {
                        self.emptyLabel.isHidden = true
                        self.tableView.reloadData()
                    }
                }
            } catch {
                print("❌ Error fetching connections: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.emptyLabel.text = "Failed to load connections"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
}

extension ConnectionsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectionCell", for: indexPath) as? ConnectionCell else {
            return UITableViewCell()
        }
        
        let user = connections[indexPath.row]
        cell.configure(with: user)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = connections[indexPath.row]
        
        let profileVC = ProfileViewController()
        profileVC.viewingUserId = user.id
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - Connection Cell
class ConnectionCell: UITableViewCell {
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
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
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        roleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        roleLabel.textColor = .systemGray
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            roleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            roleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with user: ConnectedUser) {
        nameLabel.text = user.fullName ?? user.username
        roleLabel.text = (user.role?.replacingOccurrences(of: "_", with: " ").capitalized) ?? "User"
        
        if let urlString = user.profilePictureUrl,
           let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray
        }
    }
}
