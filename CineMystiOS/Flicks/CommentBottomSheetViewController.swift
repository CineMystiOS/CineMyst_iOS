//
//  CommentBottomSheetViewController.swift
//  CineMystApp
//
//  Dark cinematic bottom sheet — deep plum + rose aesthetic

import UIKit

final class CommentBottomSheetViewController: UIViewController {

    // MARK: - Public
    var flickId: String?

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
        l.text          = "No comments yet\nBe the first! ✨"
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
        let username: String
        let avatarURL: String?
        let text: String
        let timeAgo: String
    }

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
                    username: c.username ?? "You",
                    avatarURL: nil,
                    text: c.comment,
                    timeAgo: "Just now"
                )
                self.comments.insert(d, at: 0)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self.emptyLabel.isHidden = true
            } catch {
                print("❌ Comment post: \(error)")
            }
            self.sendButton.isEnabled = true
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return "now" }
        let s = Date().timeIntervalSince(d)
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

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: DarkCommentCell.id, for: ip) as! DarkCommentCell
        cell.configure(with: comments[ip.row])
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tv: UITableView, estimatedHeightForRowAt ip: IndexPath) -> CGFloat { 70 }
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(avatar)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(commentLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),

            usernameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            usernameLabel.topAnchor.constraint(equalTo: avatar.topAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),

            commentLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 3),
            commentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with c: CommentBottomSheetViewController.DisplayComment) {
        usernameLabel.text = "@\(c.username)"
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
