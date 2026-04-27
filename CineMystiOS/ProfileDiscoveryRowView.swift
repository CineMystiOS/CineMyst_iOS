//
//  ProfileDiscoveryRowView.swift
//  CineMystiOS
//
//  Horizontal draggable strip of mini profile cards revealed when the user
//  taps "Discover Profiles" on their own profile card.
//

import UIKit
import Supabase

// MARK: - Discovery Profile Model

struct DiscoveryProfile {
    let id: UUID
    let fullName: String?
    let username: String?
    let role: String?
    let profilePictureUrl: String?
    let location: String?
}

// MARK: - Mini Profile Card Cell

final class DiscoveryMiniCardCell: UICollectionViewCell {

    static let reuseId = "DiscoveryMiniCardCell"

    // MARK: Subviews

    private let cardBg: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius  = 12
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarRing: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 32
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode  = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 28
        iv.layer.borderWidth  = 2
        iv.layer.borderColor  = UIColor.white.cgColor
        iv.backgroundColor    = UIColor(hex: "#F5E8F0")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 13, weight: .bold)
        l.textColor     = UIColor(hex: "#431631")
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 11, weight: .medium)
        l.textColor     = .gray
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 10, weight: .regular)
        l.textColor     = UIColor(hex: "#CD72A8")
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let viewBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View", for: .normal)
        b.setTitleColor(UIColor(hex: "#431631"), for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        b.backgroundColor = UIColor(hex: "#431631").withAlphaComponent(0.08)
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor(hex: "#431631").withAlphaComponent(0.15).cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: Ring gradient

    private let ringGradient = CAGradientLayer()

    // MARK: Callback

    var onViewTapped: (() -> Void)?

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Setup

    private func setupUI() {
        contentView.addSubview(cardBg)

        // Gradient ring behind avatar
        ringGradient.colors     = [UIColor(hex: "#431631").cgColor, UIColor(hex: "#CD72A8").cgColor]
        ringGradient.startPoint = CGPoint(x: 0, y: 0)
        ringGradient.endPoint   = CGPoint(x: 1, y: 1)
        ringGradient.cornerRadius = 32
        avatarRing.layer.addSublayer(ringGradient)
        
        cardBg.addSubview(avatarRing)
        cardBg.addSubview(avatarImageView)
        cardBg.addSubview(nameLabel)
        cardBg.addSubview(roleLabel)
        cardBg.addSubview(locationLabel)
        cardBg.addSubview(viewBtn)

        viewBtn.addTarget(self, action: #selector(viewTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardBg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardBg.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 4),
            cardBg.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -4),
            cardBg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatarRing.topAnchor.constraint(equalTo: cardBg.topAnchor, constant: 14),
            avatarRing.centerXAnchor.constraint(equalTo: cardBg.centerXAnchor),
            avatarRing.widthAnchor.constraint(equalToConstant: 64),
            avatarRing.heightAnchor.constraint(equalToConstant: 64),

            avatarImageView.centerXAnchor.constraint(equalTo: avatarRing.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 56),
            avatarImageView.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.topAnchor.constraint(equalTo: avatarRing.bottomAnchor, constant: 10),
            nameLabel.leftAnchor.constraint(equalTo: cardBg.leftAnchor, constant: 8),
            nameLabel.rightAnchor.constraint(equalTo: cardBg.rightAnchor, constant: -8),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            roleLabel.leftAnchor.constraint(equalTo: cardBg.leftAnchor, constant: 8),
            roleLabel.rightAnchor.constraint(equalTo: cardBg.rightAnchor, constant: -8),

            locationLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 3),
            locationLabel.leftAnchor.constraint(equalTo: cardBg.leftAnchor, constant: 8),
            locationLabel.rightAnchor.constraint(equalTo: cardBg.rightAnchor, constant: -8),

            viewBtn.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            viewBtn.centerXAnchor.constraint(equalTo: cardBg.centerXAnchor),
            viewBtn.widthAnchor.constraint(equalToConstant: 64),
            viewBtn.heightAnchor.constraint(equalToConstant: 28),
            viewBtn.bottomAnchor.constraint(lessThanOrEqualTo: cardBg.bottomAnchor, constant: -12),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ringGradient.frame = avatarRing.bounds
    }

    // MARK: Configure

    func configure(with profile: DiscoveryProfile) {
        let display  = profile.fullName ?? profile.username ?? "Unknown"
        nameLabel.text     = display.count > 16 ? String(display.prefix(14)) + "…" : display
        roleLabel.text     = profile.role ?? "Filmmaker"

        locationLabel.attributedText = nil
        let loc = profile.location ?? ""
        let city = loc.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? loc
        if city.isEmpty {
            locationLabel.text = ""
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
            if let pinIcon = UIImage(systemName: "mappin.and.ellipse", withConfiguration: config)?.withTintColor(UIColor(hex: "#CD72A8"), renderingMode: .alwaysOriginal) {
                let attachment = NSTextAttachment()
                attachment.image = pinIcon
                attachment.bounds = CGRect(x: 0, y: -1, width: 9, height: 9)
                let attrStr = NSMutableAttributedString(attachment: attachment)
                attrStr.append(NSAttributedString(string: " \(city)"))
                locationLabel.attributedText = attrStr
            } else {
                locationLabel.text = "📍 \(city)"
            }
        }
        
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = UIColor(hex: "#CD72A8")

        if let urlStr = profile.profilePictureUrl, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.avatarImageView.image = img }
            }.resume()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.cardBg.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                    : .identity
                self.cardBg.alpha = self.isHighlighted ? 0.85 : 1
            }
        }
    }

    @objc private func viewTapped() {
        onViewTapped?()
    }
}

// MARK: - Profile Discovery Row View

final class ProfileDiscoveryRowView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: Properties

    private var profiles: [DiscoveryProfile] = []
    private var loadTask: Task<Void, Never>?
    var onProfileSelected: ((DiscoveryProfile) -> Void)?
    var onSeeAllTapped: (() -> Void)?

    // MARK: Subviews

    private let headerStack: UIStackView = {
        let s = UIStackView()
        s.axis      = .horizontal
        s.spacing   = 8
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text      = "Discover Profiles"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(hex: "#431631")
        return l
    }()

    private let sparkIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor   = UIColor(hex: "#CD72A8")
        iv.contentMode = .scaleAspectFit
        iv.widthAnchor.constraint(equalToConstant: 16).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return iv
    }()

    private let seeAllBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See All", for: .normal)
        b.setTitleColor(UIColor(hex: "#CD72A8"), for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let collectionContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection       = .horizontal
        layout.itemSize              = CGSize(width: 140, height: 200)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing    = 8
        layout.sectionInset          = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor       = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(DiscoveryMiniCardCell.self, forCellWithReuseIdentifier: DiscoveryMiniCardCell.reuseId)
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        // iOS-native spring deceleration feel
        cv.decelerationRate = .fast
        return cv
    }()

    private let shimmerContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text      = "No profiles found nearby ✨"
        l.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = .gray
        l.textAlignment = .center
        l.isHidden  = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addShimmerCards()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        loadTask?.cancel()
    }

    // MARK: Setup

    private func setupUI() {
        backgroundColor    = UIColor(hex: "#FAF0F6")
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        headerStack.addArrangedSubview(sparkIcon)
        headerStack.addArrangedSubview(headerLabel)
        
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerStack)
        headerContainer.addSubview(seeAllBtn)
        addSubview(headerContainer)
        
        addSubview(shimmerContainer)
        
        collectionContainer.addSubview(collectionView)
        addSubview(collectionContainer)
        
        addSubview(emptyLabel)

        seeAllBtn.addTarget(self, action: #selector(seeAllClicked), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerContainer.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            headerContainer.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            headerContainer.heightAnchor.constraint(equalToConstant: 24),
            
            headerStack.leftAnchor.constraint(equalTo: headerContainer.leftAnchor),
            headerStack.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            seeAllBtn.rightAnchor.constraint(equalTo: headerContainer.rightAnchor),
            seeAllBtn.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            shimmerContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            shimmerContainer.leftAnchor.constraint(equalTo: leftAnchor),
            shimmerContainer.rightAnchor.constraint(equalTo: rightAnchor),
            shimmerContainer.heightAnchor.constraint(equalToConstant: 200),

            collectionContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            collectionContainer.leftAnchor.constraint(equalTo: leftAnchor),
            collectionContainer.rightAnchor.constraint(equalTo: rightAnchor),
            collectionContainer.heightAnchor.constraint(equalToConstant: 210),
            collectionContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            collectionView.topAnchor.constraint(equalTo: collectionContainer.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: collectionContainer.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: collectionContainer.rightAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: collectionContainer.centerYAnchor),
        ])

        collectionView.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add scroll edge fade to the stationary container
        if collectionContainer.layer.mask == nil {
            let maskLayer = CAGradientLayer()
            maskLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.cgColor,
                UIColor.black.cgColor,
                UIColor.clear.cgColor
            ]
            // Sharp fade on the left, softer fade on right edge
            maskLayer.locations = [0.0, 0.05, 0.95, 1.0]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
            collectionContainer.layer.mask = maskLayer
        }
        collectionContainer.layer.mask?.frame = collectionContainer.bounds
    }

    // MARK: Shimmer placeholders

    private func addShimmerCards() {
        let stack = UIStackView()
        stack.axis      = .horizontal
        stack.spacing   = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        shimmerContainer.addSubview(stack)

        for _ in 0..<4 {
            let card = makeShimmerCard()
            stack.addArrangedSubview(card)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: shimmerContainer.topAnchor),
            stack.leftAnchor.constraint(equalTo: shimmerContainer.leftAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: shimmerContainer.bottomAnchor),
        ])
        animateShimmer()
    }

    private func makeShimmerCard() -> UIView {
        let card = UIView()
        card.backgroundColor  = UIColor.white.withAlphaComponent(0.7)
        card.layer.cornerRadius = 18
        card.widthAnchor.constraint(equalToConstant: 132).isActive = true

        let circle = UIView()
        circle.backgroundColor  = UIColor(hex: "#F5E8F0")
        circle.layer.cornerRadius = 28
        circle.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(circle)

        let bar1 = shimmerBar(height: 10, width: 90)
        let bar2 = shimmerBar(height: 8,  width: 70)
        let bar3 = shimmerBar(height: 8,  width: 50)
        let barBtn = shimmerBar(height: 26, width: 60)
        barBtn.layer.cornerRadius = 13

        let vStack = UIStackView(arrangedSubviews: [bar1, bar2, bar3, barBtn])
        vStack.axis      = .vertical
        vStack.spacing   = 8
        vStack.alignment = .center
        vStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vStack)

        NSLayoutConstraint.activate([
            circle.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            circle.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            circle.widthAnchor.constraint(equalToConstant: 56),
            circle.heightAnchor.constraint(equalToConstant: 56),

            vStack.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 12),
            vStack.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 8),
            vStack.rightAnchor.constraint(equalTo: card.rightAnchor, constant: -8),
        ])
        return card
    }

    private func shimmerBar(height: CGFloat, width: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor   = UIColor(hex: "#F5E8F0")
        v.layer.cornerRadius = height / 2
        v.widthAnchor.constraint(equalToConstant: width).isActive  = true
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func animateShimmer() {
        let shimmerView = UIView(frame: .zero)
        shimmerView.backgroundColor = .clear
        shimmerContainer.addSubview(shimmerView)
        shimmerContainer.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.locations  = [0.35, 0.5, 0.65]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            gradient.frame = CGRect(x: -self.shimmerContainer.bounds.width,
                                    y: 0,
                                    width: self.shimmerContainer.bounds.width * 3,
                                    height: self.shimmerContainer.bounds.height)
            shimmerView.frame = self.shimmerContainer.bounds
            shimmerView.layer.addSublayer(gradient)

            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.fromValue    = -self.shimmerContainer.bounds.width
            animation.toValue      = self.shimmerContainer.bounds.width
            animation.duration     = 1.4
            animation.repeatCount  = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            gradient.add(animation, forKey: "shimmer")
        }
    }

    // MARK: Load Data

    func loadDiscoveryProfiles() {
        loadTask?.cancel()
        showLoadingState()

        guard let currentUserId = supabase.auth.currentUser?.id else {
            showEmptyState(message: "Complete sign-in to get suggestions.")
            return
        }

        loadTask = Task { [weak self] in
            do {
                let profiles = try await RecommendationsService.shared.fetchDiscoveryProfiles(for: currentUserId)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.applyLoadedProfiles(profiles)
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("❌ Failed to load discovery profiles: \(error)")
                await MainActor.run {
                    self?.showEmptyState(message: "No suggestions available yet.")
                }
            }
        }
    }

    private func showLoadingState() {
        profiles = []
        collectionView.reloadData()
        emptyLabel.isHidden = true
        shimmerContainer.isHidden = false
        shimmerContainer.alpha = 1
        collectionView.isHidden = true
    }

    private func applyLoadedProfiles(_ profiles: [DiscoveryProfile]) {
        self.profiles = profiles

        guard !profiles.isEmpty else {
            showEmptyState(message: "No suggestions available yet.")
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.shimmerContainer.alpha = 0
        } completion: { _ in
            self.shimmerContainer.isHidden = true
            self.shimmerContainer.alpha = 1
            self.collectionView.isHidden = false
            self.emptyLabel.isHidden = true
            self.collectionView.reloadData()
        }
    }

    private func showEmptyState(message: String) {
        emptyLabel.text = message
        emptyLabel.isHidden = false
        shimmerContainer.isHidden = true
        shimmerContainer.alpha = 1
        collectionView.isHidden = true
        profiles = []
        collectionView.reloadData()
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profiles.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DiscoveryMiniCardCell.reuseId,
            for: indexPath) as? DiscoveryMiniCardCell
        else { fatalError() }

        let profile = profiles[indexPath.item]
        cell.configure(with: profile)
        cell.onViewTapped = { [weak self] in
            self?.onProfileSelected?(profile)
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profile = profiles[indexPath.item]
        onProfileSelected?(profile)
    }

    @objc private func seeAllClicked() {
        onSeeAllTapped?()
    }
}
