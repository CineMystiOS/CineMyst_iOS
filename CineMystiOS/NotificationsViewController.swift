import UIKit

// MARK: - DB Model
struct NotificationRow: Codable {
    let id: String
    let recipient_id: String
    let sender_id: String?
    let type: String
    let title: String
    let message: String?
    let is_read: Bool?
    let created_at: String?
}

// MARK: - UI Model
struct NotificationItem {
    let id: String
    let senderId: String?
    let imageName: String?
    let title: String
    let message: String
    let timeAgo: String
    let type: String            // "connection_request" | "general" …
    let isSystemIcon: Bool
    var actionState: String     // "pending" | "accepted" | "declined" | "none"
}

// MARK: - NotificationsViewController
final class NotificationsViewController: UIViewController {

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel = UILabel()

    private var notifications: [NotificationItem] = []
    private var filtered: [NotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemBackground
        setupSearchController()
        setupTableView()
        setupEmptyLabel()
        setupLoadingIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNotifications()
        // Remove CineMyst logo
        if let navBar = navigationController?.navigationBar {
            if let contentView = navBar.subviews.first(where: {
                String(describing: type(of: $0)).contains("ContentView")
            }) {
                contentView.viewWithTag(999)?.removeFromSuperview()
            }
        }
    }

    // MARK: - Setup
    private func setupSearchController() {
        searchController.searchBar.placeholder = "Search notifications"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.text = "No notifications yet"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Fetch
    private func fetchNotifications() {
        loadingIndicator.startAnimating()
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let meId = session.user.id.uuidString

                let rows: [NotificationRow] = try await supabase
                    .from("notifications")
                    .select()
                    .eq("recipient_id", value: meId)
                    .order("created_at", ascending: false)
                    .limit(50)
                    .execute()
                    .value

                // For each connection_request, fetch current connection status
                var items: [NotificationItem] = []
                for row in rows {
                    var actionState = "none"
                    if row.type == "connection_request", let senderId = row.sender_id {
                        actionState = await fetchConnectionState(senderId: senderId, receiverId: meId)
                    }
                    items.append(NotificationItem(
                        id: row.id,
                        senderId: row.sender_id,
                        imageName: row.type == "connection_request" ? "person.circle.fill" : "bell.fill",
                        title: row.title,
                        message: row.message ?? "",
                        timeAgo: timeAgoString(from: row.created_at),
                        type: row.type,
                        isSystemIcon: true,
                        actionState: actionState
                    ))
                }

                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.notifications = items
                    self.filtered = items
                    self.emptyLabel.isHidden = !items.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    print("❌ Failed to load notifications: \(error)")
                }
            }
        }
    }

    private func fetchConnectionState(senderId: String, receiverId: String) async -> String {
        do {
            struct ConnRow: Codable { let status: String }
            let rows: [ConnRow] = try await supabase
                .from("connections")
                .select("status")
                .or("and(requester_id.eq.\(senderId),receiver_id.eq.\(receiverId)),and(requester_id.eq.\(receiverId),receiver_id.eq.\(senderId))")
                .limit(1)
                .execute()
                .value
            if let row = rows.first {
                return row.status == "accepted" ? "accepted" : "pending"
            }
            return "none"
        } catch {
            return "none"
        }
    }

    // MARK: - Accept / Decline
    private func acceptRequest(at indexPath: IndexPath) {
        guard let senderId = filtered[indexPath.row].senderId else { return }
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let meId = session.user.id.uuidString

                print("🔄 Accepting connection from sender=\(senderId) me=\(meId)")

                struct StatusUpdate: Encodable { let status: String }
                let result = try await supabase
                    .from("connections")
                    .update(StatusUpdate(status: "accepted"))
                    .or("and(requester_id.eq.\(senderId),receiver_id.eq.\(meId)),and(requester_id.eq.\(meId),receiver_id.eq.\(senderId))")
                    .execute()

                let responseStr = String(data: result.data, encoding: .utf8) ?? "nil"
                print("✅ Accept response: \(responseStr)")

                // Supabase returns "[]" when RLS blocks the update silently
                let trimmed = responseStr.trimmingCharacters(in: .whitespaces)
                if trimmed == "[]" || trimmed == "null" || trimmed.isEmpty {
                    await MainActor.run {
                        self.showError("⚠️ Connection update blocked.\n\nPlease add Row Level Security policy in Supabase:\nEnable UPDATE for authenticated users where receiver_id = auth.uid()")
                    }
                    return
                }

                await MainActor.run {
                    self.filtered[indexPath.row].actionState = "accepted"
                    if let i = self.notifications.firstIndex(where: { $0.id == self.filtered[indexPath.row].id }) {
                        self.notifications[i].actionState = "accepted"
                    }
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            } catch {
                print("❌ Accept error: \(error)")
                await MainActor.run { self.showError(error.localizedDescription) }
            }
        }
    }

    private func declineRequest(at indexPath: IndexPath) {
        guard let senderId = filtered[indexPath.row].senderId else { return }
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let meId = session.user.id.uuidString

                // Delete the connection row
                try await supabase
                    .from("connections")
                    .delete()
                    .eq("requester_id", value: senderId)
                    .eq("receiver_id", value: meId)
                    .execute()

                await MainActor.run {
                    self.filtered[indexPath.row].actionState = "declined"
                    if let i = self.notifications.firstIndex(where: { $0.id == self.filtered[indexPath.row].id }) {
                        self.notifications[i].actionState = "declined"
                    }
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            } catch {
                await MainActor.run { self.showError(error.localizedDescription) }
            }
        }
    }

    private func showError(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Helpers
    private func timeAgoString(from iso: String?) -> String {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:          return "just now"
        case ..<3600:        return "\(Int(diff/60))m ago"
        case ..<86400:       return "\(Int(diff/3600))h ago"
        case ..<604800:      return "\(Int(diff/86400))d ago"
        default:             return "\(Int(diff/604800))w ago"
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let item = filtered[indexPath.row]
        cell.configure(with: item)

        // Wire Accept / Decline closures
        cell.onAccept = { [weak self] in self?.acceptRequest(at: indexPath) }
        cell.onDecline = { [weak self] in self?.declineRequest(at: indexPath) }

        return cell
    }
}

// MARK: - Search
extension NotificationsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let q = searchController.searchBar.text, !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            filtered = notifications
            tableView.reloadData()
            return
        }
        let lower = q.lowercased()
        filtered = notifications.filter {
            $0.title.lowercased().contains(lower) || $0.message.lowercased().contains(lower)
        }
        tableView.reloadData()
    }
}
