//
//  MentorshipHomeViewController.swift
//  ProgrammaticMentorship
//

import UIKit
import Supabase

enum MentorshipUI {
    static let brandPlum = CineMystTheme.brandPlum
    static let deepPlum = CineMystTheme.deepPlum
    static let deepPlumMid = CineMystTheme.deepPlumMid
    static let deepPlumDark = CineMystTheme.deepPlumDark
    static let pageBackground = UIColor(red: 0.975, green: 0.965, blue: 0.975, alpha: 1)
    static let raisedSurface = UIColor.white.withAlphaComponent(0.88)
    static let softSurface = UIColor.white.withAlphaComponent(0.74)
    static let plumField = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.06)
    static let plumChip = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.09)
    static let plumStroke = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.10)
    static let mutedText = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.58)
    static let softText = UIColor(red: 0.333, green: 0.098, blue: 0.204, alpha: 0.78)
    static let shadow = UIColor(red: 0.176, green: 0.043, blue: 0.118, alpha: 0.14)
}

// MARK: - MentorCell (unchanged)
final class MentorCell: UICollectionViewCell {
    static let reuseIdentifier = "MentorCell"
    private static let imageCache = NSCache<NSString, UIImage>()
    private let plum = MentorshipUI.brandPlum

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = MentorshipUI.raisedSurface
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = false
        v.layer.shadowColor = MentorshipUI.shadow.cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = MentorshipUI.plumStroke.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let imageContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.backgroundColor = CineMystTheme.plumMist
        return v
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = CineMystTheme.plumMist
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = MentorshipUI.brandPlum
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        l.textColor = MentorshipUI.mutedText
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let priceChipView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 10
        v.backgroundColor = MentorshipUI.plumChip
        return v
    }()

    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = MentorshipUI.brandPlum
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var rolePriceRow: UIStackView = {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let s = UIStackView(arrangedSubviews: [roleLabel, spacer, priceChipView])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)

        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(photoView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(rolePriceRow)
        priceChipView.addSubview(priceLabel)

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        roleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        roleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        roleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        priceChipView.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceChipView.setContentHuggingPriority(.required, for: .horizontal)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            imageContainerView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 9),
            imageContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 9),
            imageContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -9),
            imageContainerView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),

            photoView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 11),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -11),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),

            rolePriceRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 11),
            rolePriceRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -11),
            rolePriceRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -11),
            rolePriceRow.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            rolePriceRow.heightAnchor.constraint(equalToConstant: 24),

            priceLabel.topAnchor.constraint(equalTo: priceChipView.topAnchor, constant: 5),
            priceLabel.leadingAnchor.constraint(equalTo: priceChipView.leadingAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: priceChipView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(equalTo: priceChipView.bottomAnchor, constant: -5)
        ])
    }

    func configure(with mentor: Mentor) {
        nameLabel.text = mentor.name
        roleLabel.text = mentor.role
        priceChipView.isHidden = true // Always hide price chip
        // Prefer remote profilePictureUrl if provided, with cache; otherwise use local asset or symbol
        photoView.image = nil
        if let urlStrRaw = mentor.profilePictureUrl, !urlStrRaw.isEmpty {
            let placeholderConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            photoView.image = UIImage(systemName: "person.crop.rectangle", withConfiguration: placeholderConfig)
            photoView.contentMode = .center
            photoView.tintColor = UIColor.systemGray3
            photoView.backgroundColor = CineMystTheme.plumMist

            // Try several URL creation strategies
            var candidateURLs: [URL] = []
            if let u = URL(string: urlStrRaw) { candidateURLs.append(u) }
            if let esc = urlStrRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let u2 = URL(string: esc) { candidateURLs.append(u2) }
            if !urlStrRaw.contains("://"), let u3 = URL(string: "https://\(urlStrRaw)") { candidateURLs.append(u3) }

            // try cache for any candidate key
            for c in candidateURLs {
                let key = NSString(string: c.absoluteString)
            if let cached = MentorCell.imageCache.object(forKey: key) {
                photoView.image = cached
                photoView.contentMode = .scaleAspectFill
                photoView.backgroundColor = .clear
                return
                }
            }

            Task {
                for c in candidateURLs {
                    if let (data, _) = try? await URLSession.shared.data(from: c), let img = UIImage(data: data) {
                        MentorCell.imageCache.setObject(img, forKey: NSString(string: c.absoluteString))
                        await MainActor.run {
                            self.photoView.image = img
                            self.photoView.contentMode = .scaleAspectFill
                            self.photoView.backgroundColor = .clear
                        }
                        return
                    }
                }
            }
        } else if let imageName = mentor.imageName, let img = UIImage(named: imageName) {
            photoView.image = img
            photoView.contentMode = .scaleAspectFill
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            let img = UIImage(systemName: "person.crop.rectangle", withConfiguration: config)
            photoView.image = img
            photoView.contentMode = .center
            photoView.tintColor = CineMystTheme.plumHaze
            photoView.backgroundColor = CineMystTheme.plumMist
        }

        cardView.layer.borderColor = MentorshipUI.plumStroke.cgColor
    }

    private static func priceHint(for mentor: Mentor) -> String? {
        let metadataMinPrice = minimumPrice(from: mentor.metadataJson)

        if let money = mentor.moneyString, !money.isEmpty {
            if let numericMoney = numericPrice(from: money), numericMoney <= 1, let metadataMinPrice {
                return formatPrice(metadataMinPrice)
            }
            if let numericMoney = numericPrice(from: money), numericMoney > 0 {
                return formatPrice(Int(numericMoney.rounded()))
            }
            return money.replacingOccurrences(of: "From ", with: "")
        }

        if let cents = mentor.priceCents, cents > 0 {
            return formatPrice(cents / 100)
        }

        if let metadataMinPrice {
            return formatPrice(metadataMinPrice)
        }

        return nil
    }

    private static func formatPrice(_ value: Int) -> String {
        return "₹ \(value)"
    }

    private static func minimumPrice(from metadataJson: String?) -> Int? {
        guard let metadataJson,
              let metadata = metadataJson.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any],
              let pricesRaw = object["prices_json"] as? String,
              let pricesData = pricesRaw.data(using: .utf8),
              let pricesObject = try? JSONSerialization.jsonObject(with: pricesData) as? [String: Any] else {
            return nil
        }

        let numericValues = pricesObject.values.compactMap { numericPrice(from: $0) }
        guard let minValue = numericValues.filter({ $0 > 0 }).min() else { return nil }
        return Int(minValue.rounded())
    }

    private static func numericPrice(from raw: Any?) -> Double? {
        if let number = raw as? NSNumber { return number.doubleValue }
        if let string = raw as? String {
            let lower = string.lowercased()
            let multiplier: Double = lower.contains("k") ? 1000.0 : 1.0
            let digits = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            guard let value = Double(digits) else { return nil }
            return value * multiplier
        }
        return nil
    }
}

final class BookingCardCell: UITableViewCell {
    static let reuseIdentifier = "BookingCardCell"
    private static let imageCache = NSCache<NSString, UIImage>()
    private let plum = MentorshipUI.brandPlum
    private var currentImageURLString: String?

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = false
        view.layer.shadowColor = MentorshipUI.shadow.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 12)
        view.layer.shadowRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = MentorshipUI.plumStroke.cgColor
        return view
    }()

    private let glassView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialLight)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        return view
    }()

    private let glassTintView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MentorshipUI.softSurface
        return view
    }()

    private let glassStrokeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        view.isUserInteractionEnabled = false
        return view
    }()

    private let imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
        view.backgroundColor = CineMystTheme.plumMist
        return view
    }()

    private let mentorImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        return iv
    }()

    private let accentOrbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        view.layer.cornerRadius = 14
        return view
    }()

    private let accentOrbInnerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MentorshipUI.brandPlum
        view.layer.cornerRadius = 5
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Upcoming"
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = MentorshipUI.softText
        return label
    }()

    private let statusPillView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let mentorNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = MentorshipUI.brandPlum
        return label
    }()

    private let areaLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let dateIconView = BookingCardCell.makeIconView(systemName: "calendar")
    private let timeIconView = BookingCardCell.makeIconView(systemName: "clock")

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let areaIconView = BookingCardCell.makeIconView(systemName: "tag")
    private lazy var areaRow = makeInfoRow(icon: areaIconView, label: areaLabel, tinted: true)

    private lazy var dateRow = makeInfoRow(icon: dateIconView, label: dateLabel, tinted: false)
    private lazy var timeRow = makeInfoRow(icon: timeIconView, label: timeLabel, tinted: false)
    private lazy var titleRow: UIStackView = {
        let spacer = UIView()
        let stack = UIStackView(arrangedSubviews: [mentorNameLabel, spacer, statusPillView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    private lazy var detailsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleRow, areaRow, dateRow, timeRow])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(glassView)
        glassView.contentView.addSubview(glassTintView)
        glassView.contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(mentorImageView)
        imageContainerView.addSubview(accentOrbView)
        accentOrbView.addSubview(accentOrbInnerView)
        glassView.contentView.addSubview(detailsStack)
        glassView.contentView.addSubview(statusPillView)
        statusPillView.contentView.addSubview(statusLabel)
        cardView.addSubview(glassStrokeView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            glassView.topAnchor.constraint(equalTo: cardView.topAnchor),
            glassView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            glassTintView.topAnchor.constraint(equalTo: glassView.contentView.topAnchor),
            glassTintView.leadingAnchor.constraint(equalTo: glassView.contentView.leadingAnchor),
            glassTintView.trailingAnchor.constraint(equalTo: glassView.contentView.trailingAnchor),
            glassTintView.bottomAnchor.constraint(equalTo: glassView.contentView.bottomAnchor),

            glassStrokeView.topAnchor.constraint(equalTo: cardView.topAnchor),
            glassStrokeView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            glassStrokeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            glassStrokeView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            imageContainerView.topAnchor.constraint(equalTo: glassView.contentView.topAnchor, constant: 16),
            imageContainerView.leadingAnchor.constraint(equalTo: glassView.contentView.leadingAnchor, constant: 16),
            imageContainerView.widthAnchor.constraint(equalToConstant: 64),
            imageContainerView.heightAnchor.constraint(equalToConstant: 64),
            imageContainerView.bottomAnchor.constraint(lessThanOrEqualTo: glassView.contentView.bottomAnchor, constant: -16),

            mentorImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 4),
            mentorImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 4),
            mentorImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -4),
            mentorImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -4),

            accentOrbView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -6),
            accentOrbView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -6),
            accentOrbView.widthAnchor.constraint(equalToConstant: 22),
            accentOrbView.heightAnchor.constraint(equalToConstant: 22),

            accentOrbInnerView.centerXAnchor.constraint(equalTo: accentOrbView.centerXAnchor),
            accentOrbInnerView.centerYAnchor.constraint(equalTo: accentOrbView.centerYAnchor),
            accentOrbInnerView.widthAnchor.constraint(equalToConstant: 8),
            accentOrbInnerView.heightAnchor.constraint(equalToConstant: 8),

            detailsStack.topAnchor.constraint(equalTo: glassView.contentView.topAnchor, constant: 16),
            detailsStack.leadingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: 16),
            detailsStack.trailingAnchor.constraint(equalTo: glassView.contentView.trailingAnchor, constant: -16),
            detailsStack.bottomAnchor.constraint(lessThanOrEqualTo: glassView.contentView.bottomAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: statusPillView.contentView.topAnchor, constant: 5),
            statusLabel.leadingAnchor.constraint(equalTo: statusPillView.contentView.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: statusPillView.contentView.trailingAnchor, constant: -10),
            statusLabel.bottomAnchor.constraint(equalTo: statusPillView.contentView.bottomAnchor, constant: -5)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentImageURLString = nil
        mentorImageView.image = UIImage(systemName: "person.crop.square")
        mentorImageView.tintColor = .systemGray3
        mentorImageView.contentMode = .scaleAspectFit
        mentorImageView.backgroundColor = .clear
    }

    func configure(with session: SessionM) {
        mentorNameLabel.text = session.mentorName
        areaLabel.text = session.mentorshipArea?.isEmpty == false ? session.mentorshipArea : "Mentorship area not available"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: session.date)

        if let scheduledTimeText = session.scheduledTimeText, !scheduledTimeText.isEmpty {
            timeLabel.text = scheduledTimeText
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            timeLabel.text = timeFormatter.string(from: session.date)
        }

        applyImage(for: session)
    }

    private static func makeIconView(systemName: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: systemName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = MentorshipUI.softText
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 14),
            imageView.heightAnchor.constraint(equalToConstant: 14)
        ])
        return imageView
    }

    private func makeInfoRow(icon: UIImageView, label: UILabel, tinted: Bool) -> UIView {
        let rowBackground = UIView()
        rowBackground.translatesAutoresizingMaskIntoConstraints = false
        rowBackground.layer.cornerRadius = 12
        rowBackground.backgroundColor = tinted
            ? MentorshipUI.plumChip
            : MentorshipUI.softSurface

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        rowBackground.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: rowBackground.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: rowBackground.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: rowBackground.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: rowBackground.bottomAnchor, constant: -8)
        ])

        return rowBackground
    }

    private func applyImage(for session: SessionM) {
        currentImageURLString = session.mentorImageURL
        let hasRemoteImage = !(session.mentorImageURL?.isEmpty ?? true)
        let shouldUseLocalFallback = !hasRemoteImage && !session.mentorImageName.isEmpty && session.mentorImageName != "Image"

        if shouldUseLocalFallback, let image = UIImage(named: session.mentorImageName) {
            mentorImageView.image = image
            mentorImageView.contentMode = .scaleAspectFit
            mentorImageView.backgroundColor = .clear
        } else {
            mentorImageView.image = UIImage(systemName: "person.crop.square")
            mentorImageView.tintColor = .systemGray3
            mentorImageView.contentMode = .scaleAspectFit
            mentorImageView.backgroundColor = .clear
        }

        guard let urlStrRaw = session.mentorImageURL, !urlStrRaw.isEmpty else { return }

        var candidateURLs: [URL] = []
        if let u = URL(string: urlStrRaw) { candidateURLs.append(u) }
        if let esc = urlStrRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let u2 = URL(string: esc) {
            candidateURLs.append(u2)
        }
        if !urlStrRaw.contains("://"), let u3 = URL(string: "https://\(urlStrRaw)") {
            candidateURLs.append(u3)
        }

        for url in candidateURLs {
            let key = NSString(string: url.absoluteString)
            if let cached = Self.imageCache.object(forKey: key) {
                mentorImageView.image = cached
                return
            }
        }

        Task {
            for url in candidateURLs {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    Self.imageCache.setObject(image, forKey: NSString(string: url.absoluteString))
                    await MainActor.run {
                        guard self.currentImageURLString == session.mentorImageURL else { return }
                        self.mentorImageView.image = image
                        self.mentorImageView.contentMode = .scaleAspectFit
                        self.mentorImageView.backgroundColor = .clear
                    }
                    return
                }
            }
        }
    }
}

// MARK: - Gradient Wordmark View
private final class GradientWordmarkView: UIView {
    private let text: String
    private let sizingLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    private let textLayer = CATextLayer()

    init(text: String) {
        self.text = text
        super.init(frame: .zero)

        let font = UIFont.systemFont(ofSize: 26, weight: .bold)
        let leadingFont = UIFont.systemFont(ofSize: 30, weight: .bold)
        sizingLabel.text = text
        sizingLabel.font = font

        gradientLayer.colors = [
            CineMystTheme.deepPlum.cgColor,
            CineMystTheme.brandPlum.cgColor,
            CineMystTheme.pink.cgColor
        ]
        gradientLayer.locations = [0, 0.55, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: font
            ]
        )
        if !text.isEmpty {
            attributed.addAttribute(.font, value: leadingFont, range: NSRange(location: 0, length: 1))
            attributed.addAttribute(.baselineOffset, value: -1, range: NSRange(location: 0, length: 1))
        }
        textLayer.string = attributed
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .left
        textLayer.truncationMode = .none
        textLayer.isWrapped = false

        layer.addSublayer(gradientLayer)
        gradientLayer.mask = textLayer

        layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.22).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let baseSize = sizingLabel.intrinsicContentSize
        return CGSize(width: ceil(baseSize.width + 10), height: ceil(max(baseSize.height, 34)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        textLayer.frame = bounds
    }
}

// MARK: - MentorshipHomeViewController
final class MentorshipHomeViewController: UIViewController {

    private let plum = MentorshipUI.brandPlum
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowTop = UIView()
    private let ambientGlowBottom = UIView()
    var initialSegmentIndex: Int = 0
    private static let mentorCachePrefix = "mentor_profile_exists_"
    private static let mentorIdsCachePrefix = "mentor_profile_ids_"
    private let defaultHomeMentorLimit = 4
    private let compactHomeMentorLimit = 2

    // UI elements
    private lazy var titleLabel: UIView = {
        let v = GradientWordmarkView(text: "Mentorship")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Discover & learn from your mentor"
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = MentorshipUI.mutedText
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Mentee", "Mentor"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentTintColor = MentorshipUI.brandPlum
        sc.backgroundColor = MentorshipUI.softSurface
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.layer.cornerRadius = 18
        sc.layer.masksToBounds = true
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return sc
    }()

    private let emptyIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = CineMystTheme.plumHaze
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = MentorshipUI.mutedText
        l.numberOfLines = 2
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emptyStateContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let mentorsLabel: UILabel = {
        let l = UILabel()
        l.text = "Mentors"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let seeAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See all", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Become Mentor button (top-right)
    private lazy var becomeMentorButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Become Mentor", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.backgroundColor = MentorshipUI.deepPlum
        b.layer.cornerRadius = 16
        b.layer.shadowColor = MentorshipUI.shadow.cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius = 16
        b.layer.shadowOffset = CGSize(width: 0, height: 10)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapBecomeMentor), for: .touchUpInside)
        b.alpha = 0.0
        b.isHidden = true
        return b
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        cv.register(MentorCell.self, forCellWithReuseIdentifier: MentorCell.reuseIdentifier)
        return cv
    }()

    // mentors loaded from Supabase
    private var allMentors: [Mentor] = []
    private var mentors: [Mentor] = []
    private var currentUserMentorProfileIds: [String] = []

    // bookings for current user
    private var menteeBookings: [SessionM] = []
    private var mentorBookings: [SessionM] = []

    // bookings header / container (inserted above mentors list when mentee has bookings)
    private let bookingsContainer: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isHidden = true
        return s
    }()

    private let bookingsTitle: UILabel = {
        let l = UILabel()
        l.text = "Your booking"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bookingsTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false
        return tv
    }()
    private var bookingsTableHeightConstraint: NSLayoutConstraint?
    private var mentorsTopToEmptyConstraint: NSLayoutConstraint?
    private var mentorsTopToBookingsConstraint: NSLayoutConstraint?
    private var emptyLabelTopToIconConstraint: NSLayoutConstraint?
    private var emptyLabelTopToContainerConstraint: NSLayoutConstraint?

    // DTO matching mentor_profiles table
    private struct MentorRecord: Codable {
        let id: String?
        let user_id: String?
        let display_name: String?
        let name: String?
        let role: String?
        let rating: Double?
        let mentorship_areas: [String]?
        let profile_picture_url: String?
        let metadata: String?

        var displayName: String? { display_name ?? name }
        var imageURL: String? { profile_picture_url }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            user_id = try container.decodeIfPresent(String.self, forKey: .user_id)
            display_name = try container.decodeIfPresent(String.self, forKey: .display_name)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            role = try container.decodeIfPresent(String.self, forKey: .role)
            rating = try container.decodeIfPresent(Double.self, forKey: .rating)
            profile_picture_url = try container.decodeIfPresent(String.self, forKey: .profile_picture_url)
            metadata = try container.decodeIfPresent(String.self, forKey: .metadata)

            if let arr = try container.decodeIfPresent([String].self, forKey: .mentorship_areas) {
                mentorship_areas = arr
            } else if let raw = try container.decodeIfPresent(String.self, forKey: .mentorship_areas) {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("["),
                   let data = trimmed.data(using: .utf8),
                   let arr = try? JSONDecoder().decode([String].self, from: data) {
                    mentorship_areas = arr
                } else if trimmed.isEmpty {
                    mentorship_areas = nil
                } else {
                    mentorship_areas = [trimmed]
                }
            } else {
                mentorship_areas = nil
            }
        }
    }

    private struct MentorshipSessionRecord: Codable {
        let id: String
        let mentor_id: String
        let mentee_id: String?
        let scheduled_at: String
        let created_at: String?
        let status: String?
        let notes: String?
    }

    private struct ProfileRecord: Codable {
        let id: String
        let full_name: String?
        let username: String?
        let avatar_url: String?
        let profile_picture_url: String?

        var displayName: String {
            if let full_name, !full_name.isEmpty { return full_name }
            if let username, !username.isEmpty { return username }
            return "Mentee"
        }

        var imageURL: String? { profile_picture_url ?? avatar_url }
    }

    private struct CurrentProfileRecord: Codable {
        let id: String
        let full_name: String?
        let username: String?
        let avatar_url: String?
        let profile_picture_url: String?
    }

    private struct MentorSessionCountRecord: Codable {
        let session: Double?
    }

    // lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MentorshipUI.pageBackground
        setupBackground()
        subtitleLabel.textColor = MentorshipUI.mutedText
        mentorsLabel.textColor = MentorshipUI.brandPlum
        bookingsTitle.textColor = MentorshipUI.brandPlum
        seeAllButton.setTitleColor(MentorshipUI.brandPlum, for: .normal)
        segmentControl.selectedSegmentIndex = initialSegmentIndex

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(segmentControl)
        view.addSubview(emptyStateContainer)
        emptyStateContainer.addSubview(emptyIcon)
        emptyStateContainer.addSubview(emptyLabel)
        view.addSubview(mentorsLabel)
        view.addSubview(seeAllButton)
        view.addSubview(bookingsContainer)
        bookingsContainer.addArrangedSubview(bookingsTitle)
        bookingsContainer.addArrangedSubview(bookingsTable)
        view.addSubview(collectionView)
        view.addSubview(becomeMentorButton)

        collectionView.dataSource = self
        collectionView.delegate = self
        bookingsTable.dataSource = self
        bookingsTable.delegate = self
        bookingsTable.register(BookingCardCell.self, forCellReuseIdentifier: BookingCardCell.reuseIdentifier)
        bookingsTable.separatorStyle = .none
        bookingsTable.backgroundColor = .clear
        bookingsTable.showsVerticalScrollIndicator = false
        bookingsTable.sectionHeaderHeight = 0
        bookingsTable.sectionFooterHeight = 0
        bookingsTable.contentInset = .zero

        seeAllButton.addTarget(self, action: #selector(didTapSeeAll), for: .touchUpInside)

        setupConstraints()
        configureEmptyState(forIndex: segmentControl.selectedSegmentIndex)
        applyCachedMentorStatusIfAvailable()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSessionStoreUpdated),
                                               name: .sessionUpdated,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        // load mentors from backend
        Task {
            await loadMentorsFromSupabase()
            reloadSessions()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowTop.layer.cornerRadius = ambientGlowTop.bounds.width / 2
        ambientGlowBottom.layer.cornerRadius = ambientGlowBottom.bounds.width / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1).cgColor,
            CineMystTheme.plumMist.cgColor,
            UIColor(red: 0.936, green: 0.892, blue: 0.917, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.45, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)

        ambientGlowTop.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.16)
        ambientGlowTop.layer.shadowColor = CineMystTheme.brandPlum.cgColor
        ambientGlowTop.layer.shadowOpacity = 0.22
        ambientGlowTop.layer.shadowRadius = 80
        ambientGlowTop.layer.shadowOffset = .zero

        ambientGlowBottom.backgroundColor = CineMystTheme.deepPlumMid.withAlphaComponent(0.11)
        ambientGlowBottom.layer.shadowColor = CineMystTheme.deepPlumMid.cgColor
        ambientGlowBottom.layer.shadowOpacity = 0.16
        ambientGlowBottom.layer.shadowRadius = 90
        ambientGlowBottom.layer.shadowOffset = .zero

        [ambientGlowTop, ambientGlowBottom].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ambientGlowTop.widthAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.heightAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.topAnchor.constraint(equalTo: view.topAnchor, constant: -42),
            ambientGlowTop.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 72),

            ambientGlowBottom.widthAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.heightAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -82),
            ambientGlowBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 42)
        ])
    }

    // Public: reload sessions & bookings (used after booking flow)
    func reloadSessions() {
        Task { await fetchBookingsForCurrentUser() }
    }

    // Fetch bookings for current user as mentee and as mentor
    private func fetchBookingsForCurrentUser() async {
        do {
            // get current user id from session
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let mentorProfileIds = try await resolveCurrentMentorProfileIds(for: userId, email: session.user.email)

            // fetch sessions where mentee_id = userId
            let menteeRes = try await supabase
                .from("mentorship_sessions")
                .select("id, mentor_id, mentee_id, scheduled_at, created_at, status, notes")
                .eq("mentee_id", value: userId)
                .execute()

            let menteeSessions = try JSONDecoder().decode([MentorshipSessionRecord].self, from: menteeRes.data)
            let activeMenteeSessions = menteeSessions.filter {
                let status = ($0.status ?? "").lowercased()
                return status != "cancelled" && status != "canceled"
            }
            let mentorIds = Array(Set(activeMenteeSessions.map(\.mentor_id)))

            var mentorMap: [String: MentorRecord] = [:]
            if !mentorIds.isEmpty {
                let mentorRes = try await supabase
                    .from("mentor_profiles")
                    .select("id, display_name, name, role, rating, profile_picture_url")
                    .in("id", values: mentorIds)
                    .execute()

                let mentorRecords = try JSONDecoder().decode([MentorRecord].self, from: mentorRes.data)
                mentorMap = Dictionary(uniqueKeysWithValues: mentorRecords.compactMap { record in
                    guard let id = record.id else { return nil }
                    return (id, record)
                })
            }

            let fetchedMentee: [SessionM] = activeMenteeSessions.compactMap { record in
                guard let date = Self.parseISODate(record.scheduled_at, using: iso) else { return nil }
                let created = Self.parseISODate(record.created_at, using: iso) ?? date
                let mentor = mentorMap[record.mentor_id]
                return SessionM(
                    id: record.id,
                    mentorId: record.mentor_id,
                    mentorName: mentor?.displayName ?? "Mentor session",
                    mentorRole: mentor?.role,
                    date: date,
                    createdAt: created,
                    mentorImageName: "",
                    mentorImageURL: mentor?.imageURL,
                    mentorshipArea: record.notes ?? mentor?.mentorship_areas?.first,
                    scheduledTimeText: nil
                )
            }

            // fetch sessions where mentor_id = userId
            let mentorSessions: [MentorshipSessionRecord]
            if mentorProfileIds.isEmpty {
                mentorSessions = []
            } else {
                let mentorRes = try await supabase
                    .from("mentorship_sessions")
                    .select("id, mentor_id, mentee_id, scheduled_at, created_at, status, notes")
                    .in("mentor_id", values: mentorProfileIds)
                    .execute()
                mentorSessions = try JSONDecoder().decode([MentorshipSessionRecord].self, from: mentorRes.data)
            }
            let activeMentorSessions = mentorSessions.filter {
                let status = ($0.status ?? "").lowercased()
                return status != "cancelled" && status != "canceled"
            }
            let menteeIds = Array(Set(activeMentorSessions.compactMap(\.mentee_id)))

            var profileMap: [String: ProfileRecord] = [:]
            if !menteeIds.isEmpty {
                let profileRes = try await supabase
                    .from("profiles")
                    .select("id, full_name, username, avatar_url, profile_picture_url")
                    .in("id", values: menteeIds)
                    .execute()

                let profiles = try JSONDecoder().decode([ProfileRecord].self, from: profileRes.data)
                profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            }

            let fetchedMentor: [SessionM] = activeMentorSessions.compactMap { record in
                guard let date = Self.parseISODate(record.scheduled_at, using: iso) else { return nil }
                let created = Self.parseISODate(record.created_at, using: iso) ?? date
                let mentee = record.mentee_id.flatMap { profileMap[$0] }
                return SessionM(
                    id: record.id,
                    mentorId: record.mentor_id,
                    mentorName: mentee?.displayName ?? "Mentee booking",
                    mentorRole: nil,
                    date: date,
                    createdAt: created,
                    mentorImageName: "",
                    mentorImageURL: mentee?.imageURL,
                    mentorshipArea: record.notes,
                    scheduledTimeText: nil
                )
            }

            await MainActor.run {
                self.menteeBookings = self.mergeLocalSessions(into: fetchedMentee).sorted { $0.date < $1.date }
                self.mentorBookings = fetchedMentor.sorted { $0.date < $1.date }
                self.updateBookingsUI()
            }
        } catch {
            print("[MentorshipHome] fetchBookingsForCurrentUser error: \(error)")
            Task { @MainActor in
                self.menteeBookings = self.mergeLocalSessions(into: [])
                self.updateBookingsUI()
            }
        }
    }

    private func updateBookingsUI() {
        // Decide which bookings to show depending on selected segment
        let showingMentee = (segmentControl.selectedSegmentIndex == 0)
        let bookings = showingMentee ? menteeBookings : mentorBookings
        let hasBookings = !bookings.isEmpty

        bookingsTitle.text = showingMentee ? "Your booking" : "Booked sessions"

        if hasBookings {
            bookingsContainer.isHidden = false
            emptyStateContainer.isHidden = true
            mentorsTopToBookingsConstraint?.isActive = true
            mentorsTopToEmptyConstraint?.isActive = false
        } else {
            bookingsContainer.isHidden = true
            emptyStateContainer.isHidden = false
            let showIcon = !showingMentee
            emptyIcon.isHidden = !showIcon
            emptyLabelTopToIconConstraint?.isActive = showIcon
            emptyLabelTopToContainerConstraint?.isActive = !showIcon
            mentorsTopToBookingsConstraint?.isActive = false
            mentorsTopToEmptyConstraint?.isActive = true
        }

        bookingsTable.reloadData()
        let rowCount = bookings.count
        let rowHeight: CGFloat = 156
        bookingsTableHeightConstraint?.constant = CGFloat(rowCount) * rowHeight
        refreshVisibleMentors()
        view.layoutIfNeeded()
    }

    private func refreshVisibleMentors() {
        let shouldCompact = !currentBookings().isEmpty
        let limit = shouldCompact ? compactHomeMentorLimit : defaultHomeMentorLimit
        mentors = Array(allMentors.prefix(limit))
        collectionView.reloadData()
    }

    // MARK: - Networking
    private func loadMentorsFromSupabase() async {
        let fetched = await MentorsProvider.fetchAll()
        await MainActor.run {
            self.allMentors = fetched
            self.refreshVisibleMentors()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await refreshCurrentMentorStatus()
            await fetchBookingsForCurrentUser()
            await MainActor.run {
                self.updateBecomeMentorVisibility(animated: false)
            }
        }
    }

    // layout
    private func setupConstraints() {
        let pagePadding: CGFloat = 20

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pagePadding),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pagePadding),

            segmentControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            segmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentControl.widthAnchor.constraint(equalToConstant: 220),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            emptyStateContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 22),
            emptyStateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),
            emptyStateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pagePadding),

            emptyIcon.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor, constant: 4),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 8),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -8),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyStateContainer.bottomAnchor),

            bookingsContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            bookingsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),
            bookingsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pagePadding),
            mentorsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),

            seeAllButton.centerYAnchor.constraint(equalTo: mentorsLabel.centerYAnchor),
            seeAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pagePadding),

            collectionView.topAnchor.constraint(equalTo: mentorsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            becomeMentorButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            becomeMentorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            becomeMentorButton.heightAnchor.constraint(equalToConstant: 32),
            becomeMentorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        // bookings table height default (0 when no bookings)
        bookingsTableHeightConstraint = bookingsTable.heightAnchor.constraint(equalToConstant: 0)
        bookingsTableHeightConstraint?.isActive = true
        mentorsTopToEmptyConstraint = mentorsLabel.topAnchor.constraint(equalTo: emptyStateContainer.bottomAnchor, constant: 26)
        mentorsTopToBookingsConstraint = mentorsLabel.topAnchor.constraint(equalTo: bookingsContainer.bottomAnchor, constant: 18)
        emptyLabelTopToIconConstraint = emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 10)
        emptyLabelTopToContainerConstraint = emptyLabel.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor)
        emptyLabelTopToContainerConstraint?.isActive = true
        mentorsTopToEmptyConstraint?.isActive = true
    }

    // empty state
    private func configureEmptyState(forIndex index: Int) {
        if index == 0 {
            emptyIcon.image = nil
            emptyLabel.text = "No session booked yet."
        } else {
            emptyIcon.image = UIImage(systemName: "phone.fill")
            emptyLabel.text = "No bookings yet. Become a mentor, once a mentee schedules a session, you'll see it here."
        }
    }

    // actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        UIView.transition(with: emptyIcon, duration: 0.18, options: .transitionCrossDissolve, animations: {
            self.configureEmptyState(forIndex: sender.selectedSegmentIndex)
        }, completion: nil)

        updateBecomeMentorVisibility(animated: true)
        updateBookingsUI()
    }

    private func updateBecomeMentorVisibility(animated: Bool) {
        let shouldShow = (segmentControl.selectedSegmentIndex == 1) && currentUserMentorProfileIds.isEmpty
        let changes = {
            self.becomeMentorButton.isHidden = !shouldShow
            self.becomeMentorButton.alpha = shouldShow ? 1.0 : 0.0
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func didTapBecomeMentor() {
        let vc = BecomeMentorViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapSeeAll() {
        let vc = AllMentorsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleSessionStoreUpdated() {
        if segmentControl.selectedSegmentIndex == 0 {
            menteeBookings = mergeLocalSessions(into: menteeBookings).sorted { $0.date < $1.date }
        }
        updateBookingsUI()
    }

    @objc private func handleAppDidBecomeActive() {
        reloadSessions()
    }

    private static func parseISODate(_ raw: String?, using formatter: ISO8601DateFormatter) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        if let date = formatter.date(from: raw) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        let fallback = formatter.date(from: raw)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fallback
    }

    private func mergeLocalSessions(into remoteSessions: [SessionM]) -> [SessionM] {
        var merged = remoteSessions
        let existingKeys = Set(remoteSessions.map { bookingDedupKey(for: $0) })

        for session in SessionStore.shared.all() {
            let key = bookingDedupKey(for: session)
            if existingKeys.contains(key) { continue }
            merged.append(session)
        }

        return merged
    }

    private func bookingDedupKey(for session: SessionM) -> String {
        let time = Int(session.date.timeIntervalSince1970)
        return "\(session.mentorId)|\(time)"
    }

    private func currentBookings() -> [SessionM] {
        segmentControl.selectedSegmentIndex == 0 ? menteeBookings : mentorBookings
    }

    private func removeBookingLocally(_ session: SessionM) {
        if segmentControl.selectedSegmentIndex == 0 {
            menteeBookings.removeAll { $0.id == session.id }
        } else {
            mentorBookings.removeAll { $0.id == session.id }
        }
        SessionStore.shared.remove(id: session.id)
        updateBookingsUI()
    }

    private func cancelBooking(_ session: SessionM) {
        Task {
            do {
                try await supabase
                    .from("mentorship_sessions")
                    .update(["status": "canceled"])
                    .eq("id", value: session.id)
                    .execute()

                await decrementMentorSessionCount(for: session.mentorId)

                await MainActor.run {
                    self.removeBookingLocally(session)
                }
            } catch {
                print("[MentorshipHome] cancel booking error: \(error)")
                await MainActor.run {
                    self.removeBookingLocally(session)
                }
            }
        }
    }

    private func decrementMentorSessionCount(for mentorId: String) async {
        do {
            let res = try await supabase
                .from("mentor_profiles")
                .select("session")
                .eq("id", value: mentorId)
                .single()
                .execute()

            let record = try JSONDecoder().decode(MentorSessionCountRecord.self, from: res.data)
            let current = Int(record.session ?? 0)
            let next = max(0, current - 1)

            try await supabase
                .from("mentor_profiles")
                .update(["session": next])
                .eq("id", value: mentorId)
                .execute()

            print("[MentorshipHome] decremented mentor_profiles.session for mentor_id=\(mentorId) to \(next)")
        } catch {
            print("[MentorshipHome] decrement mentor session count failed: \(error)")
        }
    }

    private func resolveCurrentMentorProfileIds(for userId: String, email: String? = nil) async throws -> [String] {
        let directRes = try await supabase
            .from("mentor_profiles")
            .select("id, user_id, display_name, name, role, rating, profile_picture_url")
            .eq("user_id", value: userId)
            .execute()

        let directRecords = try JSONDecoder().decode([MentorRecord].self, from: directRes.data)
        let directIds = directRecords.compactMap(\.id)
        if !directIds.isEmpty {
            return directIds
        }

        let profileRes = try await supabase
            .from("profiles")
            .select("id, full_name, username, avatar_url, profile_picture_url")
            .eq("id", value: userId)
            .single()
            .execute()

        let profile = try JSONDecoder().decode(CurrentProfileRecord.self, from: profileRes.data)
        var rawCandidates = [profile.full_name, profile.username]
        if let email, let emailPrefix = email.split(separator: "@").first.map(String.init), !emailPrefix.isEmpty {
            rawCandidates.append(emailPrefix)
        }

        let candidateNames = rawCandidates.compactMap { raw -> String? in
            guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
            return value
        }
        let normalizedCandidates = Set(candidateNames.map(Self.normalizeIdentity))
        let candidateImageURLs = [profile.avatar_url, profile.profile_picture_url]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for candidate in candidateNames {
            let displayRes = try await supabase
                .from("mentor_profiles")
                .select("id, user_id, display_name, name, role, rating, profile_picture_url")
                .eq("display_name", value: candidate)
                .execute()

            let displayRecords = try JSONDecoder().decode([MentorRecord].self, from: displayRes.data)
            let displayIds = displayRecords.compactMap(\.id)
            if !displayIds.isEmpty {
                try? await supabase
                    .from("mentor_profiles")
                    .update(["user_id": userId])
                    .eq("id", value: displayIds[0])
                    .execute()
                return displayIds
            }

            let nameRes = try await supabase
                .from("mentor_profiles")
                .select("id, user_id, display_name, name, role, rating, profile_picture_url")
                .eq("name", value: candidate)
                .execute()

            let nameRecords = try JSONDecoder().decode([MentorRecord].self, from: nameRes.data)
            let nameIds = nameRecords.compactMap(\.id)
            if !nameIds.isEmpty {
                try? await supabase
                    .from("mentor_profiles")
                    .update(["user_id": userId])
                    .eq("id", value: nameIds[0])
                    .execute()
                return nameIds
            }
        }

        let batchRes = try await supabase
            .from("mentor_profiles")
            .select("id, user_id, display_name, name, role, rating, profile_picture_url")
            .limit(200)
            .execute()

        let batchRecords = try JSONDecoder().decode([MentorRecord].self, from: batchRes.data)
        let fuzzyMatches = batchRecords.filter { record in
            let possibleNames = [record.display_name, record.name].compactMap { value -> String? in
                guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return Self.normalizeIdentity(value)
            }
            return possibleNames.contains { possibleName in
                normalizedCandidates.contains { candidate in
                    possibleName == candidate || possibleName.contains(candidate) || candidate.contains(possibleName)
                }
            }
        }

        let fuzzyIds = fuzzyMatches.compactMap(\.id)
        if !fuzzyIds.isEmpty {
            for fuzzyId in fuzzyIds {
                try? await supabase
                    .from("mentor_profiles")
                    .update(["user_id": userId])
                    .eq("id", value: fuzzyId)
                    .execute()
            }
            return fuzzyIds
        }

        if !candidateImageURLs.isEmpty {
            let imageMatches = batchRecords.filter { record in
                guard let profileURL = record.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !profileURL.isEmpty else { return false }
                return candidateImageURLs.contains { candidateURL in
                    profileURL == candidateURL ||
                    profileURL.removingPercentEncoding == candidateURL.removingPercentEncoding
                }
            }

            let imageIds = imageMatches.compactMap(\.id)
            if !imageIds.isEmpty {
                for imageId in imageIds {
                    try? await supabase
                        .from("mentor_profiles")
                        .update(["user_id": userId])
                        .eq("id", value: imageId)
                        .execute()
                }
                return imageIds
            }
        }

        let cachedIds = Self.cachedMentorProfileIds(for: userId)
        if !cachedIds.isEmpty {
            return cachedIds
        }

        return []
    }

    private func refreshCurrentMentorStatus() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            var mentorIds = try await resolveCurrentMentorProfileIds(for: userId, email: session.user.email)

            if mentorIds.isEmpty {
                let cachedIds = Self.cachedMentorProfileIds(for: userId)
                if !cachedIds.isEmpty {
                    for mentorId in cachedIds {
                        try? await supabase
                            .from("mentor_profiles")
                            .update(["user_id": userId])
                            .eq("id", value: mentorId)
                            .execute()
                    }
                    mentorIds = try await resolveCurrentMentorProfileIds(for: userId, email: session.user.email)
                    if mentorIds.isEmpty {
                        mentorIds = cachedIds
                    }
                }
            }

            await MainActor.run {
                if !mentorIds.isEmpty {
                    UserDefaults.standard.set(true, forKey: Self.mentorCacheKey(for: userId))
                    Self.cacheMentorProfileIds(mentorIds, for: userId)
                    self.currentUserMentorProfileIds = mentorIds
                } else if UserDefaults.standard.bool(forKey: Self.mentorCacheKey(for: userId)) {
                    self.currentUserMentorProfileIds = Self.cachedMentorProfileIds(for: userId)
                } else {
                    self.currentUserMentorProfileIds = []
                }
            }
        } catch {
            print("[MentorshipHome] refreshCurrentMentorStatus error: \(error)")
            await MainActor.run {
                self.applyCachedMentorStatusIfAvailable()
            }
        }
    }

    private func applyCachedMentorStatusIfAvailable() {
        Task {
            guard let session = try? await supabase.auth.session else { return }
            let cachedIsMentor = UserDefaults.standard.bool(forKey: Self.mentorCacheKey(for: session.user.id.uuidString))
            await MainActor.run {
                self.currentUserMentorProfileIds = cachedIsMentor ? Self.cachedMentorProfileIds(for: session.user.id.uuidString) : []
                self.updateBecomeMentorVisibility(animated: false)
            }
        }
    }

    private static func mentorCacheKey(for userId: String) -> String {
        mentorCachePrefix + userId
    }

    private static func mentorIdsCacheKey(for userId: String) -> String {
        mentorIdsCachePrefix + userId
    }

    private static func cacheMentorProfileIds(_ ids: [String], for userId: String) {
        UserDefaults.standard.set(ids, forKey: mentorIdsCacheKey(for: userId))
    }

    private static func cachedMentorProfileIds(for userId: String) -> [String] {
        UserDefaults.standard.stringArray(forKey: mentorIdsCacheKey(for: userId)) ?? []
    }

    private static func normalizeIdentity(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

}

// MARK: - Collection DataSource & Delegate
extension MentorshipHomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mentors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MentorCell.reuseIdentifier, for: indexPath) as? MentorCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: mentors[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 160, height: 208)
        }
        let insets = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let width = floor((collectionView.bounds.width - insets - spacing) / 2.0)
        let height = ceil(94 + (width - 16) * 0.85)
        return CGSize(width: width, height: height)
    }

    // <-- here we push BookViewController and pass the mentor -->
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let mentor = mentors[indexPath.item]

        // instantiate BookViewController (from your file)
        let detailVC = BookViewController()
        detailVC.mentor = mentor

        // hide the tab bar when this view controller is pushed
        detailVC.hidesBottomBarWhenPushed = true

        // push if we have a navigationController (your TabBar already embeds this VC into a UINavigationController)
        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            // fallback: present modally wrapped inside a nav controller so user gets a back button
            let nav = UINavigationController(rootViewController: detailVC)
            present(nav, animated: true, completion: nil)
        }
    }

}

// MARK: - Bookings Table DataSource
extension MentorshipHomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentControl.selectedSegmentIndex == 0 ? menteeBookings.count : mentorBookings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookingCardCell.reuseIdentifier, for: indexPath) as? BookingCardCell else {
            return UITableViewCell()
        }
        let session = segmentControl.selectedSegmentIndex == 0 ? menteeBookings[indexPath.row] : mentorBookings[indexPath.row]
        cell.configure(with: session)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        172
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = currentBookings()[indexPath.row]
        let cancelAction = UIContextualAction(style: .destructive, title: "Cancel") { [weak self] _, _, completion in
            self?.cancelBooking(session)
            completion(true)
        }
        cancelAction.backgroundColor = UIColor(red: 0x8B/255, green: 0x2E/255, blue: 0x46/255, alpha: 1)
        let configuration = UISwipeActionsConfiguration(actions: [cancelAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
