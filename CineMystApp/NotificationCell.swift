import UIKit

final class NotificationCell: UITableViewCell {

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
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0               // allow wrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let connectButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Connect", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        b.tintColor = .white
        b.backgroundColor = UIColor(named: "AppPrimary") ?? .systemPurple
        b.layer.cornerRadius = 14
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setContentHuggingPriority(.required, for: .horizontal)
        return b
    }()

    // Stacks
    private let textStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let horizontalStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func setupUI() {
        // Compose stacks
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        horizontalStack.addArrangedSubview(iconView)
        horizontalStack.addArrangedSubview(textStack)
        horizontalStack.addArrangedSubview(connectButton)

        contentView.addSubview(horizontalStack)
        contentView.addSubview(timeLabel)

        // Constraints
        NSLayoutConstraint.activate([
            // icon size
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            // horizontalStack pinned to contentView top & sides
            horizontalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            horizontalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // timeLabel below the horizontalStack and pinned to bottom (important!)
            timeLabel.topAnchor.constraint(equalTo: horizontalStack.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        // Make sure the textStack can shrink when connectButton is present
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // If the connect button is hidden, it shouldn't take space
        connectButton.isHidden = true
    }

    // MARK: - Configure
    func configure(with item: NotificationItem) {
        titleLabel.text = item.title
        messageLabel.text = item.message
        timeLabel.text = item.timeAgo

        connectButton.isHidden = !item.showConnectButton

        if let name = item.imageName {
            if item.isSystemIcon {
                iconView.image = UIImage(systemName: name)
                iconView.tintColor = .systemOrange
                iconView.backgroundColor = .clear
            } else {
                iconView.image = UIImage(named: name) ?? UIImage(systemName: "person.crop.circle.fill")
                iconView.backgroundColor = .clear
            }
        } else {
            iconView.image = UIImage(systemName: "bell.fill")
        }
    }

    // Ensure layout calculation is stable
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
    }
}
