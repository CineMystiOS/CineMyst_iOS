//
//  ShareBottomSheetController.swift
//  CineMystApp
//

import UIKit

final class ShareBottomSheetController: UIViewController {
    private let post: Post

    private var allUsers: [ShareUser] = []
    private var filteredUsers: [ShareUser] = []
    private var isLoading = false

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Share To Connections"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search connections"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.rowHeight = 72
        tv.register(ShareUserCell.self, forCellReuseIdentifier: "ShareUserCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No connections found"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        searchBar.delegate = self
        setupUI()
        loadConnections()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadConnections() {
        isLoading = true
        loadingIndicator.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                guard let currentUserId = try await AuthManager.shared.currentSession()?.user.id.uuidString else {
                    throw NSError(domain: "ShareBottomSheetController", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }

                let connections = try await ConnectionManager.shared.fetchUserConnections(userId: currentUserId)
                let users = connections.map {
                    ShareUser(
                        id: $0.id,
                        name: $0.fullName ?? $0.username,
                        username: "@\($0.username)",
                        avatarUrl: $0.profilePictureUrl
                    )
                }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.allUsers = users
                    self.filteredUsers = users
                    self.emptyLabel.isHidden = !users.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.allUsers = []
                    self.filteredUsers = []
                    self.emptyLabel.text = "Failed to load connections"
                    self.emptyLabel.isHidden = false
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func applySearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filteredUsers = allUsers
        } else {
            filteredUsers = allUsers.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.username.localizedCaseInsensitiveContains(trimmed)
            }
        }
        emptyLabel.text = filteredUsers.isEmpty ? "No matching connections" : "No connections found"
        emptyLabel.isHidden = !filteredUsers.isEmpty || isLoading
        tableView.reloadData()
    }

    private func sendPost(to user: ShareUser) {
        guard let recipientId = UUID(uuidString: user.id) else { return }

        let sendingAlert = UIAlertController(title: nil, message: "Sending...", preferredStyle: .alert)
        present(sendingAlert, animated: true)

        Task {
            do {
                let conversation = try await MessagesService.shared.getOrCreateConversation(withUserId: recipientId)
                let shareText = buildShareText()
                _ = try await MessagesService.shared.sendMessage(conversationId: conversation.id, content: shareText)

                await MainActor.run {
                    sendingAlert.dismiss(animated: true) {
                        let successAlert = UIAlertController(
                            title: "Sent",
                            message: "Post shared with \(user.name)",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismiss(animated: true)
                        })
                        self.present(successAlert, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    sendingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(
                            title: "Share Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }

    private func buildShareText() -> String {
        let name = post.displayName
        let avatarURL = post.userProfilePictureUrl ?? ""
        let caption = post.caption?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let firstMediaURL = post.mediaUrls.first?.url ?? ""

        var parts = ["[POST]"]
        parts.append("author:\(name)")
        if !avatarURL.isEmpty { parts.append("avatar:\(avatarURL)") }
        if !caption.isEmpty   { parts.append("caption:\(caption)") }
        if !firstMediaURL.isEmpty { parts.append(firstMediaURL) }
        
        return parts.joined(separator: "\n")
    }
}

extension ShareBottomSheetController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShareUserCell", for: indexPath) as! ShareUserCell
        let user = filteredUsers[indexPath.row]
        cell.configure(with: user)
        cell.onSendTapped = { [weak self] in
            self?.sendPost(to: user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sendPost(to: filteredUsers[indexPath.row])
    }
}

extension ShareBottomSheetController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearch(query: searchText)
    }
}
