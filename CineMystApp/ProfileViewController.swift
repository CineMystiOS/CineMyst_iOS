//  ProfileViewController.swift
//  CineMystApp
//
//  Created by Devanshi on 11/11/25.
//

import UIKit
import PhotosUI

// MARK: - User Profile Data Model
struct UserProfileData {
    let profile: ProfileRecord
    let artistProfile: ArtistProfileRecord?
    let castingProfile: CastingProfileRecord?
    let email: String
}

final class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties
    var viewingUserId: String? // ID of the user being viewed (nil = current user)
    var isOwnProfile: Bool { viewingUserId == nil }
    private var userIdFromSession: String? // Cache of current user's ID

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // ✅ Add Button (Portfolio Management)
    private let addButton = UIButton()

    // Banner and edit button
    private let bannerImageView = UIImageView()
    private let bannerEditButton = UIButton()

    // Removed coverLabel ("Acting for Life")
    private let profileImageView = UIImageView()

    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let connectionsLabel = UILabel()

    private let connectButton = UIButton(type: .system)
    private let portfolioButton = UIButton(type: .system)

    private let aboutTitle = UILabel()
    private let aboutText = UILabel()

    private let locationIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
    private let experienceIcon = UIImageView(image: UIImage(systemName: "briefcase"))
    private let locationLabel = UILabel()
    private let experienceLabel = UILabel()

    private let segmentControl = UISegmentedControl(items: ["Gallery", "Flicks", "Tagged"])
    private let collectionView: UICollectionView

    private var userPosts: [Post] = [] // ✅ Fetch real posts instead of dummy images
    private var galleryPosts: [Post] = [] // Gallery posts (images only)
    private var flicksPosts: [Post] = [] // Flicks posts (videos only)
    
    // MARK: - Profile Data
    private var userProfile: UserProfileData?
    private var hasPortfolio = false // ✅ Track portfolio state
    private var connectionState: ConnectionState = .notConnected
    private var connectionCount: Int = 0

    // MARK: - Init
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hidesBottomBarWhenPushed = true

        // Cache current user ID
        Task {
            self.userIdFromSession = try? await AuthManager.shared.currentSession()?.user.id.uuidString
        }

        setupNavigationBar()
        setupScrollView()
        setupUI()
        setupAddButton()
        layoutUI()
        
        fetchProfileData()
    }

    // MARK: - Setup Navigation Bar
    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.backButtonTitle = ""

        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .systemBackground
    }

    // MARK: - Setup Scroll View
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Setup UI
    private func setupUI() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        // Banner setup
        bannerImageView.backgroundColor = UIColor.systemGray4 // Default grey
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false

        bannerEditButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        bannerEditButton.tintColor = .white
        bannerEditButton.backgroundColor = UIColor(white: 0, alpha: 0.3)
        bannerEditButton.layer.cornerRadius = 18
        bannerEditButton.translatesAutoresizingMaskIntoConstraints = false
        bannerEditButton.isHidden = !isOwnProfile
        bannerEditButton.addTarget(self, action: #selector(editBannerTapped), for: .touchUpInside)

        // coverLabel removed

        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.text = "..."
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textAlignment = .center

        usernameLabel.text = "..."
        usernameLabel.font = .systemFont(ofSize: 13)
        usernameLabel.textColor = .secondaryLabel
        usernameLabel.textAlignment = .center

        connectionsLabel.text = "0 Connections"
        connectionsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        connectionsLabel.textAlignment = .center
        connectionsLabel.textColor = .secondaryLabel
        connectionsLabel.isUserInteractionEnabled = true
        connectionsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewConnectionsTapped)))

        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 10
        connectButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        connectButton.addTarget(self, action: #selector(connectionButtonTapped), for: .touchUpInside)
        
        // Hide connect button if viewing own profile
        if isOwnProfile {
            connectButton.isHidden = true
        }

        portfolioButton.setTitle("Loading...", for: .normal)
        portfolioButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        portfolioButton.setTitleColor(.white, for: .normal)
        portfolioButton.layer.cornerRadius = 10
        portfolioButton.layer.shadowOpacity = 0.2
        portfolioButton.layer.shadowRadius = 2
        portfolioButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        portfolioButton.addTarget(self, action: #selector(portfolioButtonTapped), for: .touchUpInside)

        aboutTitle.text = "About"
        aboutTitle.font = .systemFont(ofSize: 17, weight: .semibold)

        aboutText.text = "Loading profile information..."
        aboutText.numberOfLines = 0
        aboutText.font = .systemFont(ofSize: 14)

        locationIcon.tintColor = .label
        experienceIcon.tintColor = .label

        locationLabel.text = "..."
        locationLabel.font = .systemFont(ofSize: 13)

        experienceLabel.text = "..."
        experienceLabel.font = .systemFont(ofSize: 13)

        segmentControl.selectedSegmentIndex = 0
        segmentControl.backgroundColor = .clear
        segmentControl.selectedSegmentTintColor = .clear
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.systemPurple, .font: UIFont.boldSystemFont(ofSize: 15)], for: .selected)
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        segmentControl.addTarget(self, action: #selector(segmentDidChange), for: .valueChanged)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")

        [bannerImageView, bannerEditButton, profileImageView, nameLabel, usernameLabel, connectionsLabel,
         connectButton, portfolioButton, aboutTitle, aboutText, locationIcon, experienceIcon,
         locationLabel, experienceLabel, segmentControl, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    }
    
    // MARK: - Setup Add Button (Portfolio Actions Only)
    private func setupAddButton() {
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .label
        addButton.contentVerticalAlignment = .fill
        addButton.contentHorizontalAlignment = .fill
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        // ✅ Only show for own profile when portfolio exists
        addButton.isHidden = !isOwnProfile
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 28),
            addButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    // MARK: - Layout
    private func layoutUI() {
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Banner at top
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 150),

            // Edit button on banner
            bannerEditButton.topAnchor.constraint(equalTo: bannerImageView.topAnchor, constant: 12),
            bannerEditButton.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor, constant: -12),
            bannerEditButton.widthAnchor.constraint(equalToConstant: 36),
            bannerEditButton.heightAnchor.constraint(equalToConstant: 36),

            // Profile image overlaps banner
            profileImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -50),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            connectionsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 6),
            connectionsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Centered portfolio button below profile info
            connectButton.topAnchor.constraint(equalTo: connectionsLabel.bottomAnchor, constant: 16),
            connectButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 140),
            connectButton.heightAnchor.constraint(equalToConstant: 38),

            portfolioButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 12),
            portfolioButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            portfolioButton.widthAnchor.constraint(equalToConstant: 140),
            portfolioButton.heightAnchor.constraint(equalToConstant: 38),

            aboutTitle.topAnchor.constraint(equalTo: portfolioButton.bottomAnchor, constant: 30),
            aboutTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            aboutText.topAnchor.constraint(equalTo: aboutTitle.bottomAnchor, constant: 6),
            aboutText.leadingAnchor.constraint(equalTo: aboutTitle.leadingAnchor),
            aboutText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            locationIcon.topAnchor.constraint(equalTo: aboutText.bottomAnchor, constant: 16),
            locationIcon.leadingAnchor.constraint(equalTo: aboutText.leadingAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 16),
            locationIcon.heightAnchor.constraint(equalToConstant: 16),

            locationLabel.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 6),

            experienceIcon.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            experienceIcon.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -10),
            experienceIcon.widthAnchor.constraint(equalToConstant: 16),
            experienceIcon.heightAnchor.constraint(equalToConstant: 16),

            experienceLabel.centerYAnchor.constraint(equalTo: experienceIcon.centerYAnchor),
            experienceLabel.leadingAnchor.constraint(equalTo: experienceIcon.trailingAnchor, constant: 6),

            segmentControl.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 24),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            collectionView.heightAnchor.constraint(equalToConstant: 600),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Fetch Profile Data
    private func fetchProfileData() {
        loadingIndicator.startAnimating()
        scrollView.alpha = 0.5
        
        Task {
            do {
                print("🔍 Fetching profile data...")
                
                // Determine which user ID to fetch and get email if own profile
                let userId: UUID
                var email: String = ""
                
                if let viewingUserId = viewingUserId {
                    // Viewing another user's profile
                    guard let uuid = UUID(uuidString: viewingUserId) else {
                        throw ProfileError.invalidSession
                    }
                    userId = uuid
                    print("👤 Viewing user: \(viewingUserId)")
                } else {
                    // Viewing own profile
                    guard let session = try await AuthManager.shared.currentSession() else {
                        throw ProfileError.invalidSession
                    }
                    userId = session.user.id
                    email = session.user.email ?? ""
                    print("👤 Viewing own profile. User ID: \(userId)")
                }
                
                let profileResponse = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .execute()
                
                let profileArray = try JSONDecoder().decode([ProfileRecord].self, from: profileResponse.data)
                
                guard let profile = profileArray.first else {
                    throw ProfileError.noProfileFound
                }
                
                print("✅ Profile fetched: \(profile.role)")
                print("   Username: \(profile.username ?? "nil")")
                print("   Full Name: \(profile.fullName ?? "nil")")
                print("   Banner URL: \(profile.bannerUrl ?? "nil")")
                
                var artistProfile: ArtistProfileRecord?
                var castingProfile: CastingProfileRecord?
                
                if profile.role == "artist" {
                    do {
                        let artistResponse = try await supabase
                            .from("artist_profiles")
                            .select()
                            .eq("id", value: userId.uuidString)
                            .execute()
                        
                        let artistArray = try JSONDecoder().decode([ArtistProfileRecord].self, from: artistResponse.data)
                        artistProfile = artistArray.first
                        print("✅ Artist profile fetched")
                    } catch {
                        print("⚠️ No artist profile found: \(error)")
                    }
                } else if profile.role == "casting_professional" {
                    do {
                        let castingResponse = try await supabase
                            .from("casting_profiles")
                            .select()
                            .eq("id", value: userId.uuidString)
                            .execute()
                        
                        let castingArray = try JSONDecoder().decode([CastingProfileRecord].self, from: castingResponse.data)
                        castingProfile = castingArray.first
                        print("✅ Casting profile fetched")
                    } catch {
                        print("⚠️ No casting profile found: \(error)")
                    }
                }
                
                let userData = UserProfileData(
                    profile: profile,
                    artistProfile: artistProfile,
                    castingProfile: castingProfile,
                    email: email
                )
                
                await MainActor.run {
                    self.userProfile = userData
                    self.updateUI(with: userData)
                    
                    // ✅ Load banner image if it exists
                    self.loadBannerImage(from: profile.bannerUrl)
                    
                    // ✅ Fetch user's posts for gallery/flicks sections
                    self.fetchUserPosts(userId: userId.uuidString)
                    
                    // ✅ Check portfolio status and update buttons
                    self.checkAndUpdatePortfolioButton(userId: userId.uuidString)
                    
                    // ✅ Fetch connection state and count for other users
                    self.fetchAndUpdateConnectionState()
                    self.fetchConnectionCount()
                    
                    self.loadingIndicator.stopAnimating()
                    
                    UIView.animate(withDuration: 0.3) {
                        self.scrollView.alpha = 1.0
                    }
                }
                
            } catch {
                print("❌ Error fetching profile: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.scrollView.alpha = 1.0
                    self.showError(message: "Failed to load profile data")
                }
            }
        }
    }

    // MARK: - Update UI with Profile Data
    private func updateUI(with data: UserProfileData) {
        print("🎨 Updating UI with profile data")
        
        let displayName = data.profile.fullName ?? data.email.components(separatedBy: "@").first?.capitalized ?? "User"
        nameLabel.text = displayName
        
        let username = data.profile.username ?? data.email.components(separatedBy: "@").first ?? "user"
        let roleDisplay = data.profile.role == "artist" ? "Professional Actor" : "Casting Professional"
        usernameLabel.text = "@\(username) • \(roleDisplay)"
        
        if let profilePicUrl = data.profile.profilePictureUrl,
           let url = URL(string: profilePicUrl) {
            loadProfileImage(from: url)
        }
        
        if let city = data.profile.locationCity, let state = data.profile.locationState {
            locationLabel.text = "\(city), \(state)"
        } else if let state = data.profile.locationState {
            locationLabel.text = state
        }
        
        if let experience = data.artistProfile?.experienceYears {
            experienceLabel.text = "\(experience) years"
        } else {
            experienceLabel.text = "Experience"
        }
        
        var aboutComponents: [String] = []
        
        if data.profile.role == "artist", let artist = data.artistProfile {
            let stage = artist.careerStage?.capitalized ?? "Professional"
            let roles = artist.primaryRoles.joined(separator: ", ")
            let experience = artist.experienceYears ?? "0"
            
            aboutComponents.append("\(stage) \(roles.lowercased()) with \(experience) years of experience in")
            
            if !artist.skills.isEmpty {
                aboutComponents.append(artist.skills.prefix(3).joined(separator: ", ").lowercased() + ".")
            } else {
                aboutComponents.append("theater, film, and television.")
            }
            
            aboutComponents.append("Passionate about storytelling and bringing characters to life.")
            
        } else if let casting = data.castingProfile {
            let company = casting.companyName ?? "the industry"
            let types = casting.castingTypes.joined(separator: ", ")
            
            aboutComponents.append("Casting professional")
            if !company.isEmpty {
                aboutComponents.append("at \(company).")
            }
            if !types.isEmpty {
                aboutComponents.append("Specializing in \(types.lowercased()).")
            }
            
            if let radius = casting.castingRadius {
                aboutComponents.append("Working within \(radius)km radius.")
            }
        }
        
        aboutText.text = aboutComponents.joined(separator: " ")
        
        print("✅ UI updated successfully")
    }
    
    // MARK: - Load Banner Image
    private func loadBannerImage(from urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            print("⚠️ No banner URL, using default grey")
            bannerImageView.backgroundColor = UIColor.systemGray4
            bannerImageView.image = nil
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.bannerImageView.image = image
                        self.bannerImageView.backgroundColor = .clear
                    }
                    print("✅ Banner image loaded")
                }
            } catch {
                print("❌ Error loading banner image: \(error)")
                await MainActor.run {
                    self.bannerImageView.backgroundColor = UIColor.systemGray4
                    self.bannerImageView.image = nil
                }
            }
        }
    }
    
    // MARK: - Check Portfolio Status and Update Button
    // MARK: - Check Portfolio Status and Update Button
    private func checkAndUpdatePortfolioButton(userId: String) {
        Task {
            do {
                let portfolioResponse = try await supabase
                    .from("portfolios")
                    .select()
                    .eq("user_id", value: userId)
                    .eq("is_primary", value: true)
                    .execute()
                
                struct PortfolioCheck: Codable { let id: String }
                let portfolios = try JSONDecoder().decode([PortfolioCheck].self, from: portfolioResponse.data)
                
                await MainActor.run {
                    self.hasPortfolio = !portfolios.isEmpty
                    
                    if self.isOwnProfile {
                        // Own profile
                        self.portfolioButton.isHidden = false
                        self.connectButton.isHidden = true
                        
                        if self.hasPortfolio {
                            // Own profile WITH portfolio
                            self.portfolioButton.setTitle("Edit Portfolio", for: .normal)
                            self.portfolioButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
                            self.addButton.isHidden = false // ✅ Show + button
                            print("✅ Own profile with portfolio - showing Edit Portfolio + Add button")
                        } else {
                            // Own profile WITHOUT portfolio
                            self.portfolioButton.setTitle("Create Portfolio", for: .normal)
                            self.portfolioButton.backgroundColor = .systemGreen
                            self.addButton.isHidden = true // ✅ Hide + button
                            print("⚠️ Own profile without portfolio - showing Create Portfolio")
                        }
                    } else {
                        // Viewing someone else's profile
                        self.addButton.isHidden = true // ✅ Never show + button for other profiles
                        self.connectButton.isHidden = false
                        
                        if self.hasPortfolio {
                            // Other user HAS portfolio
                            self.portfolioButton.setTitle("View Portfolio", for: .normal)
                            self.portfolioButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
                            self.portfolioButton.isHidden = false
                            print("📖 Viewing other profile with portfolio - showing View Portfolio")
                        } else {
                            // Other user DOES NOT have portfolio
                            self.portfolioButton.isHidden = true // ✅ Hide button completely
                            print("ℹ️ Viewing other profile without portfolio - hiding button")
                        }
                    }
                }
                
            } catch {
                print("⚠️ Could not check portfolio status: \(error)")
                await MainActor.run {
                    self.portfolioButton.setTitle("Create Portfolio", for: .normal)
                    self.addButton.isHidden = true
                }
            }
        }
    }
    // MARK: - Load Profile Image
    private func loadProfileImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImageView.image = image
                        self.profileImageView.tintColor = nil
                    }
                    print("✅ Profile image loaded")
                }
            } catch {
                print("❌ Error loading profile image: \(error)")
            }
        }
    }
    
    // MARK: - Fetch User Posts for Gallery
    private func fetchUserPosts(userId: String) {
        Task {
            do {
                print("📸 Fetching user posts for profile gallery...")
                let posts = try await PostManager.shared.fetchUserPosts(userId: userId, limit: 100)
                
                await MainActor.run {
                    self.userPosts = posts
                    
                    // Separate posts into gallery (images) and flicks (videos)
                    self.galleryPosts = posts.filter { post in
                        post.mediaUrls.contains { $0.type == "image" }
                    }
                    
                    self.flicksPosts = posts.filter { post in
                        post.mediaUrls.contains { $0.type == "video" }
                    }
                    
                    print("✅ Loaded \(self.galleryPosts.count) gallery posts and \(self.flicksPosts.count) flicks")
                    self.collectionView.reloadData()
                }
            } catch {
                print("❌ Error fetching user posts: \(error)")
                await MainActor.run {
                    self.userPosts = []
                    self.galleryPosts = []
                    self.flicksPosts = []
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.fetchProfileData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showSuccess(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Portfolio Actions
    
    @objc private func addButtonTapped() {
        guard userProfile?.profile.id != nil else {
            showError(message: "User profile not loaded")
            return
        }
        
        print("+ Button: Opening portfolio creation form")
        openPortfolioCreationForm()
    }

    @objc private func portfolioButtonTapped() {
        guard let userProfile = userProfile else {
            showError(message: "User profile not loaded")
            return
        }
        
        if isOwnProfile {
            if hasPortfolio {
                // Own profile with portfolio → Edit it
                print("📖 Opening portfolio editor")
                openPortfolioViewer(isOwnProfile: true)
            } else {
                // Own profile without portfolio → Create it
                print("📝 Opening portfolio creation form")
                openPortfolioCreationForm()
            }
        } else {
            if hasPortfolio {
                // Viewing other user's portfolio → View it
                print("📖 Opening portfolio viewer")
                openPortfolioViewer(isOwnProfile: false)
            }
        }
    }

    private func openPortfolioViewer(isOwnProfile: Bool) {
        let portfolioVC = PortfolioViewController()
        portfolioVC.isOwnProfile = isOwnProfile
        portfolioVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(portfolioVC, animated: true)
    }

    private func openPortfolioCreationForm() {
        let creationVC = PortfolioCreationViewController()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .pageSheet
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(portfolioWasCreated),
            name: .portfolioCreated,
            object: nil
        )
        
        present(navController, animated: true)
    }

    @objc private func portfolioWasCreated() {
        guard let userId = userProfile?.profile.id else { return }
        checkAndUpdatePortfolioButton(userId: userId)
        showSuccess(message: "Portfolio created! You can now add your work.")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Banner Edit Action
    @objc private func editBannerTapped() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Segment Control Handler
    @objc private func segmentDidChange() {
        collectionView.reloadData()
    }
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - PHPickerViewControllerDelegate (Banner Upload)
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error loading image: \(error)")
                Task { @MainActor in
                    self.showError(message: "Failed to load image")
                }
                return
            }
            
            guard let image = object as? UIImage else {
                print("❌ Could not convert to UIImage")
                return
            }
            
            Task {
                await self.uploadBannerImage(image)
            }
        }
    }
    
    private func uploadBannerImage(_ image: UIImage) async {
        guard let userId = userProfile?.profile.id else { return }
        
        do {
            loadingIndicator.startAnimating()
            
            // Resize image to reasonable dimensions (1200x300 for banner)
            let resizedImage = image.resized(to: CGSize(width: 1200, height: 300))
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else { return }
            
            let fileName = "banner_\(Date().timeIntervalSince1970).jpg"
            let filePath = "\(userId)/\(fileName)"
            
            print("📤 Uploading banner to: profile-banners/\(filePath)")
            
            let uploadResponse = try await supabase.storage
                .from("profile-banners")
                .upload(path: filePath, file: imageData, options: .init(upsert: false))
            
            print("✅ Banner uploaded: \(uploadResponse)")
            
            let publicURL = try supabase.storage
                .from("profile-banners")
                .getPublicURL(path: filePath)
            
            print("🔗 Banner URL: \(publicURL)")
            
            let updateData: [String: String] = ["banner_url": publicURL.absoluteString]
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Database updated with banner URL")
            
            await MainActor.run {
                self.bannerImageView.image = resizedImage
                self.bannerImageView.backgroundColor = .clear
                
                if var profile = self.userProfile?.profile {
                    profile.bannerUrl = publicURL.absoluteString
                    self.userProfile = UserProfileData(
                        profile: profile,
                        artistProfile: self.userProfile?.artistProfile,
                        castingProfile: self.userProfile?.castingProfile,
                        email: self.userProfile?.email ?? ""
                    )
                }
                
                self.loadingIndicator.stopAnimating()
                self.showSuccess(message: "Banner updated successfully!")
            }
        } catch {
            print("❌ Error uploading banner: \(error)")
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showError(message: "Failed to upload banner: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let selectedTab = segmentControl.titleForSegment(at: segmentControl.selectedSegmentIndex) ?? "Gallery"
        
        switch selectedTab {
        case "Gallery":
            return galleryPosts.count
        case "Flicks":
            return flicksPosts.count
        default: // Tagged
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        
        let selectedTab = segmentControl.titleForSegment(at: segmentControl.selectedSegmentIndex) ?? "Gallery"
        
        var post: Post?
        switch selectedTab {
        case "Gallery":
            post = galleryPosts.indices.contains(indexPath.row) ? galleryPosts[indexPath.row] : nil
        case "Flicks":
            post = flicksPosts.indices.contains(indexPath.row) ? flicksPosts[indexPath.row] : nil
        default:
            break
        }
        
        if let post = post, let firstMedia = post.mediaUrls.first {
            cell.configureWithURL(imageURL: firstMedia.url)
        } else {
            cell.configure(imageName: "profile_image")
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 6) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: - Connection Management
extension ProfileViewController {
    
    private func fetchAndUpdateConnectionState() {
        guard !isOwnProfile, let viewingUserId = viewingUserId else { return }
        
        Task {
            do {
                guard let currentUser = try await AuthManager.shared.currentSession() else { return }
                let currentUserId = currentUser.user.id.uuidString
                
                let state = try await ConnectionManager.shared.getConnectionState(
                    currentUserId: currentUserId,
                    otherUserId: viewingUserId
                )
                
                await MainActor.run {
                    self.connectionState = state
                    self.updateConnectionButtonUI()
                }
            } catch {
                print("❌ Error fetching connection state: \(error)")
            }
        }
    }
    
    private func updateConnectionButtonUI() {
        switch connectionState {
        case .notConnected:
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
            connectButton.isEnabled = true
            
        case .requestSent:
            connectButton.setTitle("Request Sent", for: .normal)
            connectButton.backgroundColor = .systemGray
            connectButton.isEnabled = true
            
        case .requestReceived:
            connectButton.setTitle("Accept Request", for: .normal)
            connectButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
            connectButton.isEnabled = true
            
        case .connected:
            connectButton.setTitle("Connected", for: .normal)
            connectButton.backgroundColor = .systemGreen
            connectButton.isEnabled = true
            
        case .rejected:
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
            connectButton.isEnabled = true
        }
    }
    
    @objc private func connectionButtonTapped() {
        guard let viewingUserId = viewingUserId else { return }
        
        Task {
            do {
                switch connectionState {
                case .notConnected, .rejected:
                    try await ConnectionManager.shared.sendConnectionRequest(to: viewingUserId)
                    self.connectionState = .requestSent
                    
                case .requestSent:
                    try await ConnectionManager.shared.cancelConnectionRequest(to: viewingUserId)
                    self.connectionState = .notConnected
                    
                case .requestReceived:
                    try await ConnectionManager.shared.acceptConnectionRequest(from: viewingUserId)
                    self.connectionState = .connected
                    
                case .connected:
                    showRemoveConnectionAlert(userId: viewingUserId)
                    return
                }
                
                await MainActor.run {
                    self.updateConnectionButtonUI()
                    self.fetchConnectionCount()
                }
            } catch {
                print("❌ Error updating connection: \(error)")
                showAlert(message: "Failed to update connection")
            }
        }
    }
    
    @objc private func viewConnectionsTapped() {
        let userId = viewingUserId ?? userIdFromSession ?? ""
        guard !userId.isEmpty else { return }
        
        let connectionsVC = ConnectionsListViewController()
        connectionsVC.userId = userId
        navigationController?.pushViewController(connectionsVC, animated: true)
    }
    
    private func fetchConnectionCount() {
        Task {
            do {
                let userId = viewingUserId ?? userIdFromSession ?? ""
                guard !userId.isEmpty else { return }
                
                let count = try await ConnectionManager.shared.getConnectionCount(userId: userId)
                
                await MainActor.run {
                    self.connectionCount = count
                    self.connectionsLabel.text = "\(count) Connection\(count == 1 ? "" : "s")"
                }
            } catch {
                print("❌ Error fetching connection count: \(error)")
            }
        }
    }
    
    private func showRemoveConnectionAlert(userId: String) {
        let alert = UIAlertController(title: "Remove Connection?", message: "Are you sure you want to remove this connection?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            Task {
                do {
                    try await ConnectionManager.shared.removeConnection(with: userId)
                    self.connectionState = .notConnected
                    await MainActor.run {
                        self.updateConnectionButtonUI()
                        self.fetchConnectionCount()
                    }
                } catch {
                    print("❌ Error removing connection: \(error)")
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
