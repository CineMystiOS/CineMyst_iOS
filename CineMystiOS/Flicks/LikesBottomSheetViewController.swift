//
//  LikesBottomSheetViewController.swift
//  CineMystApp
//
//  Display a list of users who liked the flick — dark cinematic aesthetic.
//

import UIKit

// MARK: - Likes Bottom Sheet

final class LikesBottomSheetViewController: UIViewController {

    // MARK: - Public
    var flickId: String?

    // MARK: - Design
    private enum DS {
        static let bg      = UIColor(red: 0.07, green: 0.04, blue: 0.06, alpha: 1)
        static let card    = UIColor(red: 0.13, green: 0.07, blue: 0.11, alpha: 1)
        static let plum    = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1)
        static let rose    = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
    }

    // MARK: - Data
    private var allUsers: [ProfileRecord] = []

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
        l.text = "Likes"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate   = self
        tv.dataSource = self
        tv.register(LikeContactCell.self, forCellReuseIdentifier: LikeContactCell.id)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .onDrag
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No likes yet"
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
        loadLikers()
    }

    // MARK: - Layout

    private func setupViews() {
        view.addSubview(grabber)
        view.addSubview(titleLabel)
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

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
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

    private func loadLikers() {
        spinner.startAnimating()
        emptyLabel.isHidden = true

        guard let flickId = flickId else { return }

        Task {
            do {
                let users = try await FlicksService.shared.fetchLikers(flickId: flickId)
                await MainActor.run {
                    self.allUsers = users
                    self.spinner.stopAnimating()
                    self.emptyLabel.isHidden = !users.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.emptyLabel.text = "Could not load likes"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
}

// MARK: - UITableView

extension LikesBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int {
        allUsers.count
    }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: LikeContactCell.id, for: ip) as! LikeContactCell
        let user = allUsers[ip.row]
        cell.configure(with: user)
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat { 70 }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        // Optionally navigate to user profile
        let user = allUsers[ip.row]
        guard let userId = UUID(uuidString: user.id) else { return }
        
        dismiss(animated: true) {
            // Find root navigation controller to push to
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootTab = window.rootViewController as? UITabBarController,
               let nav = rootTab.selectedViewController as? UINavigationController {
                
                let profileVC = ActorProfileViewController(userId: userId)
                profileVC.hidesBottomBarWhenPushed = true
                nav.pushViewController(profileVC, animated: true)
            }
        }
    }
}

// MARK: - LikeContactCell

final class LikeContactCell: UITableViewCell {
    static let id = "LikeContactCell"

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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .default
        
        let selectedBg = UIView()
        selectedBg.backgroundColor = UIColor(white: 1, alpha: 0.1)
        selectedBackgroundView = selectedBg

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: ProfileRecord) {
        nameLabel.text    = user.fullName ?? user.username ?? "User"
        usernameLabel.text = user.username.map { "@\($0)" } ?? ""
        avatarView.image  = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = UIColor(white: 0.4, alpha: 1)

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
    }
}
