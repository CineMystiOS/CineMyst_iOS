//
//  CommentBottomSheetViewController.swift
//  CineMystApp
//
//  Dark cinematic bottom sheet — deep plum + rose aesthetic

import UIKit

final class CommentBottomSheetViewController: UIViewController {

    // MARK: - Public
    var flickId: String?
    var allowComments: Bool = true  // Set from the Flick model before presenting

    // MARK: - Design
    private enum DS {
        static let bg      = UIColor(red: 0.07, green: 0.04, blue: 0.06, alpha: 1)
        static let card    = UIColor(red: 0.13, green: 0.07, blue: 0.11, alpha: 1)
        static let plum    = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1)
        static let rose    = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        static let text    = UIColor.white
        static let sub     = UIColor(white: 1, alpha: 0.55)
    }

    // MARK: - UI

    private let grabber: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.25)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text      = "Comments"
        l.font      = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate   = self
        tv.dataSource = self
        tv.register(DarkCommentCell.self, forCellReuseIdentifier: DarkCommentCell.id)
        tv.separatorStyle  = .none
        tv.backgroundColor = .clear
        tv.keyboardDismissMode = .interactive
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let inputBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.13, green: 0.07, blue: 0.11, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder              = "Add a comment..."
        tf.attributedPlaceholder    = NSAttributedString(
            string: "Add a comment...",
            attributes: [.foregroundColor: UIColor(white: 1, alpha: 0.35)]
        )
        tf.textColor    = .white
        tf.font         = .systemFont(ofSize: 14)
        tf.tintColor    = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        tf.backgroundColor = UIColor(white: 1, alpha: 0.07)
        tf.layer.cornerRadius = 18
        tf.leftView     = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.returnKeyType = .send
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        b.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text          = "No comments yet\nBe the first!"
        l.font          = .systemFont(ofSize: 15, weight: .medium)
        l.textColor     = UIColor(white: 1, alpha: 0.4)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden      = true
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

    private var inputBarBottomConstraint: NSLayoutConstraint?

    // MARK: - Data
    private var comments: [DisplayComment] = []

    struct DisplayComment {
        let id: String
        let userId: String
        let username: String
        let avatarURL: String?
        let text: String
        let timeAgo: String
    }
    
    var onCommentAdded: (() -> Void)?
    var onCommentDeleted: (() -> Void)?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.bg
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        setupViews()
        registerKeyboard()
        inputField.delegate = self
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        loadComments()

        // Enforce allow_comments setting
        if !allowComments {
            inputBar.isHidden = true
            // Show a disabled notice
            let notice = UILabel()
            notice.text = "🔒 Comments are turned off for this Flick"
            notice.font = .systemFont(ofSize: 13, weight: .medium)
            notice.textColor = UIColor(white: 1, alpha: 0.4)
            notice.textAlignment = .center
            notice.numberOfLines = 0
            notice.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(notice)
            NSLayoutConstraint.activate([
                notice.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                notice.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                notice.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
            ])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupViews() {
        view.addSubview(grabber)
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(spinner)
        view.addSubview(inputBar)
        inputBar.addSubview(inputField)
        inputBar.addSubview(sendButton)

        let ibBottom = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputBarBottomConstraint = ibBottom

        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),

            spinner.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 64),
            ibBottom,

            inputField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            inputField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputField.heightAnchor.constraint(equalToConstant: 38),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Keyboard

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
    }

    @objc private func keyboardWillChange(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let dur   = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardHeight = max(0, UIScreen.main.bounds.height - frame.origin.y)
        let safeBottom = view.safeAreaInsets.bottom
        inputBarBottomConstraint?.constant = keyboardHeight > 0 ? -(keyboardHeight - safeBottom) : 0

        UIView.animate(withDuration: dur, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Data

    private func loadComments() {
        guard let flickId else { return }
        spinner.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                let raw = try await FlicksService.shared.fetchComments(flickId: flickId)
                let display = raw.map { c in
                    DisplayComment(
                        id: c.id,
                        userId: c.userId,
                        username: c.username ?? "User",
                        avatarURL: c.profilePictureUrl,
                        text: c.comment,
                        timeAgo: timeAgo(c.createdAt)
                    )
                }
                self.comments = display
                self.tableView.reloadData()
                self.spinner.stopAnimating()
                self.emptyLabel.isHidden = !display.isEmpty
            } catch {
                self.spinner.stopAnimating()
                print("❌ Comments fetch: \(error)")
            }
        }
    }

    @objc private func sendTapped() {
        guard let flickId,
              let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else { return }

        inputField.text = ""
        inputField.resignFirstResponder()
        sendButton.isEnabled = false

        Task {
            do {
                let c = try await FlicksService.shared.addComment(flickId: flickId, comment: text)
                let d = DisplayComment(
                    id: c.id,
                    userId: c.userId,
                    username: c.username ?? "You",
                    avatarURL: nil,
                    text: c.comment,
                    timeAgo: "Just now"
                )
                
                await MainActor.run {
                    self.comments.insert(d, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                    self.emptyLabel.isHidden = true
                    self.sendButton.isEnabled = true
                    self.onCommentAdded?()
                }
            } catch {
                print("❌ Comment post: \(error)")
                await MainActor.run {
                    self.sendButton.isEnabled = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = f.date(from: iso)
        if date == nil {
            let backupFormatter = ISO8601DateFormatter()
            date = backupFormatter.date(from: iso)
        }
        guard let validDate = date else { return "now" }
        let s = Date().timeIntervalSince(validDate)
        switch s {
        case ..<60:      return "Just now"
        case ..<3600:    return "\(Int(s/60))m"
        case ..<86400:   return "\(Int(s/3600))h"
        default:         return "\(Int(s/86400))d"
        }
    }
}

// MARK: - UITableView

extension CommentBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { comments.count }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = comments[indexPath.row]
        let cell = tv.dequeueReusableCell(withIdentifier: DarkCommentCell.id, for: indexPath) as! DarkCommentCell
        
        let currentUserId = AuthManager.shared.currentUser?.id.uuidString.lowercased()
        let isOwner = (currentUserId == comment.userId.lowercased())
        
        cell.configure(with: comment, isOwner: isOwner)
        cell.onOptionsTapped = { [weak self] in
            self?.showOptionsActionSheet(for: comment)
        }
        
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tv: UITableView, estimatedHeightForRowAt ip: IndexPath) -> CGFloat { 70 }
    
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let comment = comments[indexPath.row]
        let currentUserId = AuthManager.shared.currentUser?.id.uuidString.lowercased()
        
        // Only show swipe to delete if they own it
        guard currentUserId == comment.userId.lowercased() else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.deleteComment(comment)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        return config
    }
    
    private func showOptionsActionSheet(for comment: DisplayComment) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self] _ in
            self?.showEditAlert(for: comment)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteComment(comment)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showEditAlert(for comment: DisplayComment) {
        let alert = UIAlertController(title: "Edit comment", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = comment.text
            tf.tintColor = DS.rose
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let newText = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !newText.isEmpty else { return }
            
            Task {
                do {
                    try await FlicksService.shared.updateComment(commentId: comment.id, comment: newText)
                    let updatedComment = DisplayComment(
                        id: comment.id,
                        userId: comment.userId,
                        username: comment.username,
                        avatarURL: comment.avatarURL,
                        text: newText,
                        timeAgo: comment.timeAgo
                    )
                    await MainActor.run {
                        if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                            self.comments[index] = updatedComment
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        }
                    }
                } catch {
                    print("❌ Failed to edit comment: \(error)")
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    private func deleteComment(_ comment: DisplayComment) {
        guard let flickId = self.flickId else { return }
        Task {
            do {
                try await FlicksService.shared.deleteComment(commentId: comment.id, flickId: flickId)
                await MainActor.run {
                    if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                        self.comments.remove(at: index)
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                        self.emptyLabel.isHidden = !self.comments.isEmpty
                        self.onCommentDeleted?()
                    }
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Failed to Delete", message: "Comment could not be deleted from the database. Please check your Supabase Row Level Security (RLS) policies to ensure DELETE is allowed.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                print("❌ Failed to delete comment: \(error)")
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension CommentBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }
}

// MARK: - DarkCommentCell

final class DarkCommentCell: UITableViewCell {
    static let id = "DarkCommentCell"

    private let avatar: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 18
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let commentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.9)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.4)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var optionsButton: UIButton = {
        let b = UIButton(type: .system)
        let image = UIImage(systemName: "ellipsis")
        b.setImage(image, for: .normal)
        b.tintColor = UIColor(white: 1, alpha: 0.6)
        b.transform = CGAffineTransform(rotationAngle: .pi / 2) // Makes it vertical
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapOptions), for: .touchUpInside)
        return b
    }()
    
    var onOptionsTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(avatar)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(commentLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(optionsButton)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),
            
            usernameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            usernameLabel.topAnchor.constraint(equalTo: avatar.topAnchor),
            
            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: 24),
            optionsButton.heightAnchor.constraint(equalToConstant: 24),
            
            timeLabel.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -4),
            timeLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            commentLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            commentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func didTapOptions() {
        onOptionsTapped?()
    }

    func configure(with c: CommentBottomSheetViewController.DisplayComment, isOwner: Bool) {
        usernameLabel.text = "@\(c.username)"
        optionsButton.isHidden = !isOwner
        commentLabel.text  = c.text
        timeLabel.text     = c.timeAgo
        avatar.image       = UIImage(systemName: "person.circle.fill")
        avatar.tintColor   = UIColor(white: 0.4, alpha: 1)

        if let urlStr = c.avatarURL, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.avatar.image = img }
            }.resume()
        }
    }
}
