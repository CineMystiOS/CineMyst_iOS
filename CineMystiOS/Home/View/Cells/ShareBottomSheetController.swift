//
//  ShareBottomSheetController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit

final class ShareBottomSheetController: UIViewController {
    private enum ShareAction: Int {
        case system
        case message
        case whatsapp
        case instagram
    }

    private let post: Post

    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Send as Message"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let search = UISearchBar()
        search.placeholder = "Search"
        search.searchBarStyle = .minimal

        let shareStack = UIStackView()
        shareStack.axis = .horizontal
        shareStack.alignment = .center
        shareStack.spacing = 20
        shareStack.distribution = .equalSpacing

        let icons = ["square.and.arrow.up", "message", "whatsapp", "paperplane"]
        let names = ["Share", "iMessage", "WhatsApp", "Instagram"]

        for (i, icon) in icons.enumerated() {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: icon), for: .normal)
            button.tintColor = .label
            button.setTitle("\n\(names[i])", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12)
            button.titleLabel?.textAlignment = .center
            button.contentHorizontalAlignment = .center
            button.titleEdgeInsets.top = 8
            button.tag = i
            button.addTarget(self, action: #selector(handleShareOption(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
            shareStack.addArrangedSubview(button)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, search, shareStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc private func handleShareOption(_ sender: UIButton) {
        guard let action = ShareAction(rawValue: sender.tag) else { return }

        let shareText = buildShareText()

        switch action {
        case .system:
            let activity = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
            }
            present(activity, animated: true)

        case .message, .whatsapp, .instagram:
            let activity = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
            }
            present(activity, animated: true)
        }
    }

    private func buildShareText() -> String {
        let caption = post.caption?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let caption, !caption.isEmpty {
            return "Check out this post on CineMyst:\n\n\(caption)"
        }
        return "Check out this post on CineMyst."
    }
}
