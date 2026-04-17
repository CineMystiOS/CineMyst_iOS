//
//  ActorProfileViewController.swift
//  CineMystApp
//
//  Modern actor profile screen - #431631 × #CD72A8

import UIKit
import Supabase
import AVKit
import AVFoundation

// MARK: - Gradient Button Helper

class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func setupGradient(colors: [UIColor]) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - Design System

enum ActorProfileDS {
    static let deepPlum        = UIColor(hex: "#431631")
    static let rosePink        = UIColor(hex: "#CD72A8")
    static let midPlum         = UIColor(hex: "#6B2050")
    static let floatingPlumStart = UIColor(red: 0.38, green: 0.11, blue: 0.22, alpha: 1)
    static let floatingPlumEnd   = UIColor(red: 0.27, green: 0.08, blue: 0.17, alpha: 1)
    static let palePink        = UIColor(hex: "#F5E8F0")
    static let bgLight         = UIColor(hex: "#FAF0F6")

    static func gradient(colors: [UIColor]) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint   = CGPoint(x: 1, y: 1)
        return layer
    }
}

// MARK: - Actor Profile Card View

class ActorProfileCardView: UIView {

    let bannerImageView    = UIImageView()
    let profileImageView   = UIImageView()
    let nameLabel          = UILabel()
    let verifiedBadge      = UIImageView()
    let roleLabel          = UILabel()
    let connectionsButton  = UIButton(type: .system)
    let connectionsLabel   = UILabel()
    let editPortfolioButton = GradientButton(type: .system)
    let editProfileButton   = GradientButton(type: .system)   // own profile — edit details
    let connectButton       = GradientButton(type: .system)   // other users — connect
    let avatarEditButton    = UIButton(type: .system)          // pencil badge on own profile

    // Stored so layoutSubviews can resize them
    private let bannerGradientLayer = CAGradientLayer()
    private let ringGradientLayer   = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius  = 20
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius  = 12
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        layer.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false

        // Banner Image
        bannerImageView.contentMode  = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.backgroundColor = ActorProfileDS.palePink
        bannerImageView.layer.cornerRadius = 18
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerImageView)

        // Overlay gradient on banner
        bannerGradientLayer.colors     = [UIColor.clear.cgColor, ActorProfileDS.deepPlum.withAlphaComponent(0.3).cgColor]
        bannerGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        bannerGradientLayer.endPoint   = CGPoint(x: 0, y: 1)
        bannerImageView.layer.addSublayer(bannerGradientLayer)

        // Profile Image with Gradient Ring
        profileImageView.contentMode  = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth  = 5
        profileImageView.layer.borderColor  = UIColor.white.cgColor
        profileImageView.backgroundColor    = ActorProfileDS.palePink
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)

        // Gradient ring background
        let ringView = UIView()
        ringView.layer.cornerRadius = 68
        ringGradientLayer.colors     = [ActorProfileDS.floatingPlumStart.cgColor, ActorProfileDS.floatingPlumEnd.cgColor]
        ringGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        ringGradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        ringGradientLayer.cornerRadius = 68
        ringView.layer.addSublayer(ringGradientLayer)
        ringView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(ringView, belowSubview: profileImageView)

        // Avatar edit badge (pencil — only visible on own profile)
        configureEditBadge(avatarEditButton)
        addSubview(avatarEditButton)

        // Name Label
        nameLabel.font      = UIFont.systemFont(ofSize: 26, weight: .bold)
        nameLabel.textColor = ActorProfileDS.deepPlum
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Verified Badge
        verifiedBadge.image = UIImage(systemName: "checkmark.seal.fill")
        verifiedBadge.tintColor = .systemBlue
        verifiedBadge.contentMode = .scaleAspectFit
        verifiedBadge.isHidden = true
        verifiedBadge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verifiedBadge)

        // Role Label
        roleLabel.font      = UIFont.systemFont(ofSize: 15, weight: .medium)
        roleLabel.textColor = .gray
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roleLabel)

        // Connections CTA
        connectionsButton.translatesAutoresizingMaskIntoConstraints = false
        connectionsButton.backgroundColor = .clear
        connectionsButton.accessibilityTraits = [.button]
        addSubview(connectionsButton)

        // Connections Label
        connectionsLabel.font      = UIFont.systemFont(ofSize: 16, weight: .semibold)
        connectionsLabel.textColor = ActorProfileDS.deepPlum
        connectionsLabel.textAlignment = .center
        connectionsLabel.isUserInteractionEnabled = false
        connectionsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(connectionsLabel)

        let connLabel = UILabel()
        connLabel.text      = "Connections"
        connLabel.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        connLabel.textColor = .gray
        connLabel.textAlignment = .center
        connLabel.isUserInteractionEnabled = false
        connLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(connLabel)

        // Button stack (owns editPortfolioButton & connectButton)
        let buttonStack = UIStackView()
        buttonStack.axis         = .horizontal
        buttonStack.spacing      = 0
        buttonStack.distribution = .fill
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStack)

        // ── Portfolio Button (initially "Create Portfolio") ─────────────────
        editPortfolioButton.setTitle("Create Portfolio", for: .normal)
        editPortfolioButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        editPortfolioButton.setTitleColor(.white, for: .normal)
        editPortfolioButton.layer.cornerRadius = 22
        editPortfolioButton.layer.masksToBounds = true
        editPortfolioButton.translatesAutoresizingMaskIntoConstraints = false
        editPortfolioButton.setupGradient(colors: [ActorProfileDS.deepPlum, ActorProfileDS.midPlum])

        // ── Edit Profile button (own profile) ─────────────────────────────────
        editProfileButton.setTitle("Edit Profile", for: .normal)
        editProfileButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        editProfileButton.setTitleColor(.white, for: .normal)
        editProfileButton.layer.cornerRadius = 22
        editProfileButton.layer.masksToBounds = true
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        editProfileButton.setupGradient(colors: [ActorProfileDS.deepPlum, ActorProfileDS.midPlum])

        // ── Connect button (other users) ──────────────────────────────────────
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 22
        connectButton.layer.masksToBounds = true
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.setupGradient(colors: [ActorProfileDS.deepPlum, ActorProfileDS.rosePink])
        connectButton.isHidden = true

        // Both own-profile buttons fill equally; connect button fills full width
        buttonStack.spacing      = 12
        buttonStack.distribution = .fillEqually
        buttonStack.addArrangedSubview(editProfileButton)
        buttonStack.addArrangedSubview(editPortfolioButton)
        buttonStack.addArrangedSubview(connectButton)

        // Layout
        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            bannerImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            bannerImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
            bannerImageView.heightAnchor.constraint(equalToConstant: 140),

            profileImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -40),
            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            ringView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 136),
            ringView.heightAnchor.constraint(equalToConstant: 136),

            avatarEditButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            avatarEditButton.rightAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 4),
            avatarEditButton.widthAnchor.constraint(equalToConstant: 34),
            avatarEditButton.heightAnchor.constraint(equalToConstant: 34),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 18),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -12),

            verifiedBadge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            verifiedBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            verifiedBadge.widthAnchor.constraint(equalToConstant: 20),
            verifiedBadge.heightAnchor.constraint(equalToConstant: 20),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            roleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            connectionsButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 12),
            connectionsButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            connectionsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            connectionsButton.heightAnchor.constraint(equalToConstant: 50),

            connectionsLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 16),
            connectionsLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            connectionsLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            connLabel.topAnchor.constraint(equalTo: connectionsLabel.bottomAnchor, constant: 2),
            connLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            connLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: connLabel.bottomAnchor, constant: 20),
            buttonStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            buttonStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            buttonStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bannerGradientLayer.frame = bannerImageView.bounds
        ringGradientLayer.frame   = CGRect(origin: .zero, size: CGSize(width: 136, height: 136))
    }

    private func configureEditBadge(_ button: UIButton) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "pencil", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = .white
        button.backgroundColor = ActorProfileDS.deepPlum.withAlphaComponent(0.92)
        button.layer.cornerRadius = 17
        button.layer.borderWidth  = 1.5
        button.layer.borderColor  = UIColor.white.withAlphaComponent(0.9).cgColor
        button.layer.shadowColor  = UIColor.black.withAlphaComponent(0.18).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius  = 10
        button.layer.shadowOffset  = CGSize(width: 0, height: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - Professional Stats View

class ProfessionalStatsView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowColor   = UIColor.black.withAlphaComponent(0.05).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius  = 10
        layer.shadowOffset  = CGSize(width: 0, height: 4)

        let mainStack = UIStackView()
        mainStack.axis         = .horizontal
        mainStack.distribution = .fillEqually
        mainStack.alignment    = .top
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        func makeIcon(_ systemName: String) -> UIButton {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: systemName), for: .normal)
            b.tintColor       = ActorProfileDS.rosePink
            b.backgroundColor = ActorProfileDS.rosePink.withAlphaComponent(0.15)
            b.layer.cornerRadius = 25
            b.translatesAutoresizingMaskIntoConstraints = false
            b.widthAnchor.constraint(equalToConstant: 50).isActive  = true
            b.heightAnchor.constraint(equalToConstant: 50).isActive = true
            return b
        }

        func makeValueLabel(text: String, tag: Int = 0) -> UILabel {
            let l = UILabel()
            l.text      = text
            l.font      = UIFont.systemFont(ofSize: 18, weight: .bold)
            l.textColor = ActorProfileDS.deepPlum
            l.textAlignment = .center
            l.tag = tag
            return l
        }

        func makeSubLabel(_ text: String) -> UILabel {
            let l = UILabel()
            l.text      = text
            l.font      = UIFont.systemFont(ofSize: 13, weight: .medium)
            l.textColor = .gray
            l.textAlignment = .center
            l.numberOfLines = 2
            return l
        }

        func makeVStack(_ views: [UIView]) -> UIStackView {
            let s = UIStackView(arrangedSubviews: views)
            s.axis      = .vertical
            s.spacing   = 8
            s.alignment = .center
            return s
        }

        mainStack.addArrangedSubview(makeVStack([makeIcon("film"),          makeValueLabel(text: "0",   tag: 101), makeSubLabel("Projects")]))
        mainStack.addArrangedSubview(makeVStack([makeIcon("star.fill"),     makeValueLabel(text: "4.9"),            makeSubLabel("Rating")]))
        mainStack.addArrangedSubview(makeVStack([makeIcon("briefcase.fill"), makeValueLabel(text: "—",  tag: 103), makeSubLabel("Experience")]))

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            mainStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            mainStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
    }
}

// MARK: - About Section View

class AboutSectionView: UIView {

    let bioLabel: UILabel = {
        let l = UILabel()
        l.font      = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.textColor = .gray
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let specialtiesHeader: UILabel = {
        let l = UILabel()
        l.text      = "Specialties"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let skillsChipsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis         = .vertical
        sv.spacing      = 8
        sv.distribution = .fill
        sv.alignment    = .leading
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let locationValueLabel: UILabel = {
        let l = UILabel()
        l.text      = "—"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        l.numberOfLines = 1
        return l
    }()

    let experienceValueLabel: UILabel = {
        let l = UILabel()
        l.text      = "—"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        l.numberOfLines = 1
        return l
    }()

    private let infoStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text      = "About"
        titleLabel.font      = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = ActorProfileDS.deepPlum
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        addSubview(bioLabel)
        addSubview(specialtiesHeader)
        addSubview(skillsChipsStack)

        func makeRowIcon(_ systemName: String) -> UIImageView {
            let iv = UIImageView(image: UIImage(systemName: systemName))
            iv.tintColor = ActorProfileDS.rosePink
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 20).isActive  = true
            iv.heightAnchor.constraint(equalToConstant: 20).isActive = true
            return iv
        }

        func makeInfoRow(icon: String, title: String, valueLabel: UILabel) -> UIStackView {
            let titleLbl = UILabel()
            titleLbl.text      = title
            titleLbl.font      = UIFont.systemFont(ofSize: 12, weight: .medium)
            titleLbl.textColor = .gray
            let vStack = UIStackView(arrangedSubviews: [titleLbl, valueLabel])
            vStack.axis    = .vertical
            vStack.spacing = 2
            let hStack = UIStackView(arrangedSubviews: [makeRowIcon(icon), vStack])
            hStack.axis      = .horizontal
            hStack.spacing   = 8
            hStack.alignment = .center
            return hStack
        }

        infoStack.axis         = .horizontal
        infoStack.spacing      = 16
        infoStack.distribution = .fillEqually
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.addArrangedSubview(makeInfoRow(icon: "mappin.circle.fill",   title: "Location",   valueLabel: locationValueLabel))
        infoStack.addArrangedSubview(makeInfoRow(icon: "briefcase.circle.fill", title: "Experience", valueLabel: experienceValueLabel))
        addSubview(infoStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            bioLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            bioLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            bioLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            specialtiesHeader.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 14),
            specialtiesHeader.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),

            skillsChipsStack.topAnchor.constraint(equalTo: specialtiesHeader.bottomAnchor, constant: 8),
            skillsChipsStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            skillsChipsStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            infoStack.topAnchor.constraint(equalTo: skillsChipsStack.bottomAnchor, constant: 16),
            infoStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            infoStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    func setSkills(_ skills: [String]) {
        skillsChipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let text = skills.isEmpty ? "No specialties listed" : skills.joined(separator: ", ")
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        skillsChipsStack.addArrangedSubview(label)
    }
}

// MARK: - Gallery Header View

class GalleryHeaderView: UIView {
    let segmentControl = UISegmentedControl(items: ["Posts", "Flicks", "Tagged"])

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        segmentControl.selectedSegmentIndex = 0
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: topAnchor),
            segmentControl.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            segmentControl.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            segmentControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            segmentControl.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
}

// MARK: - Profile Settings

final class ProfileSettingsViewController: UIViewController {
    var onEditProfile: (() -> Void)?
    var onLogout:      (() -> Void)?
    var onDeleteAccount: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text      = "Settings"
        l.font      = UIFont.systemFont(ofSize: 30, weight: .bold)
        l.textColor = ActorProfileDS.deepPlum
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        title = ""

        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                   style: .plain, target: self, action: #selector(backTapped))
        back.tintColor = ActorProfileDS.deepPlum
        navigationItem.leftBarButtonItem = back

        view.addSubview(titleLabel)
        view.addSubview(stackView)

        let editBtn    = makeRowButton(title: "Edit Profile", subtitle: "Update your profile details and information")
        let termsBtn   = makeRowButton(title: "Terms & Conditions", subtitle: "Read CineMyst usage, creator, mentorship, and community guidelines")
        let privacyBtn = makeRowButton(title: "Privacy Policy", subtitle: "Understand how CineMyst stores, uses, and protects your data")
        let logoutBtn  = makeRowButton(title: "Logout",       subtitle: "Sign out of your account")
        let deleteBtn  = makeRowButton(title: "Delete Account", subtitle: "Permanently remove all your data", isDestructive: true)

        editBtn.addTarget(self,    action: #selector(editProfileTapped), for: .touchUpInside)
        termsBtn.addTarget(self,   action: #selector(termsTapped),       for: .touchUpInside)
        privacyBtn.addTarget(self, action: #selector(privacyTapped),     for: .touchUpInside)
        logoutBtn.addTarget(self,  action: #selector(logoutTapped),      for: .touchUpInside)
        deleteBtn.addTarget(self,  action: #selector(deleteTapped),      for: .touchUpInside)

        stackView.addArrangedSubview(editBtn)
        stackView.addArrangedSubview(termsBtn)
        stackView.addArrangedSubview(privacyBtn)
        stackView.addArrangedSubview(logoutBtn)
        stackView.addArrangedSubview(deleteBtn)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func makeRowButton(title: String, subtitle: String, isDestructive: Bool = false) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title           = title
        config.subtitle        = subtitle
        config.titleAlignment  = .leading
        config.image           = UIImage(systemName: "chevron.right")
        config.imagePlacement  = .trailing
        config.imagePadding    = 8
        config.baseForegroundColor = isDestructive ? .systemRed : ActorProfileDS.deepPlum
        config.contentInsets   = NSDirectionalEdgeInsets(top: 20, leading: 18, bottom: 20, trailing: 18)
        let b = UIButton(configuration: config)
        b.contentHorizontalAlignment = .fill
        b.backgroundColor     = .white
        b.layer.cornerRadius  = 18
        b.layer.shadowColor   = UIColor.black.withAlphaComponent(0.05).cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius  = 10
        b.layer.shadowOffset  = CGSize(width: 0, height: 4)
        return b
    }

    @objc private func backTapped()        { navigationController?.popViewController(animated: true) }
    @objc private func editProfileTapped() { navigationController?.popViewController(animated: false); onEditProfile?() }
    @objc private func termsTapped()       { navigationController?.pushViewController(TermsConditionsViewController(), animated: true) }
    @objc private func privacyTapped()     { navigationController?.pushViewController(PrivacyPolicyViewController(), animated: true) }
    @objc private func logoutTapped()      { navigationController?.popViewController(animated: false); onLogout?() }
    @objc private func deleteTapped()      { navigationController?.popViewController(animated: false); onDeleteAccount?() }
}

final class TermsConditionsViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Terms & Conditions"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = ActorProfileDS.deepPlum
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        title = ""

        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        back.tintColor = ActorProfileDS.deepPlum
        navigationItem.leftBarButtonItem = back

        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let introCard = makeInfoCard(
            title: "Welcome to CineMyst",
            body: "CineMyst is a creative network for filmmakers, actors, mentors, and studios. By using the app, you agree to use it responsibly, keep your account details accurate, and respect other creators on the platform."
        )

        let creatorCard = makeInfoCard(
            title: "Creator Content",
            body: "You are responsible for the posts, reels, portfolio items, and profile details you upload. Do not share copyrighted, abusive, misleading, or harmful content. CineMyst may remove content that violates platform safety or creator standards."
        )

        let jobsCard = makeInfoCard(
            title: "Jobs & Casting",
            body: "Casting calls, posted jobs, and applications must be genuine and lawful. Do not impersonate production houses, post misleading budgets, or misuse candidate information. Hiring decisions remain between users and recruiters."
        )

        let mentorshipCard = makeInfoCard(
            title: "Mentorship Sessions",
            body: "Mentors and mentees must engage professionally. Session fees, availability, and advice are shared by the mentor. CineMyst helps facilitate discovery and booking, but is not responsible for the individual outcome of sessions."
        )

        let conductCard = makeInfoCard(
            title: "Community Conduct",
            body: "Treat all creators with respect. Harassment, hate speech, scams, spam, and abusive behavior are not allowed. Repeated violations may result in content removal, account restrictions, or account deletion."
        )

        let privacyCard = makeInfoCard(
            title: "Privacy & Account",
            body: "Your profile, messages, and media are tied to your account. Keep your login secure. If you choose to delete your account, your access may be removed and connected data may be permanently erased according to app policy."
        )

        let updatesCard = makeInfoCard(
            title: "Updates to Terms",
            body: "CineMyst may improve or update these terms as the platform grows. Continued use of the app after updates means you accept the revised terms."
        )

        [introCard, creatorCard, jobsCard, mentorshipCard, conductCard, privacyCard, updatesCard].forEach {
            contentStack.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func makeInfoCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.borderWidth = 1
        card.layer.borderColor = ActorProfileDS.rosePink.withAlphaComponent(0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let heading = UILabel()
        heading.text = title
        heading.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        heading.textColor = ActorProfileDS.deepPlum
        heading.numberOfLines = 0
        heading.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = UIColor.darkGray
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(heading)
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            heading.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            heading.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            bodyLabel.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

final class PrivacyPolicyViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Privacy Policy"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = ActorProfileDS.deepPlum
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        title = ""

        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        back.tintColor = ActorProfileDS.deepPlum
        navigationItem.leftBarButtonItem = back

        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let dataCard = makeInfoCard(
            title: "What We Collect",
            body: "CineMyst may collect profile details, media uploads, mentorship details, job applications, messages, and activity needed to run the platform. We only collect information required to support creator discovery, networking, jobs, and mentorship."
        )

        let usageCard = makeInfoCard(
            title: "How We Use Your Data",
            body: "Your data is used to power your account, personalize your experience, show your content, enable messaging, process mentorship or job interactions, and improve platform safety and product quality."
        )

        let visibilityCard = makeInfoCard(
            title: "Profile & Content Visibility",
            body: "Information you choose to publish, like your profile, posts, reels, portfolio, or mentorship details, may be visible to other CineMyst users inside the app. You control what you upload and share."
        )

        let communicationCard = makeInfoCard(
            title: "Messages & Interactions",
            body: "Direct messages, mentorship requests, and application-related actions are stored to provide communication and collaboration features. These records may also help us support moderation and account safety when needed."
        )

        let securityCard = makeInfoCard(
            title: "Security & Protection",
            body: "CineMyst takes reasonable measures to protect your account and platform data. Even so, no digital system is completely risk-free, so users should keep credentials secure and avoid sharing sensitive information unnecessarily."
        )

        let controlCard = makeInfoCard(
            title: "Your Choices",
            body: "You can update your profile details, change your media, manage your visible content, and request account deletion through the app. Deleting your account may remove access and erase associated profile data."
        )

        let policyUpdatesCard = makeInfoCard(
            title: "Policy Updates",
            body: "As CineMyst evolves, this privacy policy may be updated to reflect new features, safety practices, or legal requirements. Continued use of the app means you accept the latest version available in settings."
        )

        [dataCard, usageCard, visibilityCard, communicationCard, securityCard, controlCard, policyUpdatesCard].forEach {
            contentStack.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func makeInfoCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.84)
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.borderWidth = 1
        card.layer.borderColor = ActorProfileDS.rosePink.withAlphaComponent(0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let heading = UILabel()
        heading.text = title
        heading.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        heading.textColor = ActorProfileDS.deepPlum
        heading.numberOfLines = 0
        heading.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = UIColor.darkGray
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(heading)
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            heading.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            heading.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            bodyLabel.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Gallery Collection View Data Source

struct ProfileMediaItem {
    enum Source: Equatable {
        case post
        case flick
        case tagged
    }

    let id: String
    let previewURL: String
    let contentURL: String
    let type: String
    let source: Source
}

class GalleryCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    var mediaItems: [ProfileMediaItem] = []
    var onSelectItem: ((ProfileMediaItem) -> Void)?

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryCell.reuseId, for: indexPath) as? GalleryCell
        else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId, for: indexPath)
        }
        let item = mediaItems[indexPath.item]
        cell.configureWithURL(imageURL: item.previewURL)
        cell.setMenuHidden(true)
        cell.onMenuTap = nil
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < mediaItems.count else { return }
        onSelectItem?(mediaItems[indexPath.item])
    }
}

final class ProfileMediaViewerController: UIViewController {
    private let item: ProfileMediaItem
    private let showsDeleteAction: Bool
    private let onDeleteAction: ((ProfileMediaItem) -> Void)?

    private let imageView = UIImageView()
    private let videoContainerView = UIView()
    private let actionButton = UIButton(type: .system)
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    init(item: ProfileMediaItem, showsDeleteAction: Bool, onDeleteAction: ((ProfileMediaItem) -> Void)? = nil) {
        self.item = item
        self.showsDeleteAction = showsDeleteAction
        self.onDeleteAction = onDeleteAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = item.type == "video"
        view.addSubview(imageView)

        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.isHidden = item.type != "video"
        view.addSubview(videoContainerView)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        actionButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        actionButton.tintColor = .white
        actionButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        actionButton.layer.cornerRadius = 20
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = !showsDeleteAction
        if showsDeleteAction {
            configureActionMenu()
        }
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            videoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            actionButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            actionButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            actionButton.widthAnchor.constraint(equalToConstant: 40),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        if item.type == "video", let url = URL(string: item.contentURL) {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            videoContainerView.layer.addSublayer(playerLayer)
            self.player = player
            self.playerLayer = playerLayer
            player.play()
        } else if let url = URL(string: item.contentURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }.resume()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }

    @objc private func closeTapped() {
        player?.pause()
        dismiss(animated: true)
    }

    private func configureActionMenu() {
        let deleteAction = UIAction(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.presentDeleteConfirmation()
        }

        actionButton.menu = UIMenu(title: "", children: [deleteAction])
        actionButton.showsMenuAsPrimaryAction = true
    }

    private func presentDeleteConfirmation() {
        let itemName = item.source == .flick ? "Flick" : "Post"
        let alert = UIAlertController(
            title: "Delete \(itemName)?",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.player?.pause()
            self.dismiss(animated: true) {
                self.onDeleteAction?(self.item)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - Main Actor Profile ViewController

final class ActorProfileViewController: UIViewController, EditProfileDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private enum MediaTab: Int {
        case gallery = 0
        case flicks = 1
        case tagged = 2
    }

    private let scrollView        = UIScrollView()
    private let contentStackView  = UIStackView()
    private let loadingView       = UIActivityIndicatorView(style: .large)
    private var collectionView: UICollectionView?
    private var galleryHeaderView: GalleryHeaderView?
    private let galleryDataSource = GalleryCollectionViewDataSource()
    private var galleryHeightConstraint: NSLayoutConstraint?

    private var profileData: UserProfileData?
    private var posts:        [PostData] = []
    private var userFlicks:   [Flick] = []
    private let userId:       UUID?
    private var hasPortfolio: Bool   = false
    private var hasCastingPortfolio: Bool = false
    private var isOwnProfile: Bool   = true
    /// "none" | "pending" | "connected"
    private var connectionState: String = "none"
    private var isVerifiedCasting: Bool = false
    private var selectedMediaTab: MediaTab = .gallery

    // Image editing (own profile only)
    private enum ImageEditTarget { case banner, avatar }
    private var pendingImageEditTarget: ImageEditTarget?

    init(userId: UUID? = nil) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.userId = nil
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        setupNavigationBar()
        setupLoadingView()
        setupUI()
        setupLayout()
        galleryDataSource.onSelectItem = { [weak self] item in
            self?.openMediaItem(item)
        }
        loadProfileData()

        NotificationCenter.default.addObserver(self, selector: #selector(portfolioCreated),
                                               name: .portfolioCreated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeHomeInjectedTitleIfNeeded()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Loading

    private func setupLoadingView() {
        loadingView.color = ActorProfileDS.deepPlum
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Data

    private func loadProfileData() {
        Task {
            do {
                loadingView.startAnimating()

                let combined: UserProfileData
                if let userId = userId {
                    combined = try await ProfileService.shared.fetchUserProfile(userId: userId)
                } else {
                    combined = try await ProfileService.shared.fetchCurrentUserProfile()
                }

                let isFirstLoad    = self.profileData == nil
                self.profileData   = combined
                self.posts         = try await ProfileService.shared.fetchUserPosts(userId: combined.profile.id)
                self.userFlicks    = try await self.fetchUserFlicks(userId: combined.profile.id)
                self.hasPortfolio  = await ProfileService.shared.hasPortfolio(userId: combined.profile.id)
                let castingProfile = await self.fetchCastingProfile(userId: combined.profile.id)
                self.hasCastingPortfolio = (castingProfile != nil)
                self.isVerifiedCasting = (castingProfile?.status == "verified")

                // Determine own vs other profile
                let currentUserId  = try await AuthManager.shared.currentSession()?.user.id
                self.isOwnProfile  = (self.userId == nil || self.userId == currentUserId)

                // Fetch connection state for other profiles
                if !self.isOwnProfile, let otherId = self.userId, let meId = currentUserId {
                    self.connectionState = await ProfileService.shared.connectionState(
                        requesterId: meId, receiverId: otherId)
                }

                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.updateUIWithProfileData()
                    if isFirstLoad { self.addAnimations() }
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.showErrorMessage("Failed to load profile: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - UI Update

    private func updateUIWithProfileData() {
        guard let data = profileData else { return }

        // --- Profile Card ---
        if let card = contentStackView.arrangedSubviews.first as? ActorProfileCardView {
            card.nameLabel.text        = data.profile.fullName ?? data.profile.username ?? "Profile"
            card.verifiedBadge.isHidden = !isVerifiedCasting
            card.roleLabel.text        = formatRoleLabel(data)
            card.connectionsLabel.text = "\(data.profile.connectionCount)"
            card.connectionsButton.accessibilityLabel = "Connections"
            card.connectionsButton.accessibilityValue = "\(data.profile.connectionCount)"
            card.connectionsButton.removeTarget(nil, action: nil, for: .allEvents)
            card.connectionsButton.addTarget(self, action: #selector(connectionsTapped), for: .touchUpInside)

            if let url = data.profile.profilePictureUrl {
                loadImage(from: url) { card.profileImageView.image = $0 }
            }
            if let url = data.profile.bannerUrl {
                loadImage(from: url) { card.bannerImageView.image = $0 }
            }

            // Buttons: own profile → edit controls; other → connect
            card.avatarEditButton.isHidden    = !isOwnProfile
            card.editProfileButton.isHidden   = !isOwnProfile

            if isOwnProfile {
                card.editPortfolioButton.isHidden = false
                card.connectButton.isHidden       = true
                
                card.avatarEditButton.removeTarget(nil, action: nil, for: .allEvents)
                card.avatarEditButton.addTarget(self, action: #selector(editProfileImageTapped), for: .touchUpInside)
                card.editProfileButton.removeTarget(nil, action: nil, for: .allEvents)
                card.editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
                card.editPortfolioButton.removeTarget(nil, action: nil, for: .allEvents)
                card.editPortfolioButton.addTarget(self, action: #selector(editPortfolioTapped), for: .touchUpInside)
                
                // Casting professionals should go to the production profile info flow.
                let btnTitle: String
                if shouldUseCastingPortfolioFlow(data) {
                    btnTitle = hasCastingPortfolio ? "Edit Portfolio" : "Create Portfolio"
                } else {
                    btnTitle = hasPortfolio ? "Edit Portfolio" : "Create Portfolio"
                }
                card.editPortfolioButton.setTitle(btnTitle, for: .normal)
            } else {
                card.connectButton.isHidden = false
                card.connectButton.removeTarget(nil, action: nil, for: .allEvents)
                card.connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
                updateConnectButton(card.connectButton)
                
                // Show "View Portfolio" only if connected
                if connectionState == "connected" {
                    card.editPortfolioButton.isHidden = false
                    card.editPortfolioButton.setTitle("View Portfolio", for: .normal)
                    card.editPortfolioButton.removeTarget(nil, action: nil, for: .allEvents)
                    card.editPortfolioButton.addTarget(self, action: #selector(editPortfolioTapped), for: .touchUpInside)
                } else {
                    card.editPortfolioButton.isHidden = true
                }
            }
        }

        // --- Stats ---
        if let statsView = contentStackView.arrangedSubviews.compactMap({ $0 as? ProfessionalStatsView }).first {
            updateStatsView(statsView, with: data)
        }

        // --- About ---
        if let aboutView = contentStackView.arrangedSubviews.compactMap({ $0 as? AboutSectionView }).first {
            aboutView.bioLabel.text = data.profile.bio.flatMap { $0.isEmpty ? nil : $0 } ?? "No bio available."
            aboutView.setSkills(data.artistProfile?.skills ?? [])
            let locText = data.profile.location.flatMap { $0.isEmpty ? nil : $0 } ?? "Not specified"
            aboutView.locationValueLabel.text = locText.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? locText
            if let yrs = data.artistProfile?.yearsOfExperience {
                aboutView.experienceValueLabel.text = yrs == 1 ? "1 year" : "\(yrs)+ years"
            } else {
                aboutView.experienceValueLabel.text = "Not specified"
            }
        }

        updateMediaContent()
        
        // Update navigation bar items based on ownership
        navigationItem.rightBarButtonItem = isOwnProfile ? UIBarButtonItem(customView: makeNavButton(systemName: "gearshape.fill", action: #selector(settingsTapped))) : nil
    }

    // MARK: - Connect (other users)

    private func updateConnectButton(_ btn: GradientButton) {
        switch connectionState {
        case "pending":
            btn.setTitle("Pending ⏳", for: .normal)
            btn.isEnabled = false
            btn.alpha     = 0.6
        case "connected":
            btn.setTitle("✓ Connected", for: .normal)
            btn.isEnabled = false
            btn.alpha     = 0.7
        default:
            btn.setTitle("Connect", for: .normal)
            btn.isEnabled = true
            btn.alpha     = 1
        }
    }

    @objc private func connectTapped() {
        guard let targetId = userId else { return }
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let me = session.user
                let meId = me.id.uuidString
                let otherId = targetId.uuidString

                // Check if a connection already exists in any direction
                let state = await ProfileService.shared.connectionState(requesterId: me.id, receiverId: targetId)
                if state != "none" {
                    await MainActor.run {
                        let a = UIAlertController(title: "Request Existing", message: "A connection or request already exists between you.", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(a, animated: true)
                    }
                    return
                }

                struct ConnectionInsert: Encodable {
                    let requester_id, receiver_id, status: String
                }
                try await supabase
                    .from("connections")
                    .insert(ConnectionInsert(requester_id: meId,
                                             receiver_id: otherId,
                                             status: "pending"))
                    .execute()

                let myName: String
                do {
                    let myProfile = try await ProfileService.shared.fetchCurrentUserProfile()
                    myName = myProfile.profile.fullName ?? myProfile.profile.username ?? me.email ?? "Someone"
                } catch {
                    myName = me.email ?? "Someone"
                }

                struct NotifInsert: Encodable {
                    let recipient_id, sender_id, type, title, message: String
                }
                try await supabase
                    .from("notifications")
                    .insert(NotifInsert(
                        recipient_id: targetId.uuidString,
                        sender_id:    me.id.uuidString,
                        type:         "connection_request",
                        title:        myName,
                        message:      "\(myName) wants to connect with you."
                    ))
                    .execute()

                await MainActor.run {
                    self.connectionState = "pending"
                    if let card = self.contentStackView.arrangedSubviews.first as? ActorProfileCardView {
                        self.updateConnectButton(card.connectButton)
                    }
                    let a = UIAlertController(title: "🎉 Request Sent",
                                              message: "Your connection request has been sent!",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    // MARK: - Edit Profile (own profile)

    @objc private func editProfileTapped() {
        let editVC = EditProfileViewController(
            userId: profileData?.profile.id ?? userId ?? UUID(),
            profileData: profileData
        )
        editVC.delegate = self
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func editProfileDidSave() {
        loadProfileData()
    }

    // MARK: - Edit Portfolio

    @objc private func portfolioCreated() {
        loadProfileData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let vc = PortfolioViewController()
            vc.isOwnProfile = true
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
    }

    @objc private func editPortfolioTapped() {
        if let data = profileData, shouldUseCastingPortfolioFlow(data) {
            let vc = ProfileInfoViewController()
            vc.hidesBottomBarWhenPushed = true
            if let navigationController {
                navigationController.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true)
            }
            return
        }

        // If user is connected OR it's their own profile, show the redesigned portfolio screen.
        if isOwnProfile || connectionState == "connected" {
            let vc = PortfolioViewController()
            vc.isOwnProfile = isOwnProfile
            if !isOwnProfile {
                let uid = profileData?.profile.id ?? userId
                vc.targetUserId = uid?.uuidString
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            // Probably should show creation only for self
            if isOwnProfile {
                let vc = PortfolioCreationViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true)
            }
        }
    }

    @objc private func connectionsTapped() {
        guard let targetUserId = profileData?.profile.id ?? userId else { return }

        let connectionsVC = ConnectionsListViewController()
        connectionsVC.userId = targetUserId.uuidString
        connectionsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(connectionsVC, animated: true)
    }

    // MARK: - Image Editing (avatar / banner — own profile only)

    @objc private func editProfileImageTapped() {
        let sheet = UIAlertController(title: "Update Images", message: "What would you like to change?", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Profile Image", style: .default) { [weak self] _ in
            self?.presentImagePicker(for: .avatar)
        })
        sheet.addAction(UIAlertAction(title: "Banner Image", style: .default) { [weak self] _ in
            self?.presentImagePicker(for: .banner)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController,
           let card = contentStackView.arrangedSubviews.first as? ActorProfileCardView {
            popover.sourceView = card.avatarEditButton
            popover.sourceRect = card.avatarEditButton.bounds
        }
        present(sheet, animated: true)
    }

    private func presentImagePicker(for target: ImageEditTarget) {
        pendingImageEditTarget = target
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showErrorMessage("Photo library is not available on this device.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        pendingImageEditTarget = nil
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let target = pendingImageEditTarget else { return }
        pendingImageEditTarget = nil

        let selectedImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        guard let image = selectedImage else { return }

        DispatchQueue.main.async {
            guard let card = self.contentStackView.arrangedSubviews.first as? ActorProfileCardView else { return }
            switch target {
            case .banner:
                card.bannerImageView.image = image
            case .avatar:
                card.profileImageView.image = image
            }
            self.persistImageChange(image, target: target)
        }
    }

    private func persistImageChange(_ image: UIImage, target: ImageEditTarget) {
        guard let userUUID = profileData?.profile.id ?? userId else { return }
        loadingView.startAnimating()

        Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.82) else {
                    throw NSError(domain: "ActorProfileViewController", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image."])
                }

                let prefix = userUUID.uuidString
                let fileName: String
                switch target {
                case .banner: fileName = "\(prefix)/banner_\(UUID().uuidString).jpg"
                case .avatar: fileName = "\(prefix)/profile_\(UUID().uuidString).jpg"
                }

                try await supabase.storage
                    .from("profile-pictures")
                    .upload(path: fileName, file: imageData,
                            options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true))

                let publicURL = try supabase.storage
                    .from("profile-pictures")
                    .getPublicURL(path: fileName).absoluteString

                let now = ISO8601DateFormatter().string(from: Date())
                let payload: [String: String]
                switch target {
                case .banner: payload = ["banner_url": publicURL, "updated_at": now]
                case .avatar: payload = ["profile_picture_url": publicURL, "avatar_url": publicURL, "updated_at": now]
                }

                _ = try await supabase.from("profiles")
                    .update(payload)
                    .eq("id", value: userUUID.uuidString)
                    .execute()

                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.loadProfileData()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.showErrorMessage("Failed to update image: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func updateStatsView(_ statsView: ProfessionalStatsView, with data: UserProfileData) {
        if let lbl = statsView.viewWithTag(101) as? UILabel {
            lbl.text = "\(data.projectCount)"
        }
        if let lbl = statsView.viewWithTag(103) as? UILabel {
            if let yrs = data.artistProfile?.yearsOfExperience {
                lbl.text = yrs == 1 ? "1 yr" : "\(yrs)+ yrs"
            } else {
                lbl.text = "—"
            }
        }
    }

    private func formatRoleLabel(_ data: UserProfileData) -> String {
        var parts: [String] = []
        if let username = data.profile.username { 
            parts.append("@\(username)") 
        }
        
        if hasCastingPortfolio {
            parts.append("I cast")
        } else if let roles = data.artistProfile?.primaryRoles, !roles.isEmpty {
            parts.append(roles.joined(separator: ", "))
        } else if let role = data.profile.role, !role.isEmpty {
            parts.append(role)
        } else {
            parts.append("Actor") // Default fallback
        }
        
        return parts.joined(separator: " • ")
    }

    private func shouldUseCastingPortfolioFlow(_ data: UserProfileData) -> Bool {
        // If they have a casting profile record, they are definitely a director
        if hasCastingPortfolio { return true }
        
        // Otherwise check the role, but only if they don't have artist roles defined
        let hasArtistRoles = !(data.artistProfile?.primaryRoles?.isEmpty ?? true)
        if hasArtistRoles { return false }

        let normalizedRole = data.profile.role?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
        return normalizedRole == "casting_professional"
    }

    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    private func openMediaItem(_ item: ProfileMediaItem) {
        let viewer = ProfileMediaViewerController(
            item: item,
            showsDeleteAction: isOwnProfile && item.source != .tagged,
            onDeleteAction: { [weak self] selectedItem in
                self?.deleteMedia(selectedItem)
            }
        )
        viewer.modalPresentationStyle = .fullScreen
        present(viewer, animated: true)
    }

    private func fetchUserFlicks(userId: UUID) async throws -> [Flick] {
        let response = try await supabase
            .from("flicks")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        return try JSONDecoder().decode([Flick].self, from: response.data)
    }

    private func fetchCastingProfile(userId: UUID) async -> CastingProfileRecord? {
        do {
            let profile: CastingProfileRecord = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return profile
        } catch {
            return nil
        }
    }

    @objc private func mediaSegmentChanged(_ sender: UISegmentedControl) {
        selectedMediaTab = MediaTab(rawValue: sender.selectedSegmentIndex) ?? .gallery
        updateMediaContent()
    }

    private func updateMediaContent() {
        let mediaItems: [ProfileMediaItem]

        switch selectedMediaTab {
        case .gallery:
            mediaItems = posts.compactMap { post in
                guard let first = post.media.first else { return nil }
                let previewURL = (first.mediaType == "video" ? first.thumbnailUrl : nil) ?? first.mediaUrl
                return ProfileMediaItem(
                    id: post.id,
                    previewURL: previewURL,
                    contentURL: first.mediaUrl,
                    type: first.mediaType,
                    source: .post
                )
            }
        case .flicks:
            mediaItems = userFlicks.compactMap { flick in
                let previewURL = flick.thumbnailUrl ?? flick.videoUrl
                guard !previewURL.isEmpty else { return nil }
                return ProfileMediaItem(
                    id: flick.id,
                    previewURL: previewURL,
                    contentURL: flick.videoUrl,
                    type: "video",
                    source: .flick
                )
            }
        case .tagged:
            mediaItems = []
        }

        galleryDataSource.mediaItems = mediaItems

        let itemsPerRow: CGFloat = 3
        let spacing: CGFloat     = 2
        let totalWidth           = UIScreen.main.bounds.width - 32
        let itemWidth            = (totalWidth - (itemsPerRow - 1) * spacing) / itemsPerRow
        let rows                 = mediaItems.isEmpty ? 0 : ceil(CGFloat(mediaItems.count) / itemsPerRow)
        galleryHeightConstraint?.constant = rows == 0 ? 0 : rows * itemWidth + max(0, rows - 1) * spacing
        collectionView?.isHidden = mediaItems.isEmpty
        collectionView?.reloadData()
    }

    private func deleteMedia(_ item: ProfileMediaItem) {
        loadingView.startAnimating()

        Task {
            do {
                switch item.source {
                case .post:
                    try await PostManager.shared.deletePost(postId: item.id)
                case .flick:
                    try await FlicksService.shared.deleteFlick(flickId: item.id)
                case .tagged:
                    return
                }

                await MainActor.run {
                    switch item.source {
                    case .post:
                        self.posts.removeAll { $0.id == item.id }
                    case .flick:
                        self.userFlicks.removeAll { $0.id == item.id }
                    case .tagged:
                        break
                    }
                    self.loadingView.stopAnimating()
                    self.updateMediaContent()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.showErrorMessage("Failed to delete item: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showErrorMessage(_ message: String) {
        let a = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK",    style: .default))
        a.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in self?.loadProfileData() })
        present(a, animated: true)
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.prefersLargeTitles = false
        if #available(iOS 14.0, *) { navigationItem.backButtonDisplayMode = .minimal }

        let titleLabel = UILabel()
        titleLabel.text      = "CineMyst"
        titleLabel.font      = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ActorProfileDS.deepPlum
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        if isOwnProfile {
            let settingsBtn = makeNavButton(systemName: "gearshape.fill", action: #selector(settingsTapped))
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsBtn)
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        let isRoot = navigationController?.viewControllers.first === self
        if !isRoot {
            let backBtn = makeNavButton(systemName: "chevron.left", action: #selector(backTapped))
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        }
    }

    private func makeNavButton(systemName: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        b.setImage(UIImage(systemName: systemName, withConfiguration: cfg), for: .normal)
        b.tintColor       = ActorProfileDS.deepPlum
        b.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        b.layer.cornerRadius  = 18
        b.layer.shadowColor   = UIColor.black.withAlphaComponent(0.08).cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius  = 10
        b.layer.shadowOffset  = CGSize(width: 0, height: 4)
        b.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func settingsTapped() {
        let vc = ProfileSettingsViewController()
        vc.onEditProfile   = { [weak self] in self?.editProfileTapped() }
        vc.onLogout        = { [weak self] in self?.logoutTapped() }
        vc.onDeleteAccount = { [weak self] in self?.deleteAccountTapped() }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func logoutTapped() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                await MainActor.run {
                    let welcomeVC = LaunchWelcomeViewController()
                    let nav = UINavigationController(rootViewController: welcomeVC)
                    nav.setNavigationBarHidden(true, animated: false)
                    
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = nav
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                    } else {
                        nav.modalPresentationStyle = .fullScreen
                        self.present(nav, animated: true)
                    }
                }
            } catch {
                await MainActor.run { self.showErrorMessage("Failed to logout: \(error.localizedDescription)") }
            }
        }
    }

    private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account?",
            message: "This action is permanent and will delete all your profile data, credits, and reels. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Permanently", style: .destructive) { [weak self] _ in
            self?.performAccountDeletion()
        })
        
        present(alert, animated: true)
    }

    private func performAccountDeletion() {
        loadingView.startAnimating()
        Task {
            do {
                try await AuthManager.shared.deleteAccount()
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    let welcomeVC = LaunchWelcomeViewController()
                    let nav = UINavigationController(rootViewController: welcomeVC)
                    nav.setNavigationBarHidden(true, animated: false)
                    
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = nav
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                    } else {
                        nav.modalPresentationStyle = .fullScreen
                        self.present(nav, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.showErrorMessage("Failed to delete account: \(error.localizedDescription)")
                }
            }
        }
    }

    private func removeHomeInjectedTitleIfNeeded() {
        guard let navBar = navigationController?.navigationBar,
              let cv = navBar.subviews.first(where: { String(describing: type(of: $0)).contains("ContentView") })
        else { return }
        cv.viewWithTag(999)?.removeFromSuperview()
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    // MARK: - UI Setup

    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.axis         = .vertical
        contentStackView.spacing      = 16
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        let profileCard = ActorProfileCardView()
        profileCard.heightAnchor.constraint(equalToConstant: 430).isActive = true
        contentStackView.addArrangedSubview(profileCard)

        contentStackView.addArrangedSubview(AboutSectionView())

        let galleryHeader = GalleryHeaderView()
        galleryHeader.segmentControl.addTarget(self, action: #selector(mediaSegmentChanged(_:)), for: .valueChanged)
        galleryHeader.heightAnchor.constraint(equalToConstant: 50).isActive = true
        galleryHeaderView = galleryHeader
        contentStackView.addArrangedSubview(galleryHeader)

        let itemsPerRow: CGFloat = 3
        let spacing: CGFloat     = 2
        let totalWidth           = UIScreen.main.bounds.width - 24
        let itemWidth            = (totalWidth - (itemsPerRow - 1) * spacing) / itemsPerRow

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection        = .vertical
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing      = spacing
        layout.itemSize                = CGSize(width: itemWidth, height: itemWidth)

        let gc = UICollectionView(frame: .zero, collectionViewLayout: layout)
        gc.backgroundColor = .clear
        gc.isScrollEnabled = false
        gc.translatesAutoresizingMaskIntoConstraints = false
        gc.dataSource = galleryDataSource
        gc.delegate   = galleryDataSource
        gc.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseId)
        self.collectionView = gc
        contentStackView.addArrangedSubview(gc)

        let hc = gc.heightAnchor.constraint(equalToConstant: itemWidth)
        hc.isActive = true
        galleryHeightConstraint = hc

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(spacer)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),
            contentStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 12),
            contentStackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -12),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24),
        ])
    }

    private func addAnimations() {
        contentStackView.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
            self.contentStackView.alpha = 1
        }
        if let card = contentStackView.arrangedSubviews.first {
            card.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut) {
                card.transform = .identity
            }
        }
    }
}
