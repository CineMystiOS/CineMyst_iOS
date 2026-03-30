//
//  MessagesViewController.swift
//

import UIKit
import Supabase

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
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

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

    // UI
    private let navLeftButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let navRightStack: UIStackView = {
        let compose = UIButton(type: .system)
        compose.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        compose.tintColor = .systemBlue
        compose.translatesAutoresizingMaskIntoConstraints = false
        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        more.tintColor = .systemBlue
        more.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [more, compose])
        stack.spacing = 12
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Messages"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        view.backgroundColor = .systemBackground
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ensure default navigation state: hide the standard back button if this VC is root
        navigationItem.hidesBackButton = true
        
        // Refresh conversations when view appears
        loadConversations()
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

    private func configureSubviews() {
        // Top "nav" area — only add the left back button when needed
        let shouldShowBack = shouldShowBackButton()
        if shouldShowBack {
            view.addSubview(navLeftButton)
        }

        view.addSubview(titleLabel)
        view.addSubview(navRightStack)

        // Search
        view.addSubview(searchField)

        // Table
        view.addSubview(tableView)
        
        // Loading indicator and empty state
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateLabel)
    }

    private func configureConstraints() {
        let safe = view.safeAreaLayoutGuide

        // We'll build constraints conditionally depending on whether we added navLeftButton
        let shouldShowBack = shouldShowBackButton()

        var constraints: [NSLayoutConstraint] = []

        if shouldShowBack {
            // nav left button constraints
            constraints += [
                navLeftButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 12),
                navLeftButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
                navLeftButton.widthAnchor.constraint(equalToConstant: 30),
                navLeftButton.heightAnchor.constraint(equalToConstant: 30)
            ]

            // nav right stack vertically aligned with left button
            constraints += [
                navRightStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12),
                navRightStack.centerYAnchor.constraint(equalTo: navLeftButton.centerYAnchor)
            ]

            // title centered using the left button's centerY
            constraints += [
                titleLabel.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: navLeftButton.centerYAnchor)
            ]
        } else {
            // No left nav button — center title at top safe area
            constraints += [
                titleLabel.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),

                navRightStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12),
                navRightStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
            ]
        }

        // Common constraints for the rest of the UI
        constraints += [
            // Search bar
            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12),
            searchField.heightAnchor.constraint(equalToConstant: 44),

            // Table view (directly below search field)
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
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
            // Sent messages - blue bubble on right
            bubbleView.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            timeLabel.textAlignment = .right
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        } else {
            // Received messages - gray bubble on left
            bubbleView.backgroundColor = UIColor.systemGray5
            messageLabel.textColor = .label
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
    
    private let tableView = UITableView()
    private var messages: [Message] = []
    private let messageInputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var currentUserId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = otherUserName ?? "Chat"
        currentUserId = supabase.auth.currentUser?.id
        setupUI()
        loadMessages()
    }
    
    private func setupUI() {
        // Table view for messages
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseID)
        tableView.backgroundColor = .systemBackground
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)
        
        // Input container
        let inputContainer = UIView()
        inputContainer.backgroundColor = .systemBackground
        inputContainer.layer.borderColor = UIColor.separator.cgColor
        inputContainer.layer.borderWidth = 0.5
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        // Message input field
        messageInputField.placeholder = "Type a message..."
        messageInputField.borderStyle = .roundedRect
        messageInputField.backgroundColor = .systemGray6
        messageInputField.layer.cornerRadius = 20
        messageInputField.layer.masksToBounds = true
        messageInputField.font = .systemFont(ofSize: 16)
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        messageInputField.leftView = paddingView
        messageInputField.leftViewMode = .always
        
        inputContainer.addSubview(messageInputField)
        
        // Send button
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputContainer.addSubview(sendButton)
        
        // Constraints
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
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
    
    private func loadMessages() {
        guard let conversationId = conversationId else { return }
        
        Task {
            do {
                let fetchedMessages = try await MessagesService.shared.fetchMessages(conversationId: conversationId)
                await MainActor.run {
                    self.messages = fetchedMessages
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            } catch {
                print("❌ Failed to load messages: \(error)")
            }
        }
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
                let _ = try await MessagesService.shared.sendMessage(
                    conversationId: conversationId,
                    content: text
                )
                
                loadMessages() // Reload to show new message
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - ChatViewController Table DataSource
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseID, for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.row]
        let isFromCurrentUser = message.senderId == currentUserId
        
        cell.configure(with: message, isFromCurrentUser: isFromCurrentUser)
        
        return cell
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
        view.backgroundColor = .systemBackground
        
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
        view.addSubview(searchBar)
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
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
                        cell.contentConfiguration = updatedConfig
                    }
                }
            }.resume()
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
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
