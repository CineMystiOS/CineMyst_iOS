//
//  CommentBottomSheetViewController.swift
//  CineMystApp
//
//  Created by user@55 on 25/11/25.
//

import UIKit

// MARK: - Comment Bottom Sheet
class CommentBottomSheetViewController: UIViewController {
    
    var flickId: String?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Comments"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.register(ReelCommentCell.self, forCellReuseIdentifier: "ReelCommentCell")
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let commentInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let commentTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Add a comment..."
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Send", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var comments: [ReelComment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        sendButton.addTarget(self, action: #selector(sendCommentTapped), for: .touchUpInside)
        loadComments()
    }
    
    private func loadComments() {
        guard let flickId = flickId else { return }
        
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let flickComments = try await FlicksService.shared.fetchComments(flickId: flickId)
                
                await MainActor.run {
                    self.comments = flickComments.map { comment in
                        ReelComment(
                            username: comment.username ?? "User",
                            text: comment.comment,
                            timeAgo: self.timeAgoString(from: comment.createdAt)
                        )
                    }
                    self.tableView.reloadData()
                    self.loadingIndicator.stopAnimating()
                }
            } catch {
                print("❌ Failed to load comments: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    @objc private func sendCommentTapped() {
        guard let flickId = flickId,
              let commentText = commentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !commentText.isEmpty else { return }
        
        sendButton.isEnabled = false
        
        Task {
            do {
                let newComment = try await FlicksService.shared.addComment(flickId: flickId, comment: commentText)
                
                await MainActor.run {
                    // Add to local array
                    let reelComment = ReelComment(
                        username: newComment.username ?? "You",
                        text: newComment.comment,
                        timeAgo: "Just now"
                    )
                    self.comments.insert(reelComment, at: 0)
                    self.tableView.reloadData()
                    
                    // Clear input
                    self.commentTextField.text = ""
                    self.sendButton.isEnabled = true
                    
                    // Dismiss keyboard
                    self.commentTextField.resignFirstResponder()
                }
            } catch {
                print("❌ Failed to post comment: \(error)")
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    
                    let alert = UIAlertController(title: "Error", message: "Failed to post comment. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func timeAgoString(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "now" }
        
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
    
    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(commentInputContainer)
        view.addSubview(loadingIndicator)
        commentInputContainer.addSubview(commentTextField)
        commentInputContainer.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            loadingIndicator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: commentInputContainer.topAnchor),
            
            commentInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            commentInputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            commentTextField.leadingAnchor.constraint(equalTo: commentInputContainer.leadingAnchor, constant: 16),
            commentTextField.centerYAnchor.constraint(equalTo: commentInputContainer.centerYAnchor),
            commentTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: commentInputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: commentInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
}

extension CommentBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReelCommentCell", for: indexPath) as! ReelCommentCell
        cell.configure(with: comments[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
