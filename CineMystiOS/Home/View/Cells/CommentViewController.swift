//
//  CommentViewController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

//
//  CommentViewController.swift
//  CineMystApp
//
//  Created by Devanshi on 11/11/25.
//

import UIKit

struct CommentDisplayData {
    let username: String
    let userImage: String?
    let text: String
    let timeAgo: String
}

final class CommentViewController: UIViewController {
    
    // MARK: - Properties
    private let post: Post
    private var comments: [PostComment] = []
    private var isLoadingComments = false
    private var currentUserProfileUrl: String?
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let profileImageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Init
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardObservers()
        fetchComments()
        loadCurrentUserProfile()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Comments"
        view.backgroundColor = .systemBackground
        
        // TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseId)
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)
        
        // Input Container
        inputContainer.backgroundColor = .secondarySystemBackground
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.borderWidth = 0.3
        inputContainer.layer.borderColor = UIColor.systemGray4.cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        // Profile Image
        profileImageView.image = UIImage(named: "avatar_placeholder")
        profileImageView.layer.cornerRadius = 18
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .systemGray5
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(profileImageView)
        
        // Comment Field
        commentField.placeholder = "Add a comment..."
        commentField.font = .systemFont(ofSize: 15)
        commentField.borderStyle = .none
        commentField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(commentField)
        
        // Send Button
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        // Loading Indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            inputContainer.heightAnchor.constraint(equalToConstant: 52),
            
            profileImageView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            profileImageView.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 36),
            profileImageView.heightAnchor.constraint(equalToConstant: 36),
            
            commentField.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            commentField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            
            sendButton.leadingAnchor.constraint(equalTo: commentField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func fetchComments() {
        guard !isLoadingComments else { return }
        
        isLoadingComments = true
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let fetchedComments = try await PostManager.shared.fetchComments(postId: post.id)
                
                DispatchQueue.main.async {
                    self.comments = fetchedComments
                    self.tableView.reloadData()
                    self.isLoadingComments = false
                    self.loadingIndicator.stopAnimating()
                    
                    print("✅ Loaded \(fetchedComments.count) comments")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingComments = false
                    self.loadingIndicator.stopAnimating()
                    
                    print("❌ Error fetching comments: \(error)")
                    self.showErrorAlert("Failed to load comments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Load Current User Profile
    private func loadCurrentUserProfile() {
        Task {
            do {
                let profile = try await PostManager.shared.fetchCurrentUserProfile()
                
                DispatchQueue.main.async {
                    if let profileUrl = profile?.profilePictureUrl, !profileUrl.isEmpty {
                        self.currentUserProfileUrl = profileUrl
                        self.loadProfileImage(from: profileUrl)
                    } else {
                        self.profileImageView.image = UIImage(named: "avatar_placeholder")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("⚠️ Could not load current user profile: \(error)")
                    self.profileImageView.image = UIImage(named: "avatar_placeholder")
                }
            }
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            profileImageView.image = UIImage(named: "avatar_placeholder")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.profileImageView.image = UIImage(named: "avatar_placeholder")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // MARK: - Actions
    @objc private func sendComment() {
        guard let text = commentField.text, !text.isEmpty else { return }
        
        // Disable send button during submission
        sendButton.isEnabled = false
        
        // Save comment to database
        Task {
            do {
                try await PostManager.shared.addComment(postId: post.id, text: text)
                
                DispatchQueue.main.async {
                    self.commentField.text = ""
                    self.sendButton.isEnabled = true
                    
                    // Reload comments to show the new one
                    self.fetchComments()
                    
                    print("✅ Comment sent successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self.sendButton.isEnabled = true
                    
                    print("❌ Error sending comment: \(error)")
                    self.showErrorAlert("Failed to send comment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            view.frame.origin.y = -frame.height + 60
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
}

extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as! CommentCell
        cell.configure(with: comments[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ✅ Tap profile or comment
        let username = comments[indexPath.row].username
        print("Tapped on \(username)'s profile or comment")
    }
}
