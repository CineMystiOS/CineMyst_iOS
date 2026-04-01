import UIKit

final class NotificationCell: UITableViewCell {

    // MARK: - Callbacks
    var onAccept:  (() -> Void)?
    var onDecline: (() -> Void)?

    // MARK: - Subviews
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 22
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Accept / Decline row
    private let actionRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let acceptButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Accept", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 0.27, green: 0.08, blue: 0.27, alpha: 1) // deep plum
        b.layer.cornerRadius = 14
        b.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        return b
    }()

    private let declineButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Decline", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        b.setTitleColor(UIColor(red: 0.27, green: 0.08, blue: 0.27, alpha: 1), for: .normal)
        b.backgroundColor = UIColor(red: 0.27, green: 0.08, blue: 0.27, alpha: 0.1)
        b.layer.cornerRadius = 14
        b.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        return b
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.isHidden = true
        return l
    }()

    // Text stack
    private let textStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupUI() {
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)
        textStack.addArrangedSubview(timeLabel)

        // Accept / Decline buttons in actionRow
        actionRow.addArrangedSubview(acceptButton)
        actionRow.addArrangedSubview(declineButton)
        actionRow.addArrangedSubview(statusLabel)
        textStack.addArrangedSubview(actionRow)

        contentView.addSubview(iconView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(with item: NotificationItem) {
        titleLabel.text  = item.title
        messageLabel.text = item.message
        timeLabel.text   = item.timeAgo

        // Icon
        if item.isSystemIcon, let name = item.imageName {
            iconView.image = UIImage(systemName: name)
            iconView.tintColor = item.type == "connection_request"
                ? UIColor(red: 0.27, green: 0.08, blue: 0.27, alpha: 1)
                : .systemOrange
            iconView.backgroundColor = iconView.tintColor.withAlphaComponent(0.12)
        } else if let name = item.imageName {
            iconView.image = UIImage(named: name) ?? UIImage(systemName: "person.crop.circle.fill")
            iconView.backgroundColor = .clear
        } else {
            iconView.image = UIImage(systemName: "bell.fill")
            iconView.tintColor = .systemOrange
        }

        // Action buttons (connection request only)
        switch item.type {
        case "connection_request":
            switch item.actionState {
            case "pending":
                actionRow.isHidden = false
                acceptButton.isHidden  = false
                declineButton.isHidden = false
                statusLabel.isHidden   = true
            case "accepted":
                actionRow.isHidden = false
                acceptButton.isHidden  = true
                declineButton.isHidden = true
                statusLabel.isHidden   = false
                statusLabel.text = "✓ Connected"
                statusLabel.textColor = .systemGreen
            case "declined":
                actionRow.isHidden = false
                acceptButton.isHidden  = true
                declineButton.isHidden = true
                statusLabel.isHidden   = false
                statusLabel.text = "Declined"
                statusLabel.textColor = .secondaryLabel
            default:
                actionRow.isHidden = true
            }
        default:
            actionRow.isHidden = true
        }
    }

    // MARK: - Actions
    @objc private func acceptTapped()  { onAccept?() }
    @objc private func declineTapped() { onDecline?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAccept  = nil
        onDecline = nil
        actionRow.isHidden = true
        statusLabel.isHidden = true
        acceptButton.isHidden  = false
        declineButton.isHidden = false
    }
}
