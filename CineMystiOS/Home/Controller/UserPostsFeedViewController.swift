//
//  UserPostsFeedViewController.swift
//  CineMystApp
//
//  A vertical scrolling feed of a user's posts, matching the Home feed style.
//

import UIKit

class UserPostsFeedViewController: UIViewController {
    
    private let tableView = UITableView()
    private var posts: [Post] = []
    private var initialIndex: Int = 0
    private var isFirstAppearance = true
    
    // MARK: - Init
    init(posts: [Post], startIndex: Int = 0) {
        self.posts = posts
        self.initialIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
            if initialIndex < posts.count {
                tableView.scrollToRow(at: IndexPath(row: initialIndex, section: 0), at: .top, animated: false)
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Posts"
        view.backgroundColor = .systemBackground
        
        // Add a back button with premium style
        let backBtn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        backBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        backBtn.tintColor = UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1) // deepPlum
        backBtn.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        backBtn.layer.cornerRadius = 18
        backBtn.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        backBtn.layer.shadowOpacity = 1
        backBtn.layer.shadowRadius = 10
        backBtn.layer.shadowOffset = CGSize(width: 0, height: 4)
        backBtn.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.register(PostFeedCell.self, forCellReuseIdentifier: PostFeedCell.reuseId)
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func openComments(for post: Post) {
        let commentVC = CommentViewController(post: post)
        let nav = UINavigationController(rootViewController: commentVC)
        
        let closeItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(dismissPresentedVC))
        closeItem.tintColor = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 1) // brandPlum
        commentVC.navigationItem.rightBarButtonItem = closeItem
        
        nav.modalPresentationStyle = .pageSheet
        if let s = nav.sheetPresentationController {
            s.detents = [.medium(), .large()]
            s.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    @objc private func dismissPresentedVC() {
        presentedViewController?.dismiss(animated: true)
    }
    
    private func openShareSheet(for post: Post) {
        let shareVC = ShareBottomSheetController(post: post)
        shareVC.modalPresentationStyle = .pageSheet
        if let sheet = shareVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(shareVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension UserPostsFeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostFeedCell.reuseId, for: indexPath) as! PostFeedCell
        let post = posts[indexPath.row]
        cell.isManagementEnabled = true
        cell.configure(with: post)
        
        cell.onComment = { [weak self] in
            self?.openComments(for: post)
        }
        
        cell.onShare = { [weak self] in
            self?.openShareSheet(for: post)
        }
        
        cell.onProfile = { [weak self] in
            // Already on owner's profile generally, but could link back if needed
        }
        
        cell.onMoreTap = { [weak self] button in
            self?.showPostOptions(for: post, at: indexPath.row, sourceButton: button)
        }
        
        return cell
    }
    
    private func showPostOptions(for post: Post, at index: Int, sourceButton: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { [weak self] _ in
            self?.showEditPostAlert(for: post, at: index)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete Post", style: .destructive, handler: { [weak self] _ in
            self?.confirmDeletePost(post, at: index)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceButton
            popover.sourceRect = sourceButton.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
        
        present(alert, animated: true)
    }
    
    private func showEditPostAlert(for post: Post, at index: Int) {
        let alert = UIAlertController(title: "Edit Caption", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter new caption..."
            textField.text = post.caption
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            if let newCaption = alert.textFields?.first?.text {
                self?.updatePostCaption(postId: post.id, newCaption: newCaption, at: index)
            }
        }))
        
        present(alert, animated: true)
    }
    
    private func updatePostCaption(postId: String, newCaption: String, at index: Int) {
        Task {
            do {
                try await PostManager.shared.updatePostCaption(postId: postId, newCaption: newCaption)
                await MainActor.run {
                    var updatedPost = self.posts[index]
                    updatedPost.caption = newCaption
                    self.posts[index] = updatedPost
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }
            } catch {
                print("❌ Error updating post: \(error)")
                await MainActor.run {
                    let errorAlert = UIAlertController(title: "Error", message: "Could not update post. Please try again.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    private func confirmDeletePost(_ post: Post, at index: Int) {
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deletePost(post, at: index)
        }))
        
        present(alert, animated: true)
    }
    
    private func deletePost(_ post: Post, at index: Int) {
        Task {
            do {
                try await PostManager.shared.deletePost(postId: post.id)
                await MainActor.run {
                    self.posts.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }
            } catch {
                print("❌ Error deleting post: \(error)")
                await MainActor.run {
                    let errorAlert = UIAlertController(title: "Error", message: "Could not delete post. Please try again.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
