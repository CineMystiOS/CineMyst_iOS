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
    static let deepPlum = UIColor(hex: "#431631")
    static let rosePink = UIColor(hex: "#CD72A8")
    static let midPlum = UIColor(hex: "#6B2050")
    static let palePink = UIColor(hex: "#F5E8F0")
    static let bgLight = UIColor(hex: "#FAF0F6")
    
    static func gradient(colors: [UIColor]) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }
}

// MARK: - Actor Profile Card View

class ActorProfileCardView: UIView {
    
    let bannerImageView = UIImageView()
    let profileImageView = UIImageView()
    let badgeView = UIView()
    let nameLabel = UILabel()
    let roleLabel = UILabel()
    let connectionsLabel = UILabel()
    let editProfileButton = GradientButton(type: .system)
    let editPortfolioButton = GradientButton(type: .system)
    let moreButton = UIButton(type: .system)
    let shareButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        translatesAutoresizingMaskIntoConstraints = false
        
        // Header Tag
        let headerTag = UILabel()
        headerTag.text = "Acting for Life"
        headerTag.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        headerTag.textColor = ActorProfileDS.deepPlum
        headerTag.backgroundColor = ActorProfileDS.palePink
        headerTag.textAlignment = .center
        headerTag.layer.cornerRadius = 12
        headerTag.clipsToBounds = true
        headerTag.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerTag)
        
        // Banner Image
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.backgroundColor = ActorProfileDS.palePink
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerImageView)
        
        // Overlay gradient on banner
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, ActorProfileDS.deepPlum.withAlphaComponent(0.3).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        bannerImageView.layer.addSublayer(gradientLayer)
        
        // Top Right Buttons (Share + More)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(shareButton)
        
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .white
        moreButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(moreButton)
        
        // Profile Image with Gradient Ring
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth = 5
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.backgroundColor = ActorProfileDS.palePink
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)
        
        // Gradient ring background
        let ringView = UIView()
        ringView.layer.cornerRadius = 68
        let gradLayer = ActorProfileDS.gradient(colors: [ActorProfileDS.deepPlum, ActorProfileDS.rosePink])
        gradLayer.cornerRadius = 68
        ringView.layer.addSublayer(gradLayer)
        ringView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(ringView, belowSubview: profileImageView)
        
        // Blue Badge
        badgeView.backgroundColor = #colorLiteral(red: 0.2, green: 0.6, blue: 1, alpha: 1)
        badgeView.layer.cornerRadius = 15
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeView)
        
        let badgeIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        badgeIcon.tintColor = .white
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeIcon)
        
        // Name Label
        nameLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        nameLabel.textColor = ActorProfileDS.deepPlum
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Role Label
        roleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        roleLabel.textColor = .gray
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roleLabel)
        
        // Connections Label
        connectionsLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        connectionsLabel.textColor = ActorProfileDS.deepPlum
        connectionsLabel.textAlignment = .center
        connectionsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(connectionsLabel)
        
        let connLabel = UILabel()
        connLabel.text = "Connections"
        connLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        connLabel.textColor = .gray
        connLabel.textAlignment = .center
        connLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(connLabel)
        
        // Action Buttons Container
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStack)
        
        // Edit Profile Button
        editProfileButton.setTitle("Edit Profile", for: .normal)
        editProfileButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        editProfileButton.setTitleColor(.white, for: .normal)
        editProfileButton.layer.cornerRadius = 10
        editProfileButton.layer.masksToBounds = true
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        editProfileButton.setupGradient(colors: [ActorProfileDS.deepPlum, ActorProfileDS.midPlum])
        buttonStack.addArrangedSubview(editProfileButton)
        
        // Edit Portfolio Button
        editPortfolioButton.setTitle("Edit Portfolio", for: .normal)
        editPortfolioButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        editPortfolioButton.setTitleColor(.white, for: .normal)
        editPortfolioButton.layer.cornerRadius = 10
        editPortfolioButton.layer.masksToBounds = true
        editPortfolioButton.translatesAutoresizingMaskIntoConstraints = false
        editPortfolioButton.setupGradient(colors: [ActorProfileDS.rosePink, ActorProfileDS.deepPlum])
        buttonStack.addArrangedSubview(editPortfolioButton)
        
        // Layout with NSLayoutConstraint
        NSLayoutConstraint.activate([
            headerTag.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerTag.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerTag.heightAnchor.constraint(equalToConstant: 24),
            headerTag.widthAnchor.constraint(equalToConstant: 120),
            
            bannerImageView.topAnchor.constraint(equalTo: topAnchor),
            bannerImageView.leftAnchor.constraint(equalTo: leftAnchor),
            bannerImageView.rightAnchor.constraint(equalTo: rightAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 140),
            
            shareButton.topAnchor.constraint(equalTo: bannerImageView.topAnchor, constant: 12),
            shareButton.rightAnchor.constraint(equalTo: bannerImageView.rightAnchor, constant: -12),
            shareButton.widthAnchor.constraint(equalToConstant: 40),
            shareButton.heightAnchor.constraint(equalToConstant: 40),
            
            moreButton.topAnchor.constraint(equalTo: bannerImageView.topAnchor, constant: 12),
            moreButton.rightAnchor.constraint(equalTo: shareButton.leftAnchor, constant: -8),
            moreButton.widthAnchor.constraint(equalToConstant: 40),
            moreButton.heightAnchor.constraint(equalToConstant: 40),
            
            profileImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -40),
            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            ringView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 136),
            ringView.heightAnchor.constraint(equalToConstant: 136),
            
            badgeView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            badgeView.rightAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 4),
            badgeView.widthAnchor.constraint(equalToConstant: 30),
            badgeView.heightAnchor.constraint(equalToConstant: 30),
            
            badgeIcon.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            
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
            buttonStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
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
        
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.distribution = .equalSpacing
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        // Projects
        let projectsIcon = UIButton(type: .system)
        projectsIcon.setImage(UIImage(systemName: "film"), for: .normal)
        projectsIcon.tintColor = ActorProfileDS.rosePink
        projectsIcon.backgroundColor = ActorProfileDS.rosePink.withAlphaComponent(0.15)
        projectsIcon.layer.cornerRadius = 25
        projectsIcon.translatesAutoresizingMaskIntoConstraints = false
        projectsIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        projectsIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let projectsLabel = UILabel()
        projectsLabel.text = "Projects"
        projectsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        projectsLabel.textColor = .gray
        projectsLabel.textAlignment = .center
        
        let projectsValue = UILabel()
        projectsValue.text = "0"
        projectsValue.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        projectsValue.textColor = ActorProfileDS.deepPlum
        projectsValue.textAlignment = .center
        projectsValue.tag = 101
        
        let projectsVStack = UIStackView(arrangedSubviews: [projectsIcon, projectsValue, projectsLabel])
        projectsVStack.axis = .vertical
        projectsVStack.spacing = 6
        projectsVStack.alignment = .center
        
        // Rating
        let ratingIcon = UIButton(type: .system)
        ratingIcon.setImage(UIImage(systemName: "star.fill"), for: .normal)
        ratingIcon.tintColor = ActorProfileDS.rosePink
        ratingIcon.backgroundColor = ActorProfileDS.rosePink.withAlphaComponent(0.15)
        ratingIcon.layer.cornerRadius = 25
        ratingIcon.translatesAutoresizingMaskIntoConstraints = false
        ratingIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        ratingIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let ratingLabel = UILabel()
        ratingLabel.text = "Rating"
        ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        ratingLabel.textColor = .gray
        ratingLabel.textAlignment = .center
        
        let ratingValue = UILabel()
        ratingValue.text = "4.9"
        ratingValue.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        ratingValue.textColor = ActorProfileDS.deepPlum
        ratingValue.textAlignment = .center
        
        let ratingVStack = UIStackView(arrangedSubviews: [ratingIcon, ratingValue, ratingLabel])
        ratingVStack.axis = .vertical
        ratingVStack.spacing = 6
        ratingVStack.alignment = .center
        
        // Experience
        let expIcon = UIButton(type: .system)
        expIcon.setImage(UIImage(systemName: "briefcase.fill"), for: .normal)
        expIcon.tintColor = ActorProfileDS.rosePink
        expIcon.backgroundColor = ActorProfileDS.rosePink.withAlphaComponent(0.15)
        expIcon.layer.cornerRadius = 25
        expIcon.translatesAutoresizingMaskIntoConstraints = false
        expIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        expIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let expLabel = UILabel()
        expLabel.text = "Experience"
        expLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        expLabel.textColor = .gray
        expLabel.textAlignment = .center
        
        let expValue = UILabel()
        expValue.text = "—"
        expValue.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        expValue.textColor = ActorProfileDS.deepPlum
        expValue.textAlignment = .center
        expValue.tag = 103
        
        let expVStack = UIStackView(arrangedSubviews: [expIcon, expValue, expLabel])
        expVStack.axis = .vertical
        expVStack.spacing = 6
        expVStack.alignment = .center
        
        mainStack.addArrangedSubview(projectsVStack)
        mainStack.addArrangedSubview(ratingVStack)
        mainStack.addArrangedSubview(expVStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            mainStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            mainStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
    }
}

// MARK: - About Section View

class AboutSectionView: UIView {

    // MARK: - Public Outlets (updated by ActorProfileViewController)
    let bioLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.textColor = .gray
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let specialtiesHeader: UILabel = {
        let l = UILabel()
        l.text = "Specialties"
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let skillsChipsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillProportionally
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let locationValueLabel: UILabel = {
        let l = UILabel()
        l.text = "—"
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = ActorProfileDS.deepPlum
        return l
    }()

    let experienceValueLabel: UILabel = {
        let l = UILabel()
        l.text = "—"
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
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

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "About"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = ActorProfileDS.deepPlum
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        addSubview(bioLabel)
        addSubview(specialtiesHeader)
        addSubview(skillsChipsStack)

        // Location row
        let locIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        locIcon.tintColor = ActorProfileDS.rosePink
        locIcon.translatesAutoresizingMaskIntoConstraints = false
        locIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        locIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let locTitleLabel = UILabel()
        locTitleLabel.text = "Location"
        locTitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        locTitleLabel.textColor = .gray

        let locVStack = UIStackView(arrangedSubviews: [locTitleLabel, locationValueLabel])
        locVStack.axis = .vertical
        locVStack.spacing = 2

        let locHStack = UIStackView(arrangedSubviews: [locIcon, locVStack])
        locHStack.axis = .horizontal
        locHStack.spacing = 8
        locHStack.alignment = .center

        // Experience row
        let expIcon = UIImageView(image: UIImage(systemName: "briefcase.circle.fill"))
        expIcon.tintColor = ActorProfileDS.rosePink
        expIcon.translatesAutoresizingMaskIntoConstraints = false
        expIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        expIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let expTitleLabel = UILabel()
        expTitleLabel.text = "Experience"
        expTitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        expTitleLabel.textColor = .gray

        let expVStack = UIStackView(arrangedSubviews: [expTitleLabel, experienceValueLabel])
        expVStack.axis = .vertical
        expVStack.spacing = 2

        let expHStack = UIStackView(arrangedSubviews: [expIcon, expVStack])
        expHStack.axis = .horizontal
        expHStack.spacing = 8
        expHStack.alignment = .center

        infoStack.axis = .horizontal
        infoStack.spacing = 16
        infoStack.distribution = .fillEqually
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.addArrangedSubview(locHStack)
        infoStack.addArrangedSubview(expHStack)
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
            infoStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    /// Replace skill chips with given list
    func setSkills(_ skills: [String]) {
        skillsChipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for skill in skills {
            let chip = UILabel()
            chip.text = skill
            chip.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            chip.textColor = ActorProfileDS.deepPlum
            chip.backgroundColor = ActorProfileDS.palePink
            chip.layer.cornerRadius = 12
            chip.clipsToBounds = true
            chip.textAlignment = .center
            chip.numberOfLines = 1
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.heightAnchor.constraint(equalToConstant: 28).isActive = true
            skillsChipsStack.addArrangedSubview(chip)
        }
        if skills.isEmpty {
            let noSkill = UILabel()
            noSkill.text = "No specialties listed"
            noSkill.font = UIFont.systemFont(ofSize: 13)
            noSkill.textColor = .gray
            skillsChipsStack.addArrangedSubview(noSkill)
        }
    }
}

// MARK: - Gallery/Portfolio Section

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
            segmentControl.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: - Gallery Collection View Data Source

class GalleryCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    /// Flat list of (mediaUrl, mediaType) from user posts – first media of each post
    var postMediaItems: [(url: String, type: String)] = []

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postMediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryCell.reuseId, for: indexPath) as? GalleryCell
        else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId, for: indexPath)
        }
        let item = postMediaItems[indexPath.item]
        cell.configureWithURL(imageURL: item.url)
        return cell
    }
}

// MARK: - Main Actor Profile ViewController

final class ActorProfileViewController: UIViewController, EditProfileDelegate {

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private var collectionView: UICollectionView?
    private let galleryDataSource = GalleryCollectionViewDataSource()
    private var galleryHeightConstraint: NSLayoutConstraint?

    private var profileData: UserProfileData?
    private var posts: [PostData] = []
        private let userId: UUID?
        private var hasPortfolio: Bool = false
    
    init(userId: UUID? = nil) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.userId = nil
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        setupNavigationBar()
        setupLoadingView()
        setupUI()
        setupLayout()
        loadProfileData()

        // Listen for portfolio creation from PortfolioCreationViewController
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(portfolioCreated),
            name: .portfolioCreated,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupLoadingView() {
        loadingView.color = ActorProfileDS.deepPlum
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadProfileData() {
        Task {
            do {
                loadingView.startAnimating()
                print("🚀 Starting profile data load...")

                let combined: UserProfileData
                if let userId = userId {
                    print("Loading profile for userId: \(userId)")
                    combined = try await ProfileService.shared.fetchUserProfile(userId: userId)
                } else {
                    print("Loading current user profile...")
                    combined = try await ProfileService.shared.fetchCurrentUserProfile()
                }

                let isFirstLoad = self.profileData == nil
                self.profileData = combined
                // Fetch posts for gallery
                self.posts = try await ProfileService.shared.fetchUserPosts(userId: combined.profile.id)

                // Check if the user already has a portfolio (checks portfolios table, not items)
                self.hasPortfolio = await ProfileService.shared.hasPortfolio(userId: combined.profile.id)

                await MainActor.run {
                    self.loadingView.stopAnimating()
                    print("✅ Profile loaded successfully")
                    self.updateUIWithProfileData()
                    if isFirstLoad { self.addAnimations() }
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    let errorMsg = error.localizedDescription
                    print("❌ Error loading profile: \(errorMsg)")
                    print("Full error: \(error)")
                    self.showErrorMessage("Failed to load profile: \(errorMsg)")
                }
            }
        }
    }
    
    private func updateUIWithProfileData() {
        guard let data = profileData else { return }

        // --- Profile Card ---
        if let profileCard = contentStackView.arrangedSubviews.first as? ActorProfileCardView {
            profileCard.nameLabel.text = data.profile.fullName ?? data.profile.username ?? "Profile"
            profileCard.roleLabel.text = formatRoleLabel(data)
            profileCard.connectionsLabel.text = "\(data.profile.connectionCount)"

            if let profilePicUrl = data.profile.profilePictureUrl {
                loadImage(from: profilePicUrl) { image in
                    profileCard.profileImageView.image = image
                }
            }
            if let bannerUrl = data.profile.bannerUrl {
                loadImage(from: bannerUrl) { image in
                    profileCard.bannerImageView.image = image
                }
            }
            profileCard.badgeView.isHidden = !data.profile.isVerified

            // Wire edit buttons (remove stale targets first)
            profileCard.editProfileButton.removeTarget(nil, action: nil, for: .allEvents)
            profileCard.editPortfolioButton.removeTarget(nil, action: nil, for: .allEvents)
            profileCard.editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
            profileCard.editPortfolioButton.addTarget(self, action: #selector(editPortfolioTapped), for: .touchUpInside)

            // Set portfolio button title based on whether portfolio exists
            profileCard.editPortfolioButton.setTitle(hasPortfolio ? "Edit Portfolio" : "Create Portfolio", for: .normal)
        }

        // --- Stats ---
        if let statsView = contentStackView.arrangedSubviews.compactMap({ $0 as? ProfessionalStatsView }).first {
            updateStatsView(statsView, with: data)
        }

        // --- About Section (using direct outlets) ---
        if let aboutView = contentStackView.arrangedSubviews.compactMap({ $0 as? AboutSectionView }).first {
            aboutView.bioLabel.text = data.profile.bio.flatMap { $0.isEmpty ? nil : $0 } ?? "No bio available."

            let skills = data.artistProfile?.skills ?? []
            aboutView.setSkills(skills)

            if let location = data.profile.location, !location.isEmpty {
                aboutView.locationValueLabel.text = location
            } else {
                aboutView.locationValueLabel.text = "Not specified"
            }

            if let yrs = data.artistProfile?.yearsOfExperience {
                aboutView.experienceValueLabel.text = yrs == 1 ? "1 year" : "\(yrs)+ years"
            } else {
                aboutView.experienceValueLabel.text = "Not specified"
            }
        }

        // --- Gallery: show post media images ---
        var mediaItems: [(url: String, type: String)] = []
        for post in posts {
            // Show first media of each post (image preferred, then video thumbnail)
            if let first = post.media.first {
                let url: String
                if first.mediaType == "video", let thumb = first.thumbnailUrl {
                    url = thumb
                } else {
                    url = first.mediaUrl
                }
                mediaItems.append((url: url, type: first.mediaType))
            }
        }
        galleryDataSource.postMediaItems = mediaItems

        // Recalculate collection view height based on item count
        let itemsPerRow: CGFloat = 3
        let spacing: CGFloat = 2
        let totalWidth = UIScreen.main.bounds.width - 24  // account for content stack insets
        let itemWidth = (totalWidth - (itemsPerRow - 1) * spacing) / itemsPerRow
        let rows = max(1, ceil(CGFloat(mediaItems.count) / itemsPerRow))
        let newHeight = rows * itemWidth + (rows - 1) * spacing
        galleryHeightConstraint?.constant = newHeight

        collectionView?.reloadData()
    }
    
    @objc private func editProfileTapped() {
        print("✏️ Edit profile tapped")
        let editVC = EditProfileViewController(
            userId: profileData?.profile.id ?? userId ?? UUID(),
            profileData: profileData
        )
        editVC.delegate = self
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    // MARK: - EditProfileDelegate
    func editProfileDidSave() {
        print("🔄 Profile saved — reloading data from Supabase...")
        loadProfileData()
    }
    
    @objc private func portfolioCreated() {
        print("🎉 Portfolio created — reloading profile and opening portfolio...")
        // Reload so hasPortfolio flips to true and button label updates
        loadProfileData()
        // Immediately show the new portfolio
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let portfolioVC = PortfolioViewController()
            portfolioVC.isOwnProfile = true
            let nav = UINavigationController(rootViewController: portfolioVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
    }

    @objc private func editPortfolioTapped() {
        if hasPortfolio {
            // Portfolio exists — open the portfolio viewer in edit mode
            let portfolioVC = PortfolioViewController()
            portfolioVC.isOwnProfile = true
            let nav = UINavigationController(rootViewController: portfolioVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            // No portfolio — start the creation wizard
            let creationVC = PortfolioCreationViewController()
            let nav = UINavigationController(rootViewController: creationVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    private func updateStatsView(_ statsView: ProfessionalStatsView, with data: UserProfileData) {
        // Use viewWithTag to find labels (tag assigned in ProfessionalStatsView)
        if let projectsValue = statsView.viewWithTag(101) as? UILabel {
            projectsValue.text = "\(data.projectCount)" 
        }
        if let expValue = statsView.viewWithTag(103) as? UILabel {
            if let yearsExp = data.artistProfile?.yearsOfExperience {
                expValue.text = yearsExp == 1 ? "1 yr" : "\(yearsExp)+ yrs"
            } else {
                expValue.text = "—"
            }
        }
    }
    
    private func formatRoleLabel(_ data: UserProfileData) -> String {
        var parts: [String] = []
        
        if let username = data.profile.username {
            parts.append("@\(username)")
        }
        
        if let roles = data.artistProfile?.primaryRoles, !roles.isEmpty {
            parts.append(roles.joined(separator: ", "))
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Optionally pop back
        })
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadProfileData()
        })
        alert.addAction(UIAlertAction(title: "Debug Info", style: .destructive) { _ in
            self.showDebugInfo()
        })
        present(alert, animated: true)
    }
    
    private func showDebugInfo() {
        let debugInfo = """
        Debug Information:
        
        User ID: \(userId?.uuidString ?? "Current User")
        Has Auth Session: \(supabase.auth.currentSession != nil)
        Current User ID: \(supabase.auth.currentSession?.user.id.uuidString ?? "N/A")
        
        Check:
        1. Is user logged in?
        2. Does profile exist in Supabase?
        3. Is internet connection working?
        4. Check console for detailed error logs
        """
        
        let alert = UIAlertController(title: "Debug Info", message: debugInfo, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.string = debugInfo
        })
        present(alert, animated: true)
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = ActorProfileDS.deepPlum
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        // Scroll View
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content Stack
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Profile Card
        let profileCard = ActorProfileCardView()
        profileCard.heightAnchor.constraint(equalToConstant: 420).isActive = true
        contentStackView.addArrangedSubview(profileCard)
        
        // Professional Stats
        let statsView = ProfessionalStatsView()
        statsView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        contentStackView.addArrangedSubview(statsView)
        
        // About
        let aboutView = AboutSectionView()
        contentStackView.addArrangedSubview(aboutView)
        
        // Gallery Header
        let galleryHeader = GalleryHeaderView()
        galleryHeader.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStackView.addArrangedSubview(galleryHeader)

        // Gallery Grid (self-sizing height, not scrollable)
        let itemsPerRow: CGFloat = 3
        let spacing: CGFloat = 2
        let totalWidth = UIScreen.main.bounds.width - 24
        let itemWidth = (totalWidth - (itemsPerRow - 1) * spacing) / itemsPerRow

        let galleryGrid = UICollectionViewFlowLayout()
        galleryGrid.scrollDirection = .vertical
        galleryGrid.minimumInteritemSpacing = spacing
        galleryGrid.minimumLineSpacing = spacing
        galleryGrid.itemSize = CGSize(width: itemWidth, height: itemWidth)

        let galleryCollection = UICollectionView(frame: .zero, collectionViewLayout: galleryGrid)
        galleryCollection.backgroundColor = .clear
        galleryCollection.isScrollEnabled = false
        galleryCollection.translatesAutoresizingMaskIntoConstraints = false
        galleryCollection.dataSource = galleryDataSource
        galleryCollection.delegate = galleryDataSource
        galleryCollection.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseId)
        self.collectionView = galleryCollection
        contentStackView.addArrangedSubview(galleryCollection)

        // Default height for 1 empty row; updated when posts load
        let hConstraint = galleryCollection.heightAnchor.constraint(equalToConstant: itemWidth)
        hConstraint.isActive = true
        galleryHeightConstraint = hConstraint
        
        // Add spacing at bottom
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
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24)
        ])
    }
    
    private func addAnimations() {
        // Fade in animation for main content
        contentStackView.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
            self.contentStackView.alpha = 1
        })
        
        // Scale animation for profile card
        if let profileCard = contentStackView.arrangedSubviews.first {
            profileCard.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                profileCard.transform = .identity
            })
        }
    }
}
