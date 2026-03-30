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

struct Comment {
    let username: String
    let userImage: String
    let text: String
}

final class CommentViewController: UIViewController {
    
    // MARK: - Properties
    private let post: Post
    private var comments: [Comment] = [
        Comment(username: "Dhruv Garg", userImage: "avatar_dhruv", text: "Wow! Great shot 🔥"),
        Comment(username: "Shradha", userImage: "avatar_shradha", text: "So proud of your work ❤️")
    ]
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let profileImageView = UIImageView()
    
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
        profileImageView.image = UIImage(named: "avatar_rani") // your profile image
        profileImageView.layer.cornerRadius = 18
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
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
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func sendComment() {
        guard let text = commentField.text, !text.isEmpty else { return }
        
        let newComment = Comment(username: "You", userImage: "avatar_rani", text: text)
        comments.append(newComment)
        tableView.reloadData()
        
        // Clear the text field
        commentField.text = ""
        
        // Scroll to bottom
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.comments.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
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
