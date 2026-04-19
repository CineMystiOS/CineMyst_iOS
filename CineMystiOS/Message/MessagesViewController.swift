//
//  MessagesViewController.swift
//

import UIKit
import Supabase
import AVFoundation

private extension UITextField {
    func applyCineMystSearchStyle(placeholderText: String) {
        backgroundColor = UIColor.white.withAlphaComponent(0.82)
        textColor = CineMystTheme.ink
        tintColor = CineMystTheme.brandPlum
        layer.cornerRadius = 18
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [.foregroundColor: CineMystTheme.ink.withAlphaComponent(0.38)]
        )
        if let iconView = leftView as? UIImageView {
            iconView.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.5)
        }
    }
}

// MARK: - View Models

/// UI representation of a conversation
struct ConversationViewModel {
    let id: UUID
    let name: String
    let preview: String
    let timeText: String
    let avatarUrl: String?
    var avatar: UIImage?
    let unreadCount: Int
}

// MARK: - Cells

final class ConversationCell: UITableViewCell {
    static let reuseID = "ConversationCell"

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let previewLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .right
        return l
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = UIColor.systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let unreadBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .white
        l.backgroundColor = .systemRed
        l.textAlignment = .center
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()


    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(previewLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(chevron)
        contentView.addSubview(unreadBadgeLabel)
        contentView.addSubview(separator)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),

            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -46),
            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            unreadBadgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadBadgeLabel.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),
            unreadBadgeLabel.heightAnchor.constraint(equalToConstant: 20),
            unreadBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),

            separator.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    // MARK: Configure

    func configure(with model: ConversationViewModel) {
        nameLabel.text = model.name
        previewLabel.text = model.preview
        timeLabel.text = model.timeText
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        layer.cornerRadius = 22
        layer.masksToBounds = true
        let isUnread = model.unreadCount > 0
        nameLabel.textColor = CineMystTheme.ink
        nameLabel.font = .systemFont(ofSize: 16, weight: isUnread ? .bold : .semibold)
        previewLabel.textColor = isUnread
            ? CineMystTheme.ink.withAlphaComponent(0.92)
            : CineMystTheme.brandPlum.withAlphaComponent(0.70)
        previewLabel.font = .systemFont(ofSize: 14, weight: isUnread ? .semibold : .regular)
        timeLabel.textColor = isUnread
            ? CineMystTheme.brandPlum
            : CineMystTheme.brandPlum.withAlphaComponent(0.52)
        timeLabel.font = .systemFont(ofSize: 13, weight: isUnread ? .semibold : .regular)
        chevron.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.55)
        separator.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)

        if isUnread {
            unreadBadgeLabel.isHidden = false
            unreadBadgeLabel.text = " \(model.unreadCount) "
            chevron.isHidden = true
        } else {
            unreadBadgeLabel.isHidden = true
            chevron.isHidden = false
        }
        
        // Load avatar from URL or use placeholder
        if let urlString = model.avatarUrl, let url = URL(string: urlString) {
            loadImage(from: url)
        } else if let img = model.avatar {
            avatarImageView.image = img
        } else {
            avatarImageView.image = UIImage(named: "avatar_placeholder")
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }.resume()
    }
}

// MARK: - Stories Cell (Collection View cell)

final class StoryCell: UICollectionViewCell {
    static let reuseID = "StoryCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 34
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = UIColor(white: 0.93, alpha: 1)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 68),
            imageView.heightAnchor.constraint(equalToConstant: 68),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(image: UIImage?, title: String) {
        imageView.image = image
        titleLabel.text = title
    }
}

// MARK: - Messages View Controller

final class MessagesViewController: UIViewController {

    // Placeholder avatar: uses uploaded image path (replace with asset if you prefer)
    private let placeholderAvatar = UIImage(named: "avatar_placeholder") ?? UIImage(named: "Image")

    // Data from backend
    private var conversations: [ConversationViewModel] = []
    private var stories: [(image: UIImage?, title: String)] = []
    
    // Loading state
    private var isLoading = false
    private var conversationsSubscription: MessagesRealtimeSubscription?

    // UI
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowTop = UIView()
    private let ambientGlowBottom = UIView()

    private let navLeftButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = CineMystTheme.ink.withAlphaComponent(0.82)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let navRightStack: UIStackView = {
        let compose = UIButton(type: .system)
        compose.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        compose.tintColor = CineMystTheme.brandPlum
        compose.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        compose.layer.cornerRadius = 18
        compose.translatesAutoresizingMaskIntoConstraints = false
        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        more.tintColor = CineMystTheme.brandPlum
        more.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        more.layer.cornerRadius = 18
        more.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [more, compose])
        stack.spacing = 12
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let searchField: UISearchBar = {
        let sb = UISearchBar()
        sb.searchBarStyle = .minimal
        sb.placeholder = "Search"
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.layer.cornerRadius = 10
        sb.clipsToBounds = true
        return sb
    }()

    // Stories collection removed - keeping code commented for reference
    /*
    private lazy var storiesCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 84, height: 96)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(StoryCell.self, forCellWithReuseIdentifier: StoryCell.reuseID)
        return cv
    }()
    */

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseID)
        tv.separatorStyle = .none
        tv.tableFooterView = UIView()
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No conversations yet\nStart chatting with someone!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        configureBackground()
        configureNavigationBar()
        setupDummyStories()
        configureSubviews()
        configureConstraints()
        configureActions()
        // storiesCollection.dataSource = self
        // storiesCollection.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        // Load conversations from backend
        loadConversations()
        startRealtimeConversationUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowTop.frame = CGRect(x: view.bounds.width - 160, y: 24, width: 150, height: 150)
        ambientGlowTop.layer.cornerRadius = 75
        ambientGlowBottom.frame = CGRect(x: -30, y: view.bounds.height - 220, width: 170, height: 170)
        ambientGlowBottom.layer.cornerRadius = 85
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ensure default navigation state: hide the standard back button if this VC is root
        navigationItem.hidesBackButton = true
        
        // Refresh conversations when view appears
        loadConversations()
    }

    deinit {
        conversationsSubscription?.cancel()
    }

    // MARK: Setup
    
    private func setupDummyStories() {
        // For now, keep stories as static data
        // In a real app, you might want to load these from a backend as well
        stories = [
            (image: placeholderAvatar, title: "Kenny..."),
            (image: placeholderAvatar, title: "Peter Herber..."),
            (image: placeholderAvatar, title: "Cooking!"),
            (image: placeholderAvatar, title: "Design"),
            (image: placeholderAvatar, title: "Friends")
        ]
    }

    private func configureBackground() {
        backgroundGradient.colors = [
            CineMystTheme.plumMist.cgColor,
            UIColor.white.cgColor,
            CineMystTheme.pinkPale.cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)

        ambientGlowTop.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        ambientGlowBottom.backgroundColor = CineMystTheme.deepPlumMid.withAlphaComponent(0.06)
        ambientGlowTop.isUserInteractionEnabled = false
        ambientGlowBottom.isUserInteractionEnabled = false
        view.addSubview(ambientGlowTop)
        view.addSubview(ambientGlowBottom)
    }

    private func setupDummyData() {
        // sample stories
        stories = [
            (image: placeholderAvatar, title: "Kenny..."),
            (image: placeholderAvatar, title: "Peter Herber..."),
            (image: placeholderAvatar, title: "Cooking!"),
            (image: placeholderAvatar, title: "Design"),
            (image: placeholderAvatar, title: "Friends")
        ]

        // sample conversations (for fallback/testing only - normally loaded from backend)
        conversations = [
            ConversationViewModel(id: UUID(), name: "Kristen", preview: "Hello aisha yo..", timeText: "9:41 AM", avatarUrl: nil, avatar: placeholderAvatar, unreadCount: 0),
            ConversationViewModel(id: UUID(), name: "Contact Name", preview: "Message preview...", timeText: "9:41 AM", avatarUrl: nil, avatar: placeholderAvatar, unreadCount: 0),
            ConversationViewModel(id: UUID(), name: "Contact Name", preview: "Message preview...", timeText: "9:41 AM", avatarUrl: nil, avatar: placeholderAvatar, unreadCount: 0),
        ]
    }

    private func configureNavigationBar() {
        navigationItem.title = "Messages"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = CineMystTheme.ink

        if shouldShowBackButton() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navLeftButton)
        } else {
            navigationItem.leftBarButtonItem = nil
        }

        let arranged = navRightStack.arrangedSubviews.compactMap { $0 as? UIButton }
        if arranged.count == 2 {
            let moreItem = UIBarButtonItem(customView: arranged[0])
            let composeItem = UIBarButtonItem(customView: arranged[1])
            navigationItem.rightBarButtonItems = [composeItem, moreItem]
        }
    }

    private func configureSubviews() {
        // Search
        view.addSubview(searchField)
        searchField.searchTextField.applyCineMystSearchStyle(placeholderText: "Search")

        // Table
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        
        // Loading indicator and empty state
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateLabel)
    }

    private func configureConstraints() {
        let safe = view.safeAreaLayoutGuide
        let constraints: [NSLayoutConstraint] = [
            // Search bar
            searchField.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12),
            searchField.heightAnchor.constraint(equalToConstant: 44),

            // Table view (directly below search field)
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            // Empty state
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -40)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func configureActions() {
        // Only wire the back action if the button was added
        if shouldShowBackButton() {
            navLeftButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        }

        if let more = navRightStack.arrangedSubviews.first as? UIButton {
            more.addTarget(self, action: #selector(didTapMore), for: .touchUpInside)
        }
        if navRightStack.arrangedSubviews.count > 1, let compose = navRightStack.arrangedSubviews[1] as? UIButton {
            compose.addTarget(self, action: #selector(didTapCompose), for: .touchUpInside)
        }
    }

    // determine if we should show the left/back button:
    // show it only when this VC is not the root of a navigation controller
    private func shouldShowBackButton() -> Bool {
        guard let nav = navigationController else { return false }
        return nav.viewControllers.first != self
    }

    // MARK: Actions

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapMore() {
        let a = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        a.addAction(.init(title: "Cancel", style: .cancel))
        present(a, animated: true)
    }

    @objc private func didTapCompose() {
        // Show user search interface
        let userSearchVC = UserSearchViewController()
        userSearchVC.onUserSelected = { [weak self] userId, userName in
            self?.createConversationAndOpenChat(withUserId: userId, userName: userName)
        }
        let nav = UINavigationController(rootViewController: userSearchVC)
        present(nav, animated: true)
    }
    
    private func createConversationAndOpenChat(withUserId userId: UUID, userName: String) {
        Task {
            do {
                // Create or get existing conversation
                let conversation = try await MessagesService.shared.getOrCreateConversation(withUserId: userId)
                
                await MainActor.run {
                    // Refresh conversations list
                    self.loadConversations()
                    
                    // Open chat view
                    let chatVC = ChatViewController()
                    chatVC.conversationId = conversation.id
                    chatVC.otherUserName = userName
                    chatVC.title = userName
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert(message: "Failed to create conversation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Backend Integration
    
    /// Load conversations from backend
    private func loadConversations() {
        guard !isLoading else { return }
        
        isLoading = true
        loadingIndicator.startAnimating()
        emptyStateLabel.isHidden = true
        
        Task {
            do {
                let conversationsData = try await MessagesService.shared.fetchConversations()
                
                // Convert to view models
                let viewModels = conversationsData.map { item -> ConversationViewModel in
                    let conv = item.conversation
                    let user = item.otherUser
                    
                    // Format time
                    let timeText = formatMessageTime(conv.lastMessageTime)
                    
                    // Get display name
                    let displayName = user.fullName ?? user.username ?? "User \(user.id.uuidString.prefix(8))"
                    
                    // Get preview text
                    let preview = conv.lastMessageContent ?? "No messages yet"
                    
                    return ConversationViewModel(
                        id: conv.id,
                        name: displayName,
                        preview: preview,
                        timeText: timeText,
                        avatarUrl: user.avatarUrl,
                        avatar: nil,
                        unreadCount: conv.unreadCount
                    )
                }
                
                await MainActor.run {
                    self.conversations = viewModels
                    self.tableView.reloadData()
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    
                    // Show empty state if no conversations
                    self.emptyStateLabel.isHidden = !viewModels.isEmpty
                    
                    print("✅ Loaded \(viewModels.count) conversations")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    
                    // If there's an error and no conversations, show empty state
                    if self.conversations.isEmpty {
                        self.emptyStateLabel.text = "Unable to load conversations\nPull to refresh"
                        self.emptyStateLabel.isHidden = false
                    }
                    
                    print("❌ Failed to load conversations: \(error.localizedDescription)")
                    
                    // Show error alert only if it's not an auth error
                    if (error as NSError).code != 401 {
                        self.showErrorAlert(message: "Failed to load conversations: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func startRealtimeConversationUpdates() {
        conversationsSubscription?.cancel()
        conversationsSubscription = MessagesService.shared.subscribeToConversationChanges { [weak self] in
            self?.loadConversations()
        }
    }
    
    /// Format message time for display
    private func formatMessageTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            // Today: show time
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            // Within a week: show day of week
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            // Older: show date
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    /// Show error alert
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource / Delegate

extension MessagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoryCell.reuseID, for: indexPath) as? StoryCell else {
            return UICollectionViewCell()
        }
        let item = stories[indexPath.item]
        cell.configure(image: item.image, title: item.title)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UITableView DataSource / Delegate

extension MessagesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { conversations.count }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 76 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseID, for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        cell.configure(with: conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conv = conversations[indexPath.row]
        
        // Create a chat detail view controller
        let chatVC = ChatViewController()
        chatVC.conversationId = conv.id
        chatVC.otherUserName = conv.name
        chatVC.title = conv.name
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - Chat Detail View Controller (Placeholder)

/// A simple chat detail view that will show messages for a conversation
// MARK: - Chat Message Cell

final class ChatMessageCell: UITableViewCell {
    static let reuseID = "ChatMessageCell"
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    func configure(with message: Message, isFromCurrentUser: Bool) {
        messageLabel.text = message.content
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.createdAt)
        
        if isFromCurrentUser {
            bubbleView.backgroundColor = CineMystTheme.brandPlum
            bubbleView.layer.borderWidth = 0
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            timeLabel.textAlignment = .right
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        } else {
            bubbleView.backgroundColor = UIColor.white.withAlphaComponent(0.84)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
            messageLabel.textColor = CineMystTheme.ink
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            timeLabel.textAlignment = .left
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        }
    }
}

// MARK: - Chat View Controller

final class ChatViewController: UIViewController {
    var conversationId: UUID?
    var otherUserName: String?
    
    private let backgroundGradient = CAGradientLayer()
    private let tableView = UITableView()
    private var messages: [Message] = []
    private let messageInputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var currentUserId: UUID?
    private var messagesSubscription: MessagesRealtimeSubscription?
    private var liveRefreshTask: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        title = otherUserName ?? "Chat"
        currentUserId = supabase.auth.currentUser?.id
        configureBackground()
        setupUI()
        loadMessages()
        startRealtimeMessages()
        startLiveRefreshLoop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    deinit {
        messagesSubscription?.cancel()
        liveRefreshTask?.cancel()
    }
    
    private func setupUI() {
        // Table view for messages
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self,      forCellReuseIdentifier: ChatMessageCell.reuseID)
        tableView.register(ChatFlickPreviewCell.self,  forCellReuseIdentifier: ChatFlickPreviewCell.reuseID)
        tableView.register(ChatImagePreviewCell.self,  forCellReuseIdentifier: ChatImagePreviewCell.reuseID)
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)
        
        // Input container
        let inputContainer = UIView()
        inputContainer.backgroundColor = UIColor.white.withAlphaComponent(0.80)
        inputContainer.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.cornerRadius = 22
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        // Message input field
        messageInputField.placeholder = "Type a message..."
        messageInputField.borderStyle = .none
        messageInputField.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.90)
        messageInputField.layer.cornerRadius = 20
        messageInputField.layer.masksToBounds = true
        messageInputField.font = .systemFont(ofSize: 16)
        messageInputField.textColor = CineMystTheme.ink
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        messageInputField.leftView = paddingView
        messageInputField.leftViewMode = .always
        
        inputContainer.addSubview(messageInputField)
        
        // Send button
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        sendButton.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputContainer.addSubview(sendButton)
        
        // Constraints
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),
            inputContainer.heightAnchor.constraint(equalToConstant: 64),
            
            messageInputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            messageInputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageInputField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])
    }

    private func configureBackground() {
        backgroundGradient.colors = [
            CineMystTheme.plumMist.cgColor,
            UIColor.white.cgColor,
            CineMystTheme.pinkPale.cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    private func loadMessages() {
        guard let conversationId = conversationId else { return }
        
        Task {
            do {
                let fetchedMessages = try await MessagesService.shared.fetchMessages(conversationId: conversationId)
                await MainActor.run {
                    self.replaceMessagesIfNeeded(fetchedMessages, animated: false)
                }
                try? await MessagesService.shared.markMessagesAsRead(conversationId: conversationId)
            } catch {
                print("❌ Failed to load messages: \(error)")
            }
        }
    }

    private func startLiveRefreshLoop() {
        guard let conversationId = conversationId else { return }
        liveRefreshTask?.cancel()
        liveRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let fetchedMessages = try await MessagesService.shared.fetchMessages(conversationId: conversationId)
                    await MainActor.run {
                        self?.replaceMessagesIfNeeded(fetchedMessages, animated: true)
                    }
                    try? await MessagesService.shared.markMessagesAsRead(conversationId: conversationId)
                } catch {
                    print("❌ Live refresh failed: \(error)")
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func startRealtimeMessages() {
        guard let conversationId = conversationId else { return }
        messagesSubscription?.cancel()
        messagesSubscription = MessagesService.shared.subscribeToMessages(conversationId: conversationId) { [weak self] message in
            self?.appendIncomingMessage(message)
        }
    }

    @MainActor
    private func appendIncomingMessage(_ message: Message) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
        tableView.reloadData()
        scrollToBottom(animated: true)

        if message.senderId != currentUserId, let conversationId {
            Task {
                try? await MessagesService.shared.markMessagesAsRead(conversationId: conversationId)
            }
        }
    }

    @MainActor
    private func replaceMessagesIfNeeded(_ fetchedMessages: [Message], animated: Bool) {
        let currentIds = messages.map(\.id)
        let fetchedIds = fetchedMessages.map(\.id)
        guard currentIds != fetchedIds || messages.count != fetchedMessages.count else { return }

        messages = fetchedMessages
        tableView.reloadData()
        scrollToBottom(animated: animated)
    }
    
    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    @objc private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty,
              let conversationId = conversationId else { return }
        
        messageInputField.text = ""
        
        Task {
            do {
                let sentMessage = try await MessagesService.shared.sendMessage(
                    conversationId: conversationId,
                    content: text
                )
                await MainActor.run {
                    self.appendIncomingMessage(sentMessage)
                }
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Media Message Parser

struct MediaMessageParser {
    struct FlickInfo {
        let author: String
        let avatarURL: String?
        let caption: String?
        let videoURL: String
    }
    struct ImageInfo {
        let author: String?
        let avatarURL: String?
        let caption: String?
        let imageURL: String
    }
    enum Kind {
        case flickVideo(FlickInfo)
        case sharedImage(ImageInfo)
        case plain
    }

    static func parse(_ content: String) -> Kind {
        let lines = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let videoExts = [".mov", ".mp4", ".m4v", ".avi", ".wmv"]
        let imageExts = [".jpg", ".jpeg", ".png", ".webp", ".heic"]

        var author: String?
        var avatarURL: String?
        var caption: String?
        var mediaURL: String?
        
        // Helper to extract by prefix
        func extract(_ line: String, prefix: String) -> String? {
            if line.lowercased().hasPrefix(prefix.lowercased()) {
                return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
            return nil
        }

        // ── Phase 1: Structured Scan ───────────────────────
        let messageText = content.lowercased()
        let isFlick = messageText.contains("[flick]")
        let isPost  = messageText.contains("[post]")

        for line in lines {
            if let a = extract(line, prefix: "author:") { author = a }
            else if let a = extract(line, prefix: "by:")     { author = a }
            else if let v = extract(line, prefix: "avatar:") { avatarURL = v }
            else if let c = extract(line, prefix: "caption:"){ caption = c }
            else if line.lowercased().hasPrefix("http") {
                mediaURL = line
            }
        }

        // ── Phase 2: Classification ────────────────────────
        if isFlick, let url = mediaURL {
             return .flickVideo(FlickInfo(author: author ?? "CineMyst User", avatarURL: avatarURL, caption: caption, videoURL: url))
        }
        if isPost, let url = mediaURL {
             return .sharedImage(ImageInfo(author: author ?? "CineMyst User", avatarURL: avatarURL, caption: caption, imageURL: url))
        }

        // ── Phase 3: Legacy Fallback ───────────────────────
        for line in lines {
            let lower = line.lowercased()
            if lower.hasPrefix("http") {
                if videoExts.contains(where: { lower.contains($0) }) {
                    let inferredCaption = lines.filter { !$0.lowercased().hasPrefix("http") && !($0.lowercased().contains("author:") || $0.lowercased().contains("by:")) }.joined(separator: " ")
                    return .flickVideo(FlickInfo(author: author ?? "CineMyst User", avatarURL: avatarURL,
                                                 caption: inferredCaption.isEmpty ? nil : inferredCaption, videoURL: line))
                }
                if imageExts.contains(where: { lower.contains($0) }) {
                    let inferredCaption = lines.filter { !$0.lowercased().hasPrefix("http") && !($0.lowercased().contains("author:") || $0.lowercased().contains("by:")) }.joined(separator: " ")
                    return .sharedImage(ImageInfo(author: author ?? "CineMyst User", avatarURL: avatarURL,
                                                  caption: inferredCaption.isEmpty ? nil : inferredCaption, imageURL: line))
                }
            }
        }

        return .plain
    }
}

// MARK: - Shared Media Card Cell Base
// Provides the common card shell: border, rounded corners, shadow

private final class MediaCardView: UIView {
    // Header
    let authorAvatar: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 14
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.85, green: 0.75, blue: 0.85, alpha: 1)
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = UIColor(red: 0.6, green: 0.3, blue: 0.55, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    let authorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = UIColor(red: 0.15, green: 0.07, blue: 0.12, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    let badgeLabel: UILabel = {
        let l = UILabel()
        l.text = "CineMyst"
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = UIColor(red: 0.55, green: 0.18, blue: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    // Media area
    let mediaContainer: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.backgroundColor = UIColor(red: 0.10, green: 0.05, blue: 0.09, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    // Footer
    let captionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(red: 0.25, green: 0.12, blue: 0.22, alpha: 1)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 18
        layer.borderWidth  = 1
        layer.borderColor  = UIColor(red: 0.55, green: 0.18, blue: 0.40, alpha: 0.18).cgColor
        layer.shadowColor  = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 0.18).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 1
        translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let authorStack = UIStackView(arrangedSubviews: [authorLabel, badgeLabel])
        authorStack.axis = .vertical
        authorStack.spacing = 0
        authorStack.translatesAutoresizingMaskIntoConstraints = false

        headerRow.addSubview(authorAvatar)
        headerRow.addSubview(authorStack)

        addSubview(headerRow)
        addSubview(mediaContainer)
        addSubview(captionLabel)

        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            headerRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            headerRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            headerRow.heightAnchor.constraint(equalToConstant: 34),

            authorAvatar.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            authorAvatar.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            authorAvatar.widthAnchor.constraint(equalToConstant: 28),
            authorAvatar.heightAnchor.constraint(equalToConstant: 28),

            authorStack.leadingAnchor.constraint(equalTo: authorAvatar.trailingAnchor, constant: 8),
            authorStack.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            authorStack.trailingAnchor.constraint(lessThanOrEqualTo: headerRow.trailingAnchor),

            mediaContainer.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 8),
            mediaContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            mediaContainer.heightAnchor.constraint(equalToConstant: 160),

            captionLabel.topAnchor.constraint(equalTo: mediaContainer.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            captionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func loadAvatar(from urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self.authorAvatar.image = img }
        }.resume()
    }
}

// MARK: - ChatFlickPreviewCell

final class ChatFlickPreviewCell: UITableViewCell {
    static let reuseID = "ChatFlickPreviewCell"

    private let card = MediaCardView()
    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let flickBadge: UILabel = {
        let l = UILabel()
        l.text = "FLICK"
        l.font = .systemFont(ofSize: 10, weight: .black)
        l.textColor = .white
        l.backgroundColor = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 0.82)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        card.mediaContainer.addSubview(thumbnailView)
        card.mediaContainer.addSubview(flickBadge)

        contentView.addSubview(card)
        contentView.addSubview(timeLabel)

        leadingC  = card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingC = card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.widthAnchor.constraint(equalToConstant: 256),

            thumbnailView.topAnchor.constraint(equalTo: card.mediaContainer.topAnchor),
            thumbnailView.leadingAnchor.constraint(equalTo: card.mediaContainer.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: card.mediaContainer.trailingAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: card.mediaContainer.bottomAnchor),

            flickBadge.leadingAnchor.constraint(equalTo: card.mediaContainer.leadingAnchor),
            flickBadge.trailingAnchor.constraint(equalTo: card.mediaContainer.trailingAnchor),
            flickBadge.bottomAnchor.constraint(equalTo: card.mediaContainer.bottomAnchor),
            flickBadge.heightAnchor.constraint(equalToConstant: 28),

            timeLabel.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 3),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(info: MediaMessageParser.FlickInfo, isFromCurrentUser: Bool, time: String) {
        card.authorLabel.text = info.author
        card.captionLabel.text = info.caption
        card.captionLabel.isHidden = info.caption == nil
        card.loadAvatar(from: info.avatarURL)
        timeLabel.text = time
        timeLabel.textAlignment = isFromCurrentUser ? .right : .left

        leadingC.isActive  = !isFromCurrentUser
        trailingC.isActive = isFromCurrentUser

        if isFromCurrentUser {
            timeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor).isActive = true
        } else {
            timeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor).isActive = true
        }

        thumbnailView.image = nil
        guard let url = URL(string: info.videoURL) else { return }
        Task {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 512, height: 320)
            if let cgImg = try? gen.copyCGImage(at: CMTime(seconds: 0.5, preferredTimescale: 600), actualTime: nil) {
                let img = UIImage(cgImage: cgImg)
                await MainActor.run { self.thumbnailView.image = img }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        card.authorAvatar.image = UIImage(systemName: "person.circle.fill")
        leadingC.isActive = false
        trailingC.isActive = false
    }
}

// MARK: - ChatImagePreviewCell

final class ChatImagePreviewCell: UITableViewCell {
    static let reuseID = "ChatImagePreviewCell"

    private let card = MediaCardView()
    private let imagePreview: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let postBadge: UILabel = {
        let l = UILabel()
        l.text = "POST"
        l.font = .systemFont(ofSize: 10, weight: .black)
        l.textColor = .white
        l.backgroundColor = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 0.78)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        card.mediaContainer.addSubview(imagePreview)
        card.mediaContainer.addSubview(postBadge)
        contentView.addSubview(card)
        contentView.addSubview(timeLabel)

        leadingC  = card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingC = card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.widthAnchor.constraint(equalToConstant: 256),

            imagePreview.topAnchor.constraint(equalTo: card.mediaContainer.topAnchor),
            imagePreview.leadingAnchor.constraint(equalTo: card.mediaContainer.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: card.mediaContainer.trailingAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: card.mediaContainer.bottomAnchor),

            postBadge.leadingAnchor.constraint(equalTo: card.mediaContainer.leadingAnchor),
            postBadge.trailingAnchor.constraint(equalTo: card.mediaContainer.trailingAnchor),
            postBadge.bottomAnchor.constraint(equalTo: card.mediaContainer.bottomAnchor),
            postBadge.heightAnchor.constraint(equalToConstant: 28),

            timeLabel.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 3),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(info: MediaMessageParser.ImageInfo, isFromCurrentUser: Bool, time: String) {
        card.authorLabel.text = info.author ?? "CineMyst User"
        card.captionLabel.text = info.caption
        card.captionLabel.isHidden = info.caption == nil
        card.loadAvatar(from: info.avatarURL)
        timeLabel.text = time
        timeLabel.textAlignment = isFromCurrentUser ? .right : .left

        leadingC.isActive  = !isFromCurrentUser
        trailingC.isActive = isFromCurrentUser

        if isFromCurrentUser {
            timeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor).isActive = true
        } else {
            timeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor).isActive = true
        }

        imagePreview.image = nil
        if let url = URL(string: info.imageURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.imagePreview.image = img }
            }.resume()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imagePreview.image = nil
        card.authorAvatar.image = UIImage(systemName: "person.circle.fill")
        leadingC.isActive = false
        trailingC.isActive = false
    }
}

// MARK: - ChatViewController Table DataSource
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch MediaMessageParser.parse(messages[indexPath.row].content) {
        case .flickVideo, .sharedImage: return UITableView.automaticDimension
        case .plain:                    return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch MediaMessageParser.parse(messages[indexPath.row].content) {
        case .flickVideo:  return 290
        case .sharedImage: return 290
        case .plain:       return 60
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let isFromCurrentUser = message.senderId == currentUserId
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let time = formatter.string(from: message.createdAt)

        switch MediaMessageParser.parse(message.content) {
        case .flickVideo(let info):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatFlickPreviewCell.reuseID, for: indexPath) as! ChatFlickPreviewCell
            cell.configure(info: info, isFromCurrentUser: isFromCurrentUser, time: time)
            return cell
        case .sharedImage(let info):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatImagePreviewCell.reuseID, for: indexPath) as! ChatImagePreviewCell
            cell.configure(info: info, isFromCurrentUser: isFromCurrentUser, time: time)
            return cell
        case .plain:
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseID, for: indexPath) as! ChatMessageCell
            cell.configure(with: message, isFromCurrentUser: isFromCurrentUser)
            return cell
        }
    }
}

// MARK: - User Search View Controller

/// View controller for searching and selecting users to chat with
final class UserSearchViewController: UIViewController {
    
    var onUserSelected: ((UUID, String) -> Void)?
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var users: [UserProfile] = []
    private var isSearching = false
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Search for users to start chatting"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Message"
        view.backgroundColor = CineMystTheme.pinkPale
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissView)
        )
        
        // Search bar
        searchBar.placeholder = "Search by name or username"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchTextField.applyCineMystSearchStyle(placeholderText: "Search by name or username")
        view.addSubview(searchBar)
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.rowHeight = 72
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        
        // Activity indicator
        view.addSubview(activityIndicator)
        
        // Instruction label
        view.addSubview(instructionLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
    
    private func searchUsers(query: String) {
        guard !query.isEmpty else {
            users = []
            tableView.reloadData()
            instructionLabel.isHidden = false
            return
        }
        
        isSearching = true
        activityIndicator.startAnimating()
        instructionLabel.isHidden = true
        
        Task {
            do {
                let results = try await MessagesService.shared.searchUsers(query: query)
                
                await MainActor.run {
                    self.users = results
                    self.tableView.reloadData()
                    self.isSearching = false
                    self.activityIndicator.stopAnimating()
                    
                    if results.isEmpty {
                        self.instructionLabel.text = "No users found"
                        self.instructionLabel.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    self.activityIndicator.stopAnimating()
                    self.instructionLabel.text = "Search failed. Try again."
                    self.instructionLabel.isHidden = false
                    print("❌ Search error: \(error)")
                }
            }
        }
    }
}

extension UserSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Debounce search
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(performSearch),
            object: nil
        )
        perform(#selector(performSearch), with: nil, afterDelay: 0.5)
    }
    
    @objc private func performSearch() {
        guard let query = searchBar.text else { return }
        searchUsers(query: query)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let query = searchBar.text else { return }
        searchUsers(query: query)
    }
}

extension UserSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = users[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = user.fullName ?? user.username ?? "User"
        config.image = UIImage(systemName: "person.crop.circle.fill")
        config.imageProperties.maximumSize = CGSize(width: 44, height: 44)
        config.imageProperties.cornerRadius = 22
        config.imageToTextPadding = 12
        config.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        config.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .regular)
        if let username = user.username {
            config.secondaryText = "@\(username)"
        } else if let bio = user.bio {
            config.secondaryText = bio
        }
        
        // Load avatar if available
        if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        var updatedConfig = config
                        updatedConfig.image = image
                        updatedConfig.imageProperties.maximumSize = CGSize(width: 44, height: 44)
                        updatedConfig.imageProperties.cornerRadius = 22
                        cell.contentConfiguration = updatedConfig
                    }
                }
            }.resume()
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = users[indexPath.row]
        let displayName = user.fullName ?? user.username ?? "User"
        
        dismiss(animated: true) { [weak self] in
            self?.onUserSelected?(user.id, displayName)
        }
    }
}
