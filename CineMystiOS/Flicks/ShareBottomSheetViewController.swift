//
//  ShareBottomSheetViewController.swift
//  CineMystApp
//
//  Share a Flick with connected users via DM — dark cinematic aesthetic.
//

import UIKit

// MARK: - Share Bottom Sheet

final class ShareBottomSheetViewController: UIViewController {

    // MARK: - Public
    var flickId: String?
    var flickVideoURL: String?
    var flickCaption: String?
    var flickAuthorName: String?      // poster's display name
    var flickAuthorAvatarURL: String? // poster's avatar URL

    // MARK: - Design
    private enum DS {
        static let bg      = UIColor(red: 0.07, green: 0.04, blue: 0.06, alpha: 1)
        static let card    = UIColor(red: 0.13, green: 0.07, blue: 0.11, alpha: 1)
        static let plum    = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1)
        static let rose    = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
    }

    // MARK: - Data
    private var allUsers: [ProfileRecord] = []
    private var filteredUsers: [ProfileRecord] = []
    private var sentTo: Set<String> = []    // track who we already sent to this session

    // MARK: - UI

    private let grabber: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.2)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Share with"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search connections..."
        sb.searchBarStyle = .minimal
        sb.tintColor = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        sb.searchTextField.backgroundColor = UIColor(white: 1, alpha: 0.08)
        sb.searchTextField.textColor = .white
        sb.searchTextField.leftView?.tintColor = UIColor(white: 1, alpha: 0.4)
        sb.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search connections...",
            attributes: [.foregroundColor: UIColor(white: 1, alpha: 0.35)]
        )
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate   = self
        tv.dataSource = self
        tv.register(ShareContactCell.self, forCellReuseIdentifier: ShareContactCell.id)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .onDrag
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No connections yet\nConnect with people to share Flicks ✨"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(white: 1, alpha: 0.35)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let spinner: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.color = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        a.hidesWhenStopped = true
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.bg
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        setupViews()
        searchBar.delegate = self
        loadConnections()
    }

    // MARK: - Layout

    private func setupViews() {
        view.addSubview(grabber)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            spinner.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 40),
        ])
    }

    // MARK: - Data

    private func loadConnections() {
        spinner.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                // Fetch both sent+received accepted connections
                let users = try await fetchConnectedUsers()
                await MainActor.run {
                    self.allUsers = users
                    self.filteredUsers = users
                    self.spinner.stopAnimating()
                    self.emptyLabel.isHidden = !users.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.emptyLabel.text = "Could not load connections"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    /// Fetch all accepted connections in both directions and return their profiles
    private func fetchConnectedUsers() async throws -> [ProfileRecord] {
        guard let uid = try? await supabase.auth.session.user.id.uuidString else { return [] }

        var friendIds: [String] = []

        // Direction 1: I sent
        let sentRes = try await supabase
            .from("connections")
            .select("receiver_id")
            .eq("requester_id", value: uid)
            .eq("status", value: "accepted")
            .execute()
        if let rows = try? JSONSerialization.jsonObject(with: sentRes.data) as? [[String: Any]] {
            friendIds += rows.compactMap { $0["receiver_id"] as? String }
        }

        // Direction 2: They sent
        let recvRes = try await supabase
            .from("connections")
            .select("requester_id")
            .eq("receiver_id", value: uid)
            .eq("status", value: "accepted")
            .execute()
        if let rows = try? JSONSerialization.jsonObject(with: recvRes.data) as? [[String: Any]] {
            friendIds += rows.compactMap { $0["requester_id"] as? String }
        }

        guard !friendIds.isEmpty else { return [] }

        let profileRes = try await supabase
            .from("profiles")
            .select("*")
            .in("id", value: friendIds)
            .execute()

        return try JSONDecoder().decode([ProfileRecord].self, from: profileRes.data)
    }

    // MARK: - Send Flick

    private func sendFlick(to user: ProfileRecord) {
        guard let receiverUUID = UUID(uuidString: user.id) else { return }

        let videoURL  = flickVideoURL ?? ""
        let caption   = flickCaption.flatMap { $0.isEmpty ? nil : $0 } ?? ""
        var author    = flickAuthorName?.trimmingCharacters(in: .whitespaces) ?? ""
        if author.isEmpty { author = "CineMyst User" }
        let avatarURL = flickAuthorAvatarURL ?? ""

        // Structured format so the chat can render a rich card
        var parts = ["[FLICK]"]
        parts.append("author:\(author)")
        if !avatarURL.isEmpty { parts.append("avatar:\(avatarURL)") }
        if !caption.isEmpty   { parts.append("caption:\(caption)") }
        parts.append(videoURL)
        let message = parts.joined(separator: "\n")

        // Mark as sent immediately
        sentTo.insert(user.id)
        tableView.reloadData()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        Task {
            do {
                let conv = try await MessagesService.shared.getOrCreateConversation(withUserId: receiverUUID)
                _ = try await MessagesService.shared.sendMessage(conversationId: conv.id, content: message)
            } catch {
                await MainActor.run {
                    self.sentTo.remove(user.id)
                    self.tableView.reloadData()
                    print("❌ Failed to send flick: \(error)")
                }
            }
        }
    }
}

// MARK: - UITableView

extension ShareBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int {
        filteredUsers.count
    }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: ShareContactCell.id, for: ip) as! ShareContactCell
        let user = filteredUsers[ip.row]
        cell.configure(with: user, sent: sentTo.contains(user.id))
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat { 70 }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        let user = filteredUsers[ip.row]
        guard !sentTo.contains(user.id) else { return }
        sendFlick(to: user)
    }
}

// MARK: - UISearchBar Delegate

extension ShareBottomSheetViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty {
            filteredUsers = allUsers
            tableView.reloadData()
            return
        }
        let lower = text.lowercased()
        filteredUsers = allUsers.filter {
            ($0.username?.lowercased().contains(lower) ?? false) ||
            ($0.fullName?.lowercased().contains(lower) ?? false)
        }
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredUsers = allUsers
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
}

// MARK: - ShareContactCell

final class ShareContactCell: UITableViewCell {
    static let id = "ShareContactCell"

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 22
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = UIColor(white: 0.4, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(white: 1, alpha: 0.5)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Send", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        btn.layer.cornerRadius = 16
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 18, bottom: 6, right: 18)
        btn.isUserInteractionEnabled = false   // row tap handles it
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(sendButton)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -8),

            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: ProfileRecord, sent: Bool) {
        nameLabel.text    = user.fullName ?? user.username ?? "User"
        usernameLabel.text = user.username.map { "@\($0)" } ?? ""
        avatarView.image  = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = UIColor(white: 0.4, alpha: 1)

        // Sent state
        if sent {
            sendButton.setTitle("Sent ✓", for: .normal)
            sendButton.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 0.35, alpha: 0.7)
            sendButton.alpha = 0.8
        } else {
            sendButton.setTitle("Send", for: .normal)
            sendButton.backgroundColor = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
            sendButton.alpha = 1
        }

        // Load avatar
        if let urlStr = user.profilePictureUrl, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.avatarView.image = img }
            }.resume()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = UIImage(systemName: "person.circle.fill")
        sendButton.setTitle("Send", for: .normal)
        sendButton.backgroundColor = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        sendButton.alpha = 1
    }
}
