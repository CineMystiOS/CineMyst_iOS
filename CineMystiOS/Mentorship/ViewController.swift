//
//  BookViewController.swift
//  CineMystApp
//
//  Created by You on Today.
//

import UIKit
import Supabase

// Codable DTO matchingit is  selected columns from `mentor_profiles` table
private struct MentorDetailRecord: Codable {
    let id: String?
    let displayName: String?
    let about: String?
    // DB column is text[] (array of strings)
    let mentorshipAreas: [String]?
    let rating: Double?
    let ratingCount: Int?
    let profilePictureUrl: String?
    // optional raw metadata JSON we may extract from the raw row
    var metadataJson: String?
    // direct columns on mentor_profiles
    let yoe: Double?
    let session: Int?
}

private struct ReviewRecord: Codable {
    let id: String?
    let authorName: String?
    let createdAt: String?
    let rating: Int?
    let content: String?
    let avatarUrl: String?
}

final class BookViewController: UIViewController {
    private let plum = MentorshipUI.brandPlum

    // Public property - set before presenting/pushing
    var mentor: Mentor? {
        didSet { applyMentorIfNeeded() }
    }

    // Detailed record loaded from the backend (optional)
    private var mentorDetail: MentorDetailRecord?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bottomActionContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        v.layer.borderColor = MentorshipUI.plumStroke.cgColor
        v.layer.borderWidth = 1
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Image")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let headerOverlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()
    private static let imageCache = NSCache<NSString, UIImage>()
    private var headerHeightConstraint: NSLayoutConstraint?

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = MentorshipUI.deepPlum
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = MentorshipUI.brandPlum.withAlphaComponent(0.78)
        l.textAlignment = .center
        return l
    }()

    // starsView is a placeholder stack we can update when mentor is set
    private var starsView: UIStackView = {
        starStack(rating: 4.0, max: 5, size: 16)
    }()

    private let reviewsCountLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
    l.isHidden = true // hide reviews count per request
        return l
    }()

    // Mutable stat labels so we can replace static values from backend
    private let yearExpValueLabel = UILabel()
    private let mentorStatValueLabel = UILabel()
    private let sessionsValueLabel = UILabel()

    // Reviews container populated from backend
    private lazy var reviewsStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        return v
    }()

    private let rolePillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MentorshipUI.plumChip
        view.layer.cornerRadius = 14
        return view
    }()

    private func statBlock(title: String, value: String) -> UIStackView {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let v = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 4
        v.layoutMargins = .init(top: 8, left: 12, bottom: 8, right: 12)
        v.isLayoutMarginsRelativeArrangement = true
        v.backgroundColor = MentorshipUI.softSurface
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = MentorshipUI.plumStroke.cgColor
        return v
    }

    private lazy var statsRow: UIStackView = {
        // create stat blocks using the stored value labels so we can update them later
        func makeBlock(title: String, valueLabel: UILabel) -> UIStackView {
            valueLabel.text = ""
            valueLabel.font = .systemFont(ofSize: 20, weight: .semibold)
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 12)
            titleLabel.textColor = .secondaryLabel
            titleLabel.textAlignment = .center
            let v = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
            v.axis = .vertical
            v.alignment = .center
            v.spacing = 4
            v.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)
            v.isLayoutMarginsRelativeArrangement = true
            v.backgroundColor = UIColor.white.withAlphaComponent(0.86)
            v.layer.cornerRadius = 20
            v.layer.shadowColor = MentorshipUI.shadow.cgColor
            v.layer.shadowOpacity = 1
            v.layer.shadowOffset = CGSize(width: 0, height: 12)
            v.layer.shadowRadius = 22
            v.layer.borderWidth = 1
            v.layer.borderColor = MentorshipUI.plumStroke.cgColor
            return v
        }

        let s1 = makeBlock(title: "Year Exp", valueLabel: yearExpValueLabel)
        let s2 = makeBlock(title: "Services", valueLabel: mentorStatValueLabel)
        let s3 = makeBlock(title: "Sessions", valueLabel: sessionsValueLabel)

        yearExpValueLabel.translatesAutoresizingMaskIntoConstraints = false
        mentorStatValueLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionsValueLabel.translatesAutoresizingMaskIntoConstraints = false

        let h = UIStackView(arrangedSubviews: [s1, s2, s3])
        h.axis = .horizontal
        h.distribution = .fillEqually
        h.spacing = 12
        return h
    }()

    private let aboutTitle: UILabel = sectionTitle("About")
    private let aboutText: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14)
        l.text = ""
        return l
    }()

    private let mentorshipTitle: UILabel = sectionTitle("Mentorship Area")
    private let mentorshipText: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14)
        l.text = ""
        return l
    }()

    private let reviewsTitle: UILabel = sectionTitle("Reviews")

    // moreReviewsButton removed as it's no longer required

    private let bookButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Book Session"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = MentorshipUI.deepPlum
        config.baseForegroundColor = .white
        let b = UIButton(configuration: config)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.configurationUpdateHandler = { button in
            button.configuration?.baseBackgroundColor = button.isHighlighted
                ? MentorshipUI.deepPlum.withAlphaComponent(0.85)
                : MentorshipUI.deepPlum
        }
        return b
    }()
    private func makeSectionCard(titleLabel: UILabel, bodyView: UIView, iconName: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        card.layer.cornerRadius = 24
        card.layer.shadowColor = MentorshipUI.shadow.cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 10)
        card.layer.shadowRadius = 22
        card.layer.borderWidth = 1
        card.layer.borderColor = MentorshipUI.plumStroke.cgColor

        let accentBar = UIView()
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.backgroundColor = MentorshipUI.deepPlumMid.withAlphaComponent(0.28)
        accentBar.layer.cornerRadius = 2

        let iconBadge = UIView()
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.backgroundColor = MentorshipUI.plumChip
        iconBadge.layer.cornerRadius = 14

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = plum
        iconView.contentMode = .scaleAspectFit
        iconBadge.addSubview(iconView)

        let titleRow = UIStackView(arrangedSubviews: [iconBadge, titleLabel, UIView()])
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10

        let stack = UIStackView(arrangedSubviews: [titleRow, bodyView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14

        card.addSubview(stack)
        card.addSubview(accentBar)
        NSLayoutConstraint.activate([
            accentBar.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            accentBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            accentBar.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        NSLayoutConstraint.activate([
            iconBadge.widthAnchor.constraint(equalToConstant: 28),
            iconBadge.heightAnchor.constraint(equalToConstant: 28),

            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14)
        ])
        return card
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MentorshipUI.pageBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        navigationController?.navigationBar.isTranslucent = true

        // DO NOT show the nav title over the image
        navigationItem.title = ""
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationController?.navigationBar.topItem?.title = ""
        }

        setupLayout()
        bookButton.addTarget(self, action: #selector(didTapBookSession), for: .touchUpInside)
        applyMentorIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide tab bar (if this VC was pushed with hidesBottomBarWhenPushed = true it will be hidden automatically)
        tabBarController?.tabBar.isHidden = true
        // Hide the floating button if our tab bar controller is CineMystTabBarController
       

        // Transparent navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore tab bar and floating button
        tabBarController?.tabBar.isHidden = false
      
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerHeightConstraint?.constant = 260 + view.safeAreaInsets.top
        if let gradient = headerOverlayView.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = headerOverlayView.bounds
        }
    }

    // MARK: Actions
    @objc private func didTapBookSession() {
    let vc = ScheduleSessionViewController()
    vc.mentor = self.mentor
        // prefer detailed mentor areas if available
        if let detail = mentorDetail, let areas = detail.mentorshipAreas {
            vc.allowedAreas = areas
        } else if let m = mentor, let areas = m.mentorshipAreas {
            vc.allowedAreas = areas
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        view.addSubview(bottomActionContainer)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomActionContainer.topAnchor)
        ])

        NSLayoutConstraint.activate([
            bottomActionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomActionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomActionContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomActionContainer.heightAnchor.constraint(equalToConstant: 96)
        ])

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Header image
        contentView.addSubview(headerImageView)
        headerImageView.addSubview(headerOverlayView)
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerHeightConstraint = headerImageView.heightAnchor.constraint(equalToConstant: 260)
        headerHeightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            headerOverlayView.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerOverlayView.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerOverlayView.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            headerOverlayView.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor)
        ])

        // Card container
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        card.layer.cornerRadius = 30
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.layer.shadowColor = MentorshipUI.shadow.cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: -6)
        card.layer.shadowRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = MentorshipUI.plumStroke.cgColor
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -24),
            card.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        // Stacks
        rolePillView.addSubview(roleLabel)
        rolePillView.layer.borderWidth = 1
        rolePillView.layer.borderColor = MentorshipUI.plumStroke.cgColor
        NSLayoutConstraint.activate([
            roleLabel.topAnchor.constraint(equalTo: rolePillView.topAnchor, constant: 6),
            roleLabel.leadingAnchor.constraint(equalTo: rolePillView.leadingAnchor, constant: 12),
            roleLabel.trailingAnchor.constraint(equalTo: rolePillView.trailingAnchor, constant: -12),
            roleLabel.bottomAnchor.constraint(equalTo: rolePillView.bottomAnchor, constant: -6)
        ])

        let headerStack = UIStackView(arrangedSubviews: [nameLabel, rolePillView])
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 10

        let aboutCard = makeSectionCard(titleLabel: aboutTitle, bodyView: aboutText, iconName: "text.alignleft")
        let mentorshipCard = makeSectionCard(titleLabel: mentorshipTitle, bodyView: mentorshipText, iconName: "sparkles")

        let mainStack = UIStackView(arrangedSubviews: [headerStack, statsRow, aboutCard, mentorshipCard])
        mainStack.axis = .vertical
        mainStack.spacing = 22

        card.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        let cardGlow = CAGradientLayer()
        cardGlow.colors = [
            UIColor.white.withAlphaComponent(0.28).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        cardGlow.locations = [0.0, 0.35, 1.0]
        cardGlow.startPoint = CGPoint(x: 0.5, y: 0.0)
        cardGlow.endPoint = CGPoint(x: 0.5, y: 1.0)
        cardGlow.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 180)
        let glowView = UIView()
        glowView.translatesAutoresizingMaskIntoConstraints = false
        glowView.isUserInteractionEnabled = false
        glowView.layer.cornerRadius = 30
        glowView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        glowView.clipsToBounds = true
        glowView.layer.insertSublayer(cardGlow, at: 0)
        card.insertSubview(glowView, at: 0)
        NSLayoutConstraint.activate([
            glowView.topAnchor.constraint(equalTo: card.topAnchor),
            glowView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            glowView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            glowView.heightAnchor.constraint(equalToConstant: 180)
        ])

        // Bottom Book button
        bottomActionContainer.addSubview(bookButton)
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookButton.leadingAnchor.constraint(equalTo: bottomActionContainer.leadingAnchor, constant: 20),
            bookButton.trailingAnchor.constraint(equalTo: bottomActionContainer.trailingAnchor, constant: -20),
            bookButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bookButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // Called when mentor is set (and after view loads)
    private func applyMentorIfNeeded() {
        guard isViewLoaded else { return }
        applyMentor()
    }

    private func applyMentor() {
        guard let mentor = mentor else { return }

        // DO NOT set navigation title here (we previously did `title = mentor.name` which caused the label on the image).
        // Keep the name inside the card only:
        nameLabel.text = mentor.name
        roleLabel.text = mentor.role
        headerOverlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.01).cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor,
            UIColor.black.withAlphaComponent(0.52).cgColor
        ]
        gradient.locations = [0.0, 0.45, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = headerOverlayView.bounds
        headerOverlayView.layer.addSublayer(gradient)

        updateStarsView(with: normalizedDisplayRating(mentor.rating))

        if let imgName = mentor.imageName, let img = UIImage(named: imgName) {
            headerImageView.image = img
            headerImageView.contentMode = .scaleAspectFill
        } else {
            headerImageView.image = UIImage(systemName: "person.crop.rectangle")
            headerImageView.tintColor = .systemGray3
            headerImageView.contentMode = .center
        }

    // Fetch additional mentor details (prefer id when available)
    Task { await fetchMentorDetailsIfNeeded(mentorId: mentor.id, byName: mentor.name) }
    }

    // MARK: - Networking / Supabase
    private func fetchMentorDetailsIfNeeded(mentorId: String?, byName mentorName: String) async {
        // Already loaded
        if mentorDetail != nil { return }
        do {
            print("[MentorDetail] fetching details for: \(mentorName) id=\(String(describing: mentorId))")
            // If we have id, prefer fetching by id
            if let id = mentorId {
                let resId = try await supabase.database
                    .from("mentor_profiles")
                    .select("id,display_name,about,mentorship_areas,rating,rating_count,profile_picture_url,metadata,yoe,session")
                    .eq("id", value: id)
                    .execute()
                print("[MentorDetail] by-id response data=\(String(describing: resId.data))")
                if let rowsId = try rowsArray(from: resId.data), !rowsId.isEmpty {
                    if let firstRaw = rowsId.first as? [String: Any] {
                        var mdJson: String? = nil
                        if let meta = firstRaw["metadata"] {
                            if let s = meta as? String { mdJson = s }
                            else if let d = try? JSONSerialization.data(withJSONObject: meta), let s = String(data: d, encoding: .utf8) { mdJson = s }
                        }
                        let dataId = try JSONSerialization.data(withJSONObject: [firstRaw])
                        let decoderId = JSONDecoder()
                        decoderId.keyDecodingStrategy = .convertFromSnakeCase
                        let detailsId = try decoderId.decode([MentorDetailRecord].self, from: dataId)
                        if var first = detailsId.first {
                            first.metadataJson = mdJson
                            mentorDetail = first
                            await applyMentorDetail(first)
                            return
                        }
                    }
                }
            }

            print("[MentorDetail] fetching details for: \(mentorName)")
            // Try by display_name first
            let res = try await supabase.database
                .from("mentor_profiles")
                .select("id,display_name,about,mentorship_areas,rating,rating_count,profile_picture_url,metadata,yoe,session")
                .eq("display_name", value: mentorName)
                .execute()

            print("[MentorDetail] response data=\(String(describing: res.data))")

            if let rows = try rowsArray(from: res.data), !rows.isEmpty {
                if let firstRaw = rows.first as? [String: Any] {
                    var mdJson: String? = nil
                    if let meta = firstRaw["metadata"] {
                        if let s = meta as? String { mdJson = s }
                        else if let d = try? JSONSerialization.data(withJSONObject: meta), let s = String(data: d, encoding: .utf8) { mdJson = s }
                    }
                    let data = try JSONSerialization.data(withJSONObject: [firstRaw])
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let details = try decoder.decode([MentorDetailRecord].self, from: data)
                    if var first = details.first {
                        first.metadataJson = mdJson
                        mentorDetail = first
                        await applyMentorDetail(first)
                        return
                    }
                }
            }
            else {
                print("[MentorDetail] no rows for display_name=\(mentorName)")
            }
            // Fallback: try a name column if different
            let res2 = try await supabase.database
                .from("mentor_profiles")
                .select("id,display_name,about,mentorship_areas,rating,rating_count,profile_picture_url,metadata,yoe,session")
                .eq("name", value: mentorName)
                .execute()

            print("[MentorDetail] fallback response data=\(String(describing: res2.data))")

            if let rows2 = try rowsArray(from: res2.data), !rows2.isEmpty {
                if let firstRaw = rows2.first as? [String: Any] {
                    var mdJson: String? = nil
                    if let meta = firstRaw["metadata"] {
                        if let s = meta as? String { mdJson = s }
                        else if let d = try? JSONSerialization.data(withJSONObject: meta), let s = String(data: d, encoding: .utf8) { mdJson = s }
                    }
                    let data = try JSONSerialization.data(withJSONObject: [firstRaw])
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let details = try decoder.decode([MentorDetailRecord].self, from: data)
                    if var first = details.first {
                        first.metadataJson = mdJson
                        mentorDetail = first
                        await applyMentorDetail(first)
                    }
                }
            } else {
                print("[MentorDetail] no rows for name=\(mentorName)")
                // Final fallback: fetch a batch and try a case-insensitive local match
                let resAll = try await supabase.database
                    .from("mentor_profiles")
                    .select("id,display_name,about,mentorship_areas,rating,rating_count,profile_picture_url,metadata,yoe,session")
                    .limit(100)
                    .execute()
                print("[MentorDetail] fallback batch data=\(String(describing: resAll.data))")
                if let rowsAll = try rowsArray(from: resAll.data), !rowsAll.isEmpty {
                    // Debug: print display_name and about for each row to help diagnose mismatches
                    for (i, raw) in rowsAll.enumerated() {
                        if let dict = raw as? [String: Any] {
                            let dn = dict["display_name"] as? String ?? dict["name"] as? String ?? "(no name)"
                            let about = dict["about"] as? String ?? "(no about)"
                            print("[MentorDetail][batch][\(i)] display_name=\(dn), about=\(about.prefix(80))")
                        } else {
                            print("[MentorDetail][batch][\(i)] raw=\(raw)")
                        }
                    }
                    
                    // Try to find a match by inspecting any string field in each row
                    for raw in rowsAll {
                        if let dict = raw as? [String: Any] {
                            // check any string value for a case-insensitive containment
                            let lcTarget = mentorName.lowercased()
                            var matches = false
                            for (_, v) in dict {
                                if let s = v as? String, s.lowercased().contains(lcTarget) {
                                    matches = true
                                    break
                                }
                                // handle array of strings (text[])
                                if let arr = v as? [String] {
                                    for item in arr {
                                        if item.lowercased().contains(lcTarget) { matches = true; break }
                                    }
                                    if matches { break }
                                }
                            }
                                    if matches {
                                        // decode this single row into MentorDetailRecord
                                        let rowData = try JSONSerialization.data(withJSONObject: dict)
                                        let decoder = JSONDecoder()
                                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                                        var foundDetail = try decoder.decode(MentorDetailRecord.self, from: rowData)
                                        if let meta = dict["metadata"] {
                                            if let s = meta as? String { foundDetail.metadataJson = s }
                                            else if let d = try? JSONSerialization.data(withJSONObject: meta), let s = String(data: d, encoding: .utf8) { foundDetail.metadataJson = s }
                                        }
                                        mentorDetail = foundDetail
                                        await applyMentorDetail(foundDetail)
                                        return
                                    }
                        }
                    }
                }
                // Nothing matched - inform user in UI
                await MainActor.run {
                    if self.aboutText.text?.isEmpty ?? true { self.aboutText.text = "Profile not found for \(mentorName)" }
                }
            }
        } catch {
            print("[MentorDetail] error fetching mentor details: \(error)")
            await MainActor.run {
                if self.aboutText.text?.isEmpty ?? true { self.aboutText.text = "Could not load profile." }
                if self.mentorshipText.text?.isEmpty ?? true { self.mentorshipText.text = "" }
            }
            return
        }
    }

    private func applyMentorDetail(_ detail: MentorDetailRecord) async {
        await MainActor.run {
            if let about = detail.about, !about.isEmpty {
                self.aboutText.text = about
            }
            if let areas = detail.mentorshipAreas, !areas.isEmpty {
                self.mentorshipText.text = areas.joined(separator: ", ")
                self.mentorStatValueLabel.text = "\(areas.count)"
            } else if let areas = self.mentor?.mentorshipAreas, !areas.isEmpty {
                self.mentorStatValueLabel.text = "\(areas.count)"
            } else {
                self.mentorStatValueLabel.text = "1"
            }
            if let count = detail.ratingCount {
                self.reviewsCountLabel.text = "\(count) reviews"
            }

            // Prefer direct columns (yoe, session) from the mentor_profiles table; fall back to metadata JSON
            if let y = detail.yoe {
                // yoe is numeric (Double) in the table
                let intY = Int(y)
                self.yearExpValueLabel.text = "\(intY)"
            } else if let md = detail.metadataJson, !md.isEmpty, let data = md.data(using: .utf8) {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let yearKeys = ["years", "years_experience", "yearsOfExperience", "experience", "years_of_experience", "yearsexperience", "yearsExperience", "years_exp"]
                    var yearVal: Int? = nil
                    for k in yearKeys {
                        if let v = obj[k] as? Int { yearVal = v; break }
                        if let s = obj[k] as? String, let iv = Int(s) { yearVal = iv; break }
                        if let d = obj[k] as? Double { yearVal = Int(d); break }
                    }
                    if let yv = yearVal { self.yearExpValueLabel.text = "\(yv)" }
                }
            }

            if let s = detail.session {
                self.sessionsValueLabel.text = "\(s)"
            } else if let md = detail.metadataJson, !md.isEmpty, let data = md.data(using: .utf8) {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let sessionsKeys = ["sessions", "session_count", "sessions_count", "total_sessions", "totalSessions"]
                    var sessionsVal: Int? = nil
                    for k in sessionsKeys {
                        if let v = obj[k] as? Int { sessionsVal = v; break }
                        if let s = obj[k] as? String, let iv = Int(s) { sessionsVal = iv; break }
                        if let d = obj[k] as? Double { sessionsVal = Int(d); break }
                    }
                    if let sv = sessionsVal { self.sessionsValueLabel.text = "\(sv)" }
                }
            }
        }

    if let urlString = detail.profilePictureUrl, let _ = URL(string: urlString) {
            if let cached = BookViewController.imageCache.object(forKey: NSString(string: urlString)) {
                await MainActor.run { self.headerImageView.image = cached; self.headerImageView.contentMode = .scaleAspectFill }
            } else {
                if let img = await downloadImage(from: urlString) {
                    BookViewController.imageCache.setObject(img, forKey: NSString(string: urlString))
                    await MainActor.run { self.headerImageView.image = img; self.headerImageView.contentMode = .scaleAspectFill }
                }
            }
        }

        // Populate stats: sessions count and mentor rating
        if let mentorId = detail.id {
            Task {
                print("[MentorDetail] fetching sessions/reviews for mentorId=\(mentorId)")
                let sessionsCount = await fetchSessionsCount(for: mentorId)
                print("[MentorDetail] sessionsCount=\(sessionsCount)")
                await MainActor.run {
                    if sessionsCount > 0 {
                            // update the sessions stat label text inside the blocks
                            self.sessionsValueLabel.text = "\(sessionsCount)"
                            // also ensure the reviews count label is populated
                            self.reviewsCountLabel.text = detail.ratingCount != nil ? "\(detail.ratingCount!) reviews" : self.reviewsCountLabel.text
                    }
                }

                let reviews = await fetchRecentReviews(for: mentorId, limit: 3)
                print("[MentorDetail] reviews fetched count=\(reviews.count)")
                await MainActor.run {
                    // Clear existing assembled review views
                    while !self.reviewsStack.arrangedSubviews.isEmpty {
                        let v = self.reviewsStack.arrangedSubviews[0]
                        self.reviewsStack.removeArrangedSubview(v)
                        v.removeFromSuperview()
                    }
                    for r in reviews {
                        let avatarImg = UIImage(systemName: "person.circle")
                        let rv = reviewView(avatar: avatarImg,
                                            name: r.authorName ?? "",
                                            timeAgo: r.createdAt ?? "",
                                            rating: r.rating ?? 0,
                                            text: r.content ?? "")
                        self.reviewsStack.addArrangedSubview(rv)
                    }
                    if reviews.isEmpty {
                        let empty = UILabel()
                        empty.text = "No reviews yet"
                        empty.font = .systemFont(ofSize: 13)
                        empty.textColor = .secondaryLabel
                        self.reviewsStack.addArrangedSubview(empty)
                    }
                }
            }
        }
    }

    private func fetchSessionsCount(for mentorId: String) async -> Int {
        do {
            let res = try await supabase.database
                .from("mentorship_sessions")
                .select("id")
                .eq("mentor_id", value: mentorId)
                .execute()
            print("[fetchSessionsCount] res.data=\(String(describing: res.data))")
            if let rows = res.data as? [Any] {
                return rows.count
            }
        } catch {
            print("[fetchSessionsCount] error: \(error)")
            return 0
        }
        return 0
    }

    private func fetchRecentReviews(for mentorId: String, limit: Int = 3) async -> [ReviewRecord] {
        do {
            // select all columns to be tolerant to schema differences; we'll extract needed fields
            let res = try await supabase.database
                .from("session_reviews")
                .select()
                .eq("mentor_id", value: mentorId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            print("[fetchRecentReviews] res.data=\(String(describing: res.data))")

            if let rows = try rowsArray(from: res.data), !rows.isEmpty {
                // Build ReviewRecord objects manually from dictionaries to tolerate column name mismatches
                var result: [ReviewRecord] = []
                for r in rows {
                    if let dict = r as? [String: Any] {
                        let id = dict["id"] as? String
                        // tolerant keys: author_name or authorName
                        let author = (dict["author_name"] as? String) ?? (dict["authorName"] as? String) ?? (dict["author"] as? String)
                        let created = (dict["created_at"] as? String) ?? (dict["createdAt"] as? String)
                        let rating = dict["rating"] as? Int ?? (dict["rating"] as? Int)
                        let content = (dict["content"] as? String) ?? (dict["body"] as? String)
                        let avatar = (dict["avatar_url"] as? String) ?? (dict["avatarUrl"] as? String)
                        let rr = ReviewRecord(id: id, authorName: author, createdAt: created, rating: rating, content: content, avatarUrl: avatar)
                        result.append(rr)
                    }
                }
                return result
            }
        } catch {
            print("[fetchRecentReviews] error: \(error)")
            return []
        }
        return []
    }

    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func updateStarsView(with rating: Double) {
        // clear existing arranged subviews
        while !starsView.arrangedSubviews.isEmpty {
            let v = starsView.arrangedSubviews[0]
            starsView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        let new = starStack(rating: rating, max: 5, size: 16)
        for v in new.arrangedSubviews {
            starsView.addArrangedSubview(v)
        }
    }

    private func normalizedDisplayRating(_ rating: Double) -> Double {
        rating > 0.01 ? rating : 4.0
    }
}

// MARK: - Helpers
private func sectionTitle(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 16, weight: .semibold)
    l.textColor = .label
    return l
}

private func starStack(rating: Double, max: Int, size: CGFloat = 14) -> UIStackView {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 2
    stack.alignment = .center

    let full = Int(rating.rounded(.down))
    let hasHalf = (rating - Double(full)) >= 0.25 && (rating - Double(full)) < 0.75

    for i in 0..<max {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemYellow
        if i < full {
            iv.image = UIImage(systemName: "star.fill")
        } else if i == full && hasHalf {
            iv.image = UIImage(systemName: "star.leadinghalf.filled")
        } else {
            iv.image = UIImage(systemName: "star")
            iv.tintColor = .tertiaryLabel
        }
        iv.widthAnchor.constraint(equalToConstant: size).isActive = true
        iv.heightAnchor.constraint(equalToConstant: size).isActive = true
        stack.addArrangedSubview(iv)
    }
    return stack
}

private func reviewView(avatar: UIImage?, name: String, timeAgo: String, rating: Int, text: String) -> UIView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 6
    container.alignment = .leading

    let topRow = UIStackView()
    topRow.axis = .horizontal
    topRow.alignment = .center
    topRow.spacing = 8

    let avatarView = UIImageView(image: avatar)
    avatarView.contentMode = .scaleAspectFill
    avatarView.tintColor = .secondaryLabel
    avatarView.layer.cornerRadius = 16
    avatarView.clipsToBounds = true
    avatarView.widthAnchor.constraint(equalToConstant: 32).isActive = true
    avatarView.heightAnchor.constraint(equalToConstant: 32).isActive = true

    let nameLabel = UILabel()
    nameLabel.text = name
    nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)

    let timeLabel = UILabel()
    timeLabel.text = timeAgo
    timeLabel.font = .systemFont(ofSize: 12)
    timeLabel.textColor = .secondaryLabel

    let nameTime = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
    nameTime.axis = .vertical
    nameTime.spacing = 2

    topRow.addArrangedSubview(avatarView)
    topRow.addArrangedSubview(nameTime)

    let stars = starStack(rating: Double(rating), max: 5, size: 14)

    let textLabel = UILabel()
    textLabel.numberOfLines = 0
    textLabel.font = .systemFont(ofSize: 13)
    textLabel.text = text

    container.addArrangedSubview(topRow)
    container.addArrangedSubview(stars)
    container.addArrangedSubview(textLabel)
    return container
}

// Normalize response.data into an array of Any for decoding. Supabase client's PostgrestResponse.data
// can sometimes be already an array of dictionaries or raw JSON data; this helper handles both.
private func rowsArray(from raw: Any?) throws -> [Any]? {
    guard let raw = raw else { return nil }
    // If it's already an array, return it
    if let arr = raw as? [Any] { return arr }
    // If it's Data representing JSON, try to decode
    if let data = raw as? Data {
        let json = try JSONSerialization.jsonObject(with: data)
        if let arr = json as? [Any] { return arr }
    }
    // If it's a string of JSON, attempt to parse
    if let s = raw as? String, let data = s.data(using: .utf8) {
        let json = try JSONSerialization.jsonObject(with: data)
        if let arr = json as? [Any] { return arr }
    }
    return nil
}
