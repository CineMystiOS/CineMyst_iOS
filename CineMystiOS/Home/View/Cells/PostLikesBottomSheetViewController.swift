import UIKit

private enum PostLikesSheetDS {
    static let bg = UIColor(red: 0.986, green: 0.958, blue: 0.975, alpha: 1)
    static let card = UIColor.white.withAlphaComponent(0.72)
    static let plum = UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1)
    static let rose = UIColor(red: 0.854, green: 0.553, blue: 0.742, alpha: 1)
    static let ink = UIColor(red: 0.19, green: 0.13, blue: 0.16, alpha: 1)
}

final class PostLikesBottomSheetViewController: UIViewController {

    var postId: String?

    private var users: [ProfileRecord] = []

    private let grabber: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Likes"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = PostLikesSheetDS.plum
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(PostLikeUserCell.self, forCellReuseIdentifier: PostLikeUserCell.reuseId)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No likes yet"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = PostLikesSheetDS.plum.withAlphaComponent(0.45)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = PostLikesSheetDS.rose
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PostLikesSheetDS.bg
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        setupViews()
        loadLikers()
    }

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

    private func loadLikers() {
        spinner.startAnimating()
        emptyLabel.isHidden = true

        guard let postId else { return }

        Task {
            do {
                let users = try await PostManager.shared.fetchPostLikers(postId: postId)
                await MainActor.run {
                    self.users = users.sorted {
                        ($0.fullName ?? $0.username ?? "").localizedCaseInsensitiveCompare($1.fullName ?? $1.username ?? "") == .orderedAscending
                    }
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

extension PostLikesBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostLikeUserCell.reuseId, for: indexPath) as! PostLikeUserCell
        cell.configure(with: users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = users[indexPath.row]
        guard let userId = UUID(uuidString: user.id) else { return }

        dismiss(animated: true) {
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

final class PostLikeUserCell: UITableViewCell {
    static let reuseId = "PostLikeUserCell"

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor = PostLikesSheetDS.card
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 22
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = PostLikesSheetDS.rose.withAlphaComponent(0.18)
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = PostLikesSheetDS.plum.withAlphaComponent(0.55)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = PostLikesSheetDS.ink
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = PostLikesSheetDS.plum.withAlphaComponent(0.55)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card)
        card.addSubview(avatarView)
        card.addSubview(nameLabel)
        card.addSubview(usernameLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            avatarView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            usernameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: ProfileRecord) {
        nameLabel.text = user.fullName ?? user.username ?? "User"
        usernameLabel.text = user.username.map { "@\($0)" } ?? ""
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = PostLikesSheetDS.plum.withAlphaComponent(0.55)

        let imageURL = user.profilePictureUrl ?? user.avatarUrl
        if let imageURL, let url = URL(string: imageURL), !imageURL.isEmpty {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.avatarView.image = image
                }
            }.resume()
        }
    }
}
