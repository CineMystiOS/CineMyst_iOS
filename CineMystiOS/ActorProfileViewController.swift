//
//  ActorProfileViewController.swift
//  CineMystApp
//
//  Modern actor profile screen - #431631 × #CD72A8

import UIKit
import PhotosUI
import Supabase

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
    let roleLabel          = UILabel()
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
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Role Label
        roleLabel.font      = UIFont.systemFont(ofSize: 15, weight: .medium)
        roleLabel.textColor = .gray
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roleLabel)

        // Connections Label
        connectionsLabel.font      = UIFont.systemFont(ofSize: 16, weight: .semibold)
        connectionsLabel.textColor = ActorProfileDS.deepPlum
        connectionsLabel.textAlignment = .center
        connectionsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(connectionsLabel)

        let connLabel = UILabel()
        connLabel.text      = "Connections"
        connLabel.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        connLabel.textColor = .gray
        connLabel.textAlignment = .center
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
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            roleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

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
        sv.axis         = .horizontal
        sv.spacing      = 8
        sv.distribution = .fillProportionally
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let locationValueLabel: UILabel = {
        let l = UILabel()
        l.text      = "—"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        return l
    }()

    let experienceValueLabel: UILabel = {
        let l = UILabel()
        l.text      = "—"
        l.font      = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
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
            skillsChipsStack.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -16),
            skillsChipsStack.heightAnchor.constraint(equalToConstant: 28),

            infoStack.topAnchor.constraint(equalTo: skillsChipsStack.bottomAnchor, constant: 16),
            infoStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            infoStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    func setSkills(_ skills: [String]) {
        skillsChipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let list = skills.isEmpty ? ["No specialties listed"] : skills
        for skill in list {
            let chip = UILabel()
            chip.text           = skill
            chip.font           = UIFont.systemFont(ofSize: 13, weight: .semibold)
            chip.textColor      = skills.isEmpty ? .gray : ActorProfileDS.deepPlum
            chip.backgroundColor = skills.isEmpty ? .clear : ActorProfileDS.palePink
            chip.layer.cornerRadius = 12
            chip.clipsToBounds  = true
            chip.textAlignment  = .center
            chip.numberOfLines  = 1
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.heightAnchor.constraint(equalToConstant: 28).isActive = true
            skillsChipsStack.addArrangedSubview(chip)
        }
    }
}

// MARK: - Gallery Header View

class GalleryHeaderView: UIView {
    let segmentControl = UISegmentedControl(items: ["Gallery", "Flicks", "Tagged"])

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

        let editBtn   = makeRowButton(title: "Edit Profile", subtitle: "Update your profile details and information")
        let logoutBtn = makeRowButton(title: "Logout",       subtitle: "Sign out of your account")
        editBtn.addTarget(self,   action: #selector(editProfileTapped), for: .touchUpInside)
        logoutBtn.addTarget(self, action: #selector(logoutTapped),      for: .touchUpInside)
        stackView.addArrangedSubview(editBtn)
        stackView.addArrangedSubview(logoutBtn)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func makeRowButton(title: String, subtitle: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title           = title
        config.subtitle        = subtitle
        config.titleAlignment  = .leading
        config.image           = UIImage(systemName: "chevron.right")
        config.imagePlacement  = .trailing
        config.imagePadding    = 8
        config.baseForegroundColor = ActorProfileDS.deepPlum
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
    @objc private func logoutTapped()      { navigationController?.popViewController(animated: false); onLogout?() }
}

// MARK: - Gallery Collection View Data Source

class GalleryCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    var postMediaItems: [(url: String, type: String)] = []

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        postMediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryCell.reuseId, for: indexPath) as? GalleryCell
        else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId, for: indexPath)
        }
        cell.configureWithURL(imageURL: postMediaItems[indexPath.item].url)
        return cell
    }
}

// MARK: - Main Actor Profile ViewController

final class ActorProfileViewController: UIViewController, EditProfileDelegate, PHPickerViewControllerDelegate {

    private let scrollView        = UIScrollView()
    private let contentStackView  = UIStackView()
    private let loadingView       = UIActivityIndicatorView(style: .large)
    private var collectionView: UICollectionView?
    private let galleryDataSource = GalleryCollectionViewDataSource()
    private var galleryHeightConstraint: NSLayoutConstraint?

    private var profileData: UserProfileData?
    private var posts:        [PostData] = []
    private let userId:       UUID?
    private var hasPortfolio: Bool   = false
    private var isOwnProfile: Bool   = true
    /// "none" | "pending" | "connected"
    private var connectionState: String = "none"

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
                self.hasPortfolio  = await ProfileService.shared.hasPortfolio(userId: combined.profile.id)

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
            card.roleLabel.text        = formatRoleLabel(data)
            card.connectionsLabel.text = "\(data.profile.connectionCount)"

            if let url = data.profile.profilePictureUrl {
                loadImage(from: url) { card.profileImageView.image = $0 }
            }
            if let url = data.profile.bannerUrl {
                loadImage(from: url) { card.bannerImageView.image = $0 }
            }

            // Buttons: own profile → edit controls; other → connect
            card.avatarEditButton.isHidden    = !isOwnProfile
            card.editProfileButton.isHidden   = !isOwnProfile
            card.editPortfolioButton.isHidden = !isOwnProfile
            card.connectButton.isHidden       = isOwnProfile

            if isOwnProfile {
                card.avatarEditButton.removeTarget(nil, action: nil, for: .allEvents)
                card.avatarEditButton.addTarget(self, action: #selector(editProfileImageTapped), for: .touchUpInside)
                card.editProfileButton.removeTarget(nil, action: nil, for: .allEvents)
                card.editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
                card.editPortfolioButton.removeTarget(nil, action: nil, for: .allEvents)
                card.editPortfolioButton.addTarget(self, action: #selector(editPortfolioTapped), for: .touchUpInside)
                
                // Toggle text based on existence
                let btnTitle = hasPortfolio ? "Edit Portfolio" : "Create Portfolio"
                card.editPortfolioButton.setTitle(btnTitle, for: .normal)
            } else {
                card.connectButton.removeTarget(nil, action: nil, for: .allEvents)
                card.connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
                updateConnectButton(card.connectButton)
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
            aboutView.locationValueLabel.text   = data.profile.location.flatMap { $0.isEmpty ? nil : $0 } ?? "Not specified"
            if let yrs = data.artistProfile?.yearsOfExperience {
                aboutView.experienceValueLabel.text = yrs == 1 ? "1 year" : "\(yrs)+ years"
            } else {
                aboutView.experienceValueLabel.text = "Not specified"
            }
        }

        // --- Gallery ---
        var mediaItems: [(url: String, type: String)] = []
        for post in posts {
            if let first = post.media.first {
                let url = (first.mediaType == "video" ? first.thumbnailUrl : nil) ?? first.mediaUrl
                mediaItems.append((url: url, type: first.mediaType))
            }
        }
        galleryDataSource.postMediaItems = mediaItems

        let itemsPerRow: CGFloat = 3
        let spacing: CGFloat     = 2
        let totalWidth           = UIScreen.main.bounds.width - 24
        let itemWidth            = (totalWidth - (itemsPerRow - 1) * spacing) / itemsPerRow
        let rows                 = max(1, ceil(CGFloat(mediaItems.count) / itemsPerRow))
        galleryHeightConstraint?.constant = rows * itemWidth + (rows - 1) * spacing
        collectionView?.reloadData()
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

                struct ConnectionInsert: Encodable {
                    let requester_id, receiver_id, status: String
                }
                try await supabase
                    .from("connections")
                    .insert(ConnectionInsert(requester_id: me.id.uuidString,
                                             receiver_id: targetId.uuidString,
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
        if hasPortfolio {
            let vc = ActorPortfolioDetailViewController()
            vc.isOwnProfile = true
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            let vc = PortfolioCreationViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
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
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter         = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate        = self
        pendingImageEditTarget = target
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first,
              result.itemProvider.canLoadObject(ofClass: UIImage.self),
              let target = pendingImageEditTarget else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                guard let card = self.contentStackView.arrangedSubviews.first as? ActorProfileCardView else { return }
                switch target {
                case .banner: card.bannerImageView.image  = image
                case .avatar: card.profileImageView.image = image
                }
                self.persistImageChange(image, target: target)
            }
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
        if let username = data.profile.username { parts.append("@\(username)") }
        if let roles = data.artistProfile?.primaryRoles, !roles.isEmpty {
            parts.append(roles.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            DispatchQueue.main.async { completion(image) }
        }.resume()
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
        titleLabel.font      = UIFont(name: "Georgia-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ActorProfileDS.deepPlum
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        let settingsBtn = makeNavButton(systemName: "gearshape.fill", action: #selector(settingsTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsBtn)

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
        vc.onEditProfile = { [weak self] in self?.editProfileTapped() }
        vc.onLogout      = { [weak self] in self?.logoutTapped() }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func logoutTapped() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                await MainActor.run {
                    let nav = UINavigationController(rootViewController: LoginViewController())
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            } catch {
                await MainActor.run { self.showErrorMessage("Failed to logout: \(error.localizedDescription)") }
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

        let statsView = ProfessionalStatsView()
        statsView.heightAnchor.constraint(equalToConstant: 146).isActive = true
        contentStackView.addArrangedSubview(statsView)

        contentStackView.addArrangedSubview(AboutSectionView())

        let galleryHeader = GalleryHeaderView()
        galleryHeader.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
