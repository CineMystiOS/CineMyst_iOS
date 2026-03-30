// SessionCell.swift
// Reusable table cell used by PostBookingMentorshipViewController

import UIKit

final class SessionCell: UITableViewCell {
    static let reuseIdentifier = "SessionCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray6
        v.layer.cornerRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 8
        return v
    }()

    private let avatar: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 28
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .systemGray4
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let ratingStack: UIStackView = {
        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = .systemBlue
        star.translatesAutoresizingMaskIntoConstraints = false
        star.widthAnchor.constraint(equalToConstant: 14).isActive = true
        star.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let rating = UILabel()
        rating.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        rating.translatesAutoresizingMaskIntoConstraints = false
        rating.text = "4.8" // static demo rating; change if you store rating in Session/Mentor

        let s = UIStackView(arrangedSubviews: [star, rating])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(avatar)
        cardView.addSubview(nameLabel)
        cardView.addSubview(roleLabel)
        cardView.addSubview(dateLabel)
        cardView.addSubview(ratingStack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatar.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: ratingStack.leadingAnchor, constant: -8),

            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12),

            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14),

            ratingStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            ratingStack.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with session: SessionM) {
        nameLabel.text = session.mentorName
        roleLabel.text = session.mentorRole ?? ""
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        dateLabel.text = df.string(from: session.date)

        // Use the image name stored in the session. Falls back to asset named "Image".
        let image = UIImage(named: session.mentorImageName) ?? UIImage(named: "Image")
        avatar.image = image
        avatar.contentMode = .scaleAspectFill
    }
}
