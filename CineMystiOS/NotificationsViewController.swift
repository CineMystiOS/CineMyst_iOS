import UIKit

struct NotificationItem {
    let imageName: String?   // systemName or asset name
    let title: String
    let message: String
    let timeAgo: String
    let showConnectButton: Bool
    let isSystemIcon: Bool
}

final class NotificationsViewController: UIViewController {

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var notifications: [NotificationItem] = []
    private var filteredNotifications: [NotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemBackground
        setupSearchController()
        setupTableView()
        loadDummyNotifications()
    }

    private func setupSearchController() {
        searchController.searchBar.placeholder = "Search"
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

        // Let table auto-size cells
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96

        // remove extra separators
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadDummyNotifications() {
        notifications = [
            NotificationItem(imageName: "megaphone.fill",
                             title: "KGF Casting",
                             message: "You have a new job posting.",
                             timeAgo: "1 day ago",
                             showConnectButton: false,
                             isSystemIcon: true),

            NotificationItem(imageName: "checkmark.seal.fill",
                             title: "YRF Casting",
                             message: "Thanks for your application! We’ll be in touch with you shortly.",
                             timeAgo: "13 days ago",
                             showConnectButton: false,
                             isSystemIcon: true),

            NotificationItem(imageName: "avatar_adrea",
                             title: "Adrea Marsi",
                             message: "Your mentoring session has been rescheduled. Kindly check your mail.",
                             timeAgo: "15 days ago",
                             showConnectButton: false,
                             isSystemIcon: false),

            NotificationItem(imageName: "avatar_potter",
                             title: "mis_potter started following you.",
                             message: "mis_potter started following you. You can connect with them to start exchanging messages.",
                             timeAgo: "3d",
                             showConnectButton: true,
                             isSystemIcon: false)
        ]

        filteredNotifications = notifications
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       filteredNotifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let item = filteredNotifications[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - Search
extension NotificationsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let q = searchController.searchBar.text, !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            filteredNotifications = notifications
            tableView.reloadData()
            return
        }
        let lower = q.lowercased()
        filteredNotifications = notifications.filter {
            $0.title.lowercased().contains(lower) || $0.message.lowercased().contains(lower)
        }
        tableView.reloadData()
    }
}
