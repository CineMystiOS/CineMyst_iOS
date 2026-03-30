//
//  PortfolioViewController.swift
//  CineMystApp
//
//  Created by user@50 on 23/01/26.
//

import UIKit

class PortfolioViewController: UIViewController {
    
    // MARK: - Properties
    var isOwnProfile = false
    var portfolioId: String? // For viewing other user's portfolio
    private var portfolioData: ActorPortfolioData?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Header
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let contactEmailLabel = UILabel()
    private let socialLinksStack = UIStackView()
    
    // Edit button (only for own profile)
    private let editButton = UIButton(type: .system)
    
    // Section containers
    private let filmsContainer = UIView()
    private let theatreContainer = UIView()
    private let workshopsContainer = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Portfolio"
        
        setupNavigationBar()
        setupScrollView()
        setupUI()
        layoutUI()
        
        fetchPortfolioData()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.backButtonTitle = ""
        
        if isOwnProfile {
            let editNavButton = UIBarButtonItem(
                image: UIImage(systemName: "pencil.circle"),
                style: .plain,
                target: self,
                action: #selector(editBasicInfo)
            )
            navigationItem.rightBarButtonItem = editNavButton
        }
    }
    
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
    
    private func setupUI() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Profile Image
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Bio
        bioLabel.font = .systemFont(ofSize: 15)
        bioLabel.textColor = .secondaryLabel
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 0
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Contact Email
        contactEmailLabel.font = .systemFont(ofSize: 14)
        contactEmailLabel.textColor = .secondaryLabel
        contactEmailLabel.textAlignment = .center
        contactEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Social Links Stack
        socialLinksStack.axis = .horizontal
        socialLinksStack.spacing = 16
        socialLinksStack.distribution = .fillEqually
        socialLinksStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Section Containers
        [filmsContainer, theatreContainer, workshopsContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [profileImageView, nameLabel, bioLabel, contactEmailLabel, socialLinksStack,
         filmsContainer, theatreContainer, workshopsContainer].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func layoutUI() {
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            contactEmailLabel.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 8),
            contactEmailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactEmailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            socialLinksStack.topAnchor.constraint(equalTo: contactEmailLabel.bottomAnchor, constant: 20),
            socialLinksStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            socialLinksStack.heightAnchor.constraint(equalToConstant: 44),
            
            filmsContainer.topAnchor.constraint(equalTo: socialLinksStack.bottomAnchor, constant: 32),
            filmsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filmsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            theatreContainer.topAnchor.constraint(equalTo: filmsContainer.bottomAnchor, constant: 24),
            theatreContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            theatreContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            workshopsContainer.topAnchor.constraint(equalTo: theatreContainer.bottomAnchor, constant: 24),
            workshopsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            workshopsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            workshopsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Fetch Portfolio Data
    private func fetchPortfolioData() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let userId: String
                
                if let portfolioId = portfolioId {
                    // Viewing another user's portfolio - use provided portfolioId
                    // First, fetch the portfolio to get the user_id
                    let portfolioResponse = try await supabase
                        .from("portfolios")
                        .select("user_id")
                        .eq("id", value: portfolioId)
                        .single()
                        .execute()
                    
                    struct PortfolioUserId: Codable {
                        let userId: String
                        enum CodingKeys: String, CodingKey {
                            case userId = "user_id"
                        }
                    }
                    
                    let portfolioUser = try JSONDecoder().decode(PortfolioUserId.self, from: portfolioResponse.data)
                    userId = portfolioUser.userId
                } else {
                    // Viewing own portfolio
                    guard let session = try await AuthManager.shared.currentSession() else {
                        throw NSError(domain: "Auth", code: 401)
                    }
                    userId = session.user.id.uuidString
                }
                
                // Fetch portfolio
                let portfolioResponse = try await supabase
                    .from("portfolios") 
                    .select()
                    .eq("user_id", value: userId)
                    .eq("is_primary", value: true)
                    .execute()
                
                let portfolios = try JSONDecoder().decode([ActorPortfolio].self, from: portfolioResponse.data)
                
                guard let portfolio = portfolios.first else {
                    throw NSError(domain: "Portfolio", code: 404, userInfo: [NSLocalizedDescriptionKey: "Portfolio not found"])
                }
                
                // Fetch portfolio items using PortfolioManager
                let allItems = try await PortfolioManager.shared.fetchPortfolioItems(portfolioId: portfolio.id)
                
                // Filter items by type
                let films = allItems.filter { $0.type == .film || $0.type == .tvShow }
                let theatre = allItems.filter { $0.type == .theatre }
                let workshops = allItems.filter { $0.type == .workshop || $0.type == .training }
                
                // Convert to work items for display
                let filmWorkItems = films.map { ActorPortfolioWorkItem(
                    id: $0.id,
                    portfolioId: $0.portfolioId,
                    type: $0.type.displayName,
                    title: $0.title,
                    year: String($0.year),
                    role: $0.role,
                    description: $0.description,
                    posterUrl: $0.posterUrl
                )}
                
                let theatreWorkItems = theatre.map { ActorPortfolioWorkItem(
                    id: $0.id,
                    portfolioId: $0.portfolioId,
                    type: $0.type.displayName,
                    title: $0.title,
                    year: String($0.year),
                    role: $0.role,
                    description: $0.description,
                    posterUrl: $0.posterUrl
                )}
                
                let workshopWorkItems = workshops.map { ActorPortfolioWorkItem(
                    id: $0.id,
                    portfolioId: $0.portfolioId,
                    type: $0.type.displayName,
                    title: $0.title,
                    year: String($0.year),
                    role: $0.role,
                    description: $0.description,
                    posterUrl: $0.posterUrl
                )}
                
                let data = ActorPortfolioData(
                    portfolio: portfolio,
                    films: filmWorkItems,
                    theatreProductions: theatreWorkItems,
                    workshops: workshopWorkItems
                )
                
                await MainActor.run {
                    self.portfolioData = data
                    self.updateUI(with: data)
                    self.loadingIndicator.stopAnimating()
                }
                
            } catch {
                print("❌ Error fetching portfolio: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError(message: "Failed to load portfolio: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Update UI
    private func updateUI(with data: ActorPortfolioData) {
        // Update header
        nameLabel.text = data.portfolio.stageName ?? "Portfolio"
        bioLabel.text = data.portfolio.bio
        contactEmailLabel.text = "📧 \(data.portfolio.contactEmail)"
        
        // Load profile image if exists
        if let profilePicUrl = data.portfolio.profilePictureUrl,
           let url = URL(string: profilePicUrl) {
            loadImage(from: url, into: profileImageView)
        }
        
        // Setup social links
        setupSocialLinks(data: data)
        
        // Setup sections
        setupFilmsSection(films: data.films)
        setupTheatreSection(productions: data.theatreProductions)
        setupWorkshopsSection(workshops: data.workshops)
    }
    
    private func setupSocialLinks(data: ActorPortfolioData) {
        socialLinksStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        var hasLinks = false
        
        if let instagram = data.portfolio.instagramUrl, !instagram.isEmpty {
            let button = createSocialButton(icon: "📱", title: "Instagram", url: instagram)
            socialLinksStack.addArrangedSubview(button)
            hasLinks = true
        }
        
        if let youtube = data.portfolio.youtubeUrl, !youtube.isEmpty {
            let button = createSocialButton(icon: "📺", title: "YouTube", url: youtube)
            socialLinksStack.addArrangedSubview(button)
            hasLinks = true
        }
        
        if let imdb = data.portfolio.imdbUrl, !imdb.isEmpty {
            let button = createSocialButton(icon: "🎬", title: "IMDb", url: imdb)
            socialLinksStack.addArrangedSubview(button)
            hasLinks = true
        }
        
        socialLinksStack.isHidden = !hasLinks
    }
    
    private func createSocialButton(icon: String, title: String, url: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(icon) \(title)", for: .normal)
        button.backgroundColor = .systemGray6
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.layer.cornerRadius = 8
        button.addAction(UIAction { [weak self] _ in
            self?.openURL(url)
        }, for: .touchUpInside)
        return button
    }
    
    // MARK: - Setup Sections
    private func setupFilmsSection(films: [ActorPortfolioWorkItem]) {
        filmsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let headerView = createSectionHeader(
            title: "🎬 Films & TV",
            action: isOwnProfile ? #selector(addFilm) : nil
        )
        filmsContainer.addSubview(headerView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: filmsContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: filmsContainer.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: filmsContainer.trailingAnchor, constant: -20)
        ])
        
        if films.isEmpty {
            // Show empty state
            let emptyView = createEmptyStateView(
                icon: "🎬",
                title: "No Films Yet",
                subtitle: isOwnProfile ? "Add your film work to showcase your talent" : "No films added yet",
                buttonTitle: isOwnProfile ? "Add Your First Film" : nil,
                action: isOwnProfile ? #selector(addFilm) : nil
            )
            filmsContainer.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                emptyView.leadingAnchor.constraint(equalTo: filmsContainer.leadingAnchor, constant: 20),
                emptyView.trailingAnchor.constraint(equalTo: filmsContainer.trailingAnchor, constant: -20),
                emptyView.bottomAnchor.constraint(equalTo: filmsContainer.bottomAnchor)
            ])
        } else {
            var lastView: UIView = headerView
            for (index, film) in films.enumerated() {
                let filmView = createPortfolioItemView(item: film)
                filmsContainer.addSubview(filmView)
                
                filmView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    filmView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                    filmView.leadingAnchor.constraint(equalTo: filmsContainer.leadingAnchor, constant: 20),
                    filmView.trailingAnchor.constraint(equalTo: filmsContainer.trailingAnchor, constant: -20)
                ])
                
                if index == films.count - 1 {
                    filmView.bottomAnchor.constraint(equalTo: filmsContainer.bottomAnchor).isActive = true
                }
                
                lastView = filmView
            }
        }
    }
    
    private func setupTheatreSection(productions: [ActorPortfolioWorkItem]) {
        theatreContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let headerView = createSectionHeader(
            title: "🎭 Theatre",
            action: isOwnProfile ? #selector(addTheatre) : nil
        )
        theatreContainer.addSubview(headerView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: theatreContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: theatreContainer.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: theatreContainer.trailingAnchor, constant: -20)
        ])
        
        if productions.isEmpty {
            let emptyView = createEmptyStateView(
                icon: "🎭",
                title: "No Theatre Work Yet",
                subtitle: isOwnProfile ? "Share your stage experience" : "No theatre productions added yet",
                buttonTitle: isOwnProfile ? "Add Theatre Production" : nil,
                action: isOwnProfile ? #selector(addTheatre) : nil
            )
            theatreContainer.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                emptyView.leadingAnchor.constraint(equalTo: theatreContainer.leadingAnchor, constant: 20),
                emptyView.trailingAnchor.constraint(equalTo: theatreContainer.trailingAnchor, constant: -20),
                emptyView.bottomAnchor.constraint(equalTo: theatreContainer.bottomAnchor)
            ])
        } else {
            var lastView: UIView = headerView
            for (index, production) in productions.enumerated() {
                let prodView = createPortfolioItemView(item: production)
                theatreContainer.addSubview(prodView)
                
                prodView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    prodView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                    prodView.leadingAnchor.constraint(equalTo: theatreContainer.leadingAnchor, constant: 20),
                    prodView.trailingAnchor.constraint(equalTo: theatreContainer.trailingAnchor, constant: -20)
                ])
                
                if index == productions.count - 1 {
                    prodView.bottomAnchor.constraint(equalTo: theatreContainer.bottomAnchor).isActive = true
                }
                
                lastView = prodView
            }
        }
    }
    
    private func setupWorkshopsSection(workshops: [ActorPortfolioWorkItem]) {
        workshopsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let headerView = createSectionHeader(
            title: "📚 Training & Workshops",
            action: isOwnProfile ? #selector(addWorkshop) : nil
        )
        workshopsContainer.addSubview(headerView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: workshopsContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: workshopsContainer.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: workshopsContainer.trailingAnchor, constant: -20)
        ])
        
        if workshops.isEmpty {
            let emptyView = createEmptyStateView(
                icon: "📚",
                title: "No Training Yet",
                subtitle: isOwnProfile ? "List your workshops and courses" : "No training added yet",
                buttonTitle: isOwnProfile ? "Add Training/Workshop" : nil,
                action: isOwnProfile ? #selector(addWorkshop) : nil
            )
            workshopsContainer.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                emptyView.leadingAnchor.constraint(equalTo: workshopsContainer.leadingAnchor, constant: 20),
                emptyView.trailingAnchor.constraint(equalTo: workshopsContainer.trailingAnchor, constant: -20),
                emptyView.bottomAnchor.constraint(equalTo: workshopsContainer.bottomAnchor)
            ])
        } else {
            var lastView: UIView = headerView
            for (index, workshop) in workshops.enumerated() {
                let workshopView = createPortfolioItemView(item: workshop)
                workshopsContainer.addSubview(workshopView)
                
                workshopView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    workshopView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                    workshopView.leadingAnchor.constraint(equalTo: workshopsContainer.leadingAnchor, constant: 20),
                    workshopView.trailingAnchor.constraint(equalTo: workshopsContainer.trailingAnchor, constant: -20)
                ])
                
                if index == workshops.count - 1 {
                    workshopView.bottomAnchor.constraint(equalTo: workshopsContainer.bottomAnchor).isActive = true
                }
                
                lastView = workshopView
            }
        }
    }
    
    // MARK: - UI Helpers
    private func createPortfolioItemView(item: ActorPortfolioWorkItem) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        
        var lastView: UIView?
        
        // Image View (if poster exists)
        if let posterUrl = item.posterUrl, !posterUrl.isEmpty, let url = URL(string: posterUrl) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 12
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Load image asynchronously
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            imageView.image = image
                        }
                    }
                } catch {
                    print("Failed to load portfolio image: \(error)")
                }
            }
            
            container.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 180)
            ])
            
            lastView = imageView
        }
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Year and Role
        var subtitleText = ""
        if let year = item.year, !year.isEmpty {
            subtitleText = year
        }
        if let role = item.role, !role.isEmpty {
            if !subtitleText.isEmpty {
                subtitleText += " • \(role)"
            } else {
                subtitleText = role
            }
        }
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitleText.isEmpty ? item.type : subtitleText
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        let descLabel = UILabel()
        descLabel.text = item.description
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .tertiaryLabel
        descLabel.numberOfLines = 3
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        if let desc = item.description, !desc.isEmpty {
            container.addSubview(descLabel)
        }
        
        let topOffset = lastView == nil ? 0 : 16
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: lastView?.bottomAnchor ?? container.topAnchor, constant: 16 + CGFloat(topOffset)),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        if let _ = item.description {
            NSLayoutConstraint.activate([
                descLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
                descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
            ])
        } else {
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16).isActive = true
        }
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        return container
    }
    
    private func createSectionHeader(title: String, action: Selector?) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        if let action = action {
            let addButton = UIButton(type: .system)
            addButton.setTitle("+ Add", for: .normal)
            addButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            addButton.addTarget(self, action: action, for: .touchUpInside)
            addButton.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(addButton)
            
            NSLayoutConstraint.activate([
                addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
        }
        
        return container
    }
    
    private func createEmptyStateView(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String?,
        action: Selector?
    ) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 16
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 48)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .tertiaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconLabel)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 32),
            iconLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
        
        if let buttonTitle = buttonTitle, let action = action {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.backgroundColor = UIColor(named: "AccentColor")?.withAlphaComponent(0.1)
            button.setTitleColor(UIColor(named: "AccentColor"), for: .normal)
            button.layer.cornerRadius = 12
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: action, for: .touchUpInside)
            container.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
                button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                button.widthAnchor.constraint(equalToConstant: 200),
                button.heightAnchor.constraint(equalToConstant: 44),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
            ])
        } else {
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32).isActive = true
        }
        
        return container
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                        imageView.tintColor = nil
                    }
                }
            } catch {
                print("❌ Error loading image: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func editBasicInfo() {
        let alert = UIAlertController(
            title: "Edit Portfolio",
            message: "Edit your portfolio information",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func addFilm() {
        guard let portfolioId = portfolioData?.portfolio.id else { return }
        presentAddItemForm(for: .film, portfolioId: portfolioId)
    }
    
    @objc private func addTheatre() {
        guard let portfolioId = portfolioData?.portfolio.id else { return }
        presentAddItemForm(for: .theatre, portfolioId: portfolioId)
    }
    
    @objc private func addWorkshop() {
        guard let portfolioId = portfolioData?.portfolio.id else { return }
        presentAddItemForm(for: .workshop, portfolioId: portfolioId)
    }
    
    private func presentAddItemForm(for type: PortfolioItemType, portfolioId: String) {
        let addVC = AddPortfolioItemViewController()
        addVC.portfolioId = portfolioId
        addVC.itemType = type
        addVC.onItemAdded = { [weak self] _ in
            self?.fetchPortfolioData()
        }
        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }
    
    private func openURL(_ urlString: String) {
        var finalURL = urlString
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            finalURL = "https://" + urlString
        }
        
        if let url = URL(string: finalURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Data Models (Renamed to avoid conflicts)
struct ActorPortfolioData {
    let portfolio: ActorPortfolio
    let films: [ActorPortfolioWorkItem]
    let theatreProductions: [ActorPortfolioWorkItem]
    let workshops: [ActorPortfolioWorkItem]
}

struct ActorPortfolio: Codable {
    let id: String
    let userId: String
    let stageName: String?
    let contactEmail: String
    let alternateEmail: String?
    let bio: String?
    let profilePictureUrl: String?
    let instagramUrl: String?
    let youtubeUrl: String?
    let imdbUrl: String?
    let isPrimary: Bool
    let isPublic: Bool
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stageName = "stage_name"
        case contactEmail = "contact_email"
        case alternateEmail = "alternate_email"
        case bio
        case profilePictureUrl = "profile_picture_url"
        case instagramUrl = "instagram_url"
        case youtubeUrl = "youtube_url"
        case imdbUrl = "imdb_url"
        case isPrimary = "is_primary"
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
}

struct ActorPortfolioWorkItem: Codable {
    let id: String
    let portfolioId: String
    let type: String
    let title: String
    let year: String?
    let role: String?
    let description: String?
    let posterUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case type
        case title
        case year
        case role
        case description
        case posterUrl = "poster_url"
    }
}
