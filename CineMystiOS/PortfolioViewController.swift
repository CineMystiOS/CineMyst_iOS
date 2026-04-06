//
//  PortfolioViewController.swift
//  CineMystApp
//
//  Redesigned with cinematic gradient hero + glassmorphism card design
//

import UIKit
import AVKit
import Supabase

// MARK: - Design System
private enum PDS {
    // Gradient colours — deep cinematic purple → warm rose
    static let gradStart  = UIColor(red: 0.07, green: 0.04, blue: 0.18, alpha: 1)   // #120A2E
    static let gradMid    = UIColor(red: 0.28, green: 0.08, blue: 0.28, alpha: 1)   // #471447
    static let gradEnd    = UIColor(red: 0.55, green: 0.15, blue: 0.25, alpha: 1)   // #8C2640
    static let accent     = UIColor(red: 0.95, green: 0.42, blue: 0.47, alpha: 1)   // rose
    static let accentGold = UIColor(red: 1.00, green: 0.80, blue: 0.30, alpha: 1)   // gold
    static let glass      = UIColor.white.withAlphaComponent(0.08)
    static let glassBorder = UIColor.white.withAlphaComponent(0.18)
    static let cardBg     = UIColor(red: 0.10, green: 0.06, blue: 0.20, alpha: 0.85)
    static let textPrimary   = UIColor.white
    static let textSecondary = UIColor.white.withAlphaComponent(0.65)
    static let textTertiary  = UIColor.white.withAlphaComponent(0.40)
}

// MARK: - Section Model
private struct PortfolioSection {
    let icon: String?
    let title: String
    let types: [PortfolioItemType]
    var items: [PortfolioItem]
    let addType: PortfolioItemType
}

// MARK: - PortfolioViewController
class PortfolioViewController: UIViewController {

    // MARK: - Public
    var isOwnProfile = false
    var portfolioId: String?
    var targetUserId: String?

    // MARK: - State
    private var portfolio: PortfolioResponse?
    private var sections: [PortfolioSection] = [
        // These will only be shown for users who use the 'portfolio_items' structured table
    ]

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let gradientLayer = CAGradientLayer()
    private let heroView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let emailLabel = UILabel()
    private let socialStack = UIStackView()
    private let statStack = UIStackView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupNavBar()
        setupScrollView()
        setupHero()
        setupSections()
        setupLoadingIndicator()
        fetchPortfolioData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Background Gradient
    private func setupBackground() {
        gradientLayer.colors = [PDS.gradStart.cgColor, PDS.gradMid.cgColor, PDS.gradEnd.cgColor]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Subtle noise overlay for texture (using a 1-pt alpha tint)
        let overlay = UIView(frame: .zero)
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.18)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Navigation Bar
    private func setupNavBar() {
        title = "Portfolio"
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = PDS.accent

        // Back button
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem = backBtn

        // Share / Edit buttons
        let shareBtn = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain, target: self,
            action: #selector(shareTapped)
        )
        
        if isOwnProfile {
            let editMenu = UIMenu(title: "Portfolio Options", children: [
                UIAction(title: "Edit Details", image: UIImage(systemName: "pencil")) { [weak self] _ in self?.editBasicInfoTapped() },
                UIAction(title: "Share Portfolio", image: UIImage(systemName: "link")) { [weak self] _ in self?.shareTapped() },
                UIAction(title: "Export resume", image: UIImage(systemName: "doc.text")) { [weak self] _ in self?.exportTapped() }
            ])
            let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: editMenu)
            navigationItem.rightBarButtonItems = [moreBtn, shareBtn]
        } else {
            navigationItem.rightBarButtonItem = shareBtn
        }
    }

    // MARK: - Scroll View
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Hero Section
    private func setupHero() {
        heroView.translatesAutoresizingMaskIntoConstraints = false
        heroView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
        contentStack.addArrangedSubview(heroView)

        // Shimmering ring behind avatar
        let ringView = UIView()
        ringView.translatesAutoresizingMaskIntoConstraints = false
        ringView.layer.cornerRadius = 60
        ringView.layer.borderWidth  = 2
        ringView.layer.borderColor  = PDS.accent.cgColor
        ringView.backgroundColor    = .clear
        heroView.addSubview(ringView)

        // Avatar
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = PDS.textSecondary
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 52
        profileImageView.layer.borderWidth   = 3
        profileImageView.layer.borderColor   = PDS.accent.withAlphaComponent(0.8).cgColor
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(profileImageView)

        // Verified badge
        let badgeView = makeGlassTag(icon: "checkmark.seal.fill", text: "Verified Artist", color: PDS.accentGold)
        badgeView.isHidden = true
        badgeView.tag = 900
        heroView.addSubview(badgeView)

        // Name
        nameLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = PDS.textPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(nameLabel)

        // Bio
        bioLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bioLabel.textColor = PDS.textSecondary
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 4
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(bioLabel)

        // Email
        emailLabel.font = UIFont.systemFont(ofSize: 12)
        emailLabel.textColor = PDS.textTertiary
        emailLabel.textAlignment = .center
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(emailLabel)

        // Social links row
        socialStack.axis = .horizontal
        socialStack.spacing = 10
        socialStack.distribution = .equalSpacing
        socialStack.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(socialStack)

        // Stats row
        statStack.axis = .horizontal
        statStack.distribution = .fillEqually
        statStack.spacing = 1
        statStack.translatesAutoresizingMaskIntoConstraints = false
        statStack.layer.cornerRadius = 16
        statStack.clipsToBounds = true
        statStack.backgroundColor = PDS.glassBorder
        heroView.addSubview(statStack)

        // Divider line
        let divider = UIView()
        divider.backgroundColor = PDS.glassBorder
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStack.addArrangedSubview(divider)

        NSLayoutConstraint.activate([
            ringView.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),
            ringView.topAnchor.constraint(equalTo: heroView.topAnchor, constant: 40),
            ringView.widthAnchor.constraint(equalToConstant: 120),
            ringView.heightAnchor.constraint(equalToConstant: 120),

            profileImageView.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 104),
            profileImageView.heightAnchor.constraint(equalToConstant: 104),

            badgeView.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),
            badgeView.topAnchor.constraint(equalTo: ringView.bottomAnchor, constant: 4),

            nameLabel.topAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -24),

            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            bioLabel.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 32),
            bioLabel.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -32),

            emailLabel.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 4),
            emailLabel.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),

            socialStack.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 12),
            socialStack.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),

            statStack.topAnchor.constraint(equalTo: socialStack.bottomAnchor, constant: 12),
            statStack.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
            statStack.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -24),
            statStack.heightAnchor.constraint(equalToConstant: 60),
            statStack.bottomAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Sections (placeholder, filled after data loads)
    private func setupSections() {
        // Will be rebuilt in updateSections()
    }

    private func setupLoadingIndicator() {
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Fetch
    private func fetchPortfolioData() {
        loadingIndicator.startAnimating()
        Task {
            do {
                let session = try? await AuthManager.shared.currentSession()
                let currentUid = session?.user.id.uuidString.lowercased()

                let userId = try await resolveUserId()
                let targetId = userId.lowercased()
                
                // Determine if this is the user's own profile
                await MainActor.run { self.isOwnProfile = (targetId == currentUid) }

                // Fetch portfolio header - Try portfolios table first
                var portfolioResp = try await supabase
                    .from("portfolios")
                    .select()
                    .eq("user_id", value: userId)
                    .eq("is_primary", value: true)
                    .execute()

                var portfolios = try JSONDecoder().decode([PortfolioResponse].self, from: portfolioResp.data)
                
                // Also check actor_portfolios table - Actors often have detailed casting data here
                print("ℹ️ Checking actor_portfolios for userId: \(userId)")
                let actorResp = try await supabase
                    .from("actor_portfolios")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                
                let actorPortfolios = try JSONDecoder().decode([PortfolioResponse].self, from: actorResp.data)
                
                // Merge logic: Combine project history with casting meta
                var finalP: PortfolioResponse? = nil
                var structuredId: String? = nil
                
                if let mainP = portfolios.first {
                    finalP = mainP
                    structuredId = mainP.id
                }
                
                if let actorP = actorPortfolios.first {
                    if finalP == nil {
                        finalP = actorP
                    } else {
                        // We found both. Use actorP for stats/media but keep structuredId for items
                        finalP = actorP
                    }
                }

                guard let p = finalP else { 
                    print("❌ No portfolio found in either table for userId: \(userId)")
                    throw NSError(domain: "Portfolio", code: 404) 
                }

                // Fetch items (use structuredId if available, else p.id)
                let fetchId = structuredId ?? p.id
                print("📦 Fetching items for portfolioId: \(fetchId)")
                let allItems = try await PortfolioManager.shared.fetchPortfolioItems(portfolioId: fetchId)

                await MainActor.run {
                    self.portfolio = p
                    self.loadingIndicator.stopAnimating()
                    self.updateHero(with: p)
                    self.buildSections(items: allItems)
                    self.animateIn()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func resolveUserId() async throws -> String {
        if let pid = portfolioId {
            struct Wrap: Codable { let user_id: String }
            let r = try await supabase.from("portfolios").select("user_id").eq("id", value: pid).single().execute()
            return try JSONDecoder().decode(Wrap.self, from: r.data).user_id
        } else if let uid = targetUserId {
            return uid
        } else {
            guard let session = try await AuthManager.shared.currentSession() else {
                throw NSError(domain: "Auth", code: 401)
            }
            return session.user.id.uuidString
        }
    }

    // MARK: - Update Hero
    private func updateHero(with p: PortfolioResponse) {
        nameLabel.text = p.full_name ?? p.stage_name ?? "Portfolio"
        bioLabel.text  = p.bio
        emailLabel.isHidden = true

        // Avatar resolution: 1. p.profile_picture_url -> 2. first image from mediaItems
        var avatarUrl = p.profile_picture_url
        if (avatarUrl == nil || avatarUrl?.isEmpty == true) {
            avatarUrl = p.mediaItems.first(where: { $0["type"] == "image" })?["url"]
        }

        if let url = avatarUrl.flatMap(URL.init) {
            loadRemoteImage(url: url, into: profileImageView)
        }

        // Social buttons
        socialStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let ig = p.instagram_url, !ig.isEmpty  { socialStack.addArrangedSubview(makeSocialBtn(icon: "camera.fill", label: "Instagram", url: ig)) }
        if let yt = p.youtube_url,   !yt.isEmpty   { socialStack.addArrangedSubview(makeSocialBtn(icon: "play.rectangle.fill", label: "YouTube", url: yt)) }
        if let imdb = p.imdb_url,    !imdb.isEmpty  { socialStack.addArrangedSubview(makeSocialBtn(icon: "film.fill", label: "IMDb", url: imdb)) }
    }

    // MARK: - Build Sections
    private func buildSections(items: [PortfolioItem]) {
        guard let p = portfolio else { return }
        
        // Remove old sections (keep hero + divider = first 2 views)
        while contentStack.arrangedSubviews.count > 2 {
            contentStack.arrangedSubviews.last?.removeFromSuperview()
        }

        // --- 1. MEDIA GALLERY (from actor_portfolios) ---
        let galleryItems = p.mediaItems
        if !galleryItems.isEmpty {
            contentStack.addArrangedSubview(makeMediaGallerySection(galleryItems))
            contentStack.addArrangedSubview(makeSectionSpacer())
        }

        // --- 2. VITAL STATISTICS / PHYSICAL TRAITS ---
        if p.height_cm != nil || p.bust != nil || p.skin_tone != nil {
            contentStack.addArrangedSubview(makeVitalsSection(p))
            contentStack.addArrangedSubview(makeSectionSpacer())
        }

        // --- 3. PROJECT HISTORY SECTIONS ---
        for i in 0..<sections.count {
            sections[i].items = items.filter { sections[i].types.contains($0.type) }
        }
        
        let hasGlobalItems = !items.isEmpty
        if isOwnProfile || hasGlobalItems {
            rebuildStatBar(items: items)
        } else {
            statStack.isHidden = true
        }

        // Add specialized actor sections from actor_portfolios columns if they hold text or JSON
        let actorSections: [(String, AnyCodable?)] = [
            ("FILMS & TV", p.movies),
            ("THEATRE", p.theatre),
            ("ADS & COMMERCIALS", p.advertisement),
            ("WEB SERIES", p.web_series),
            ("TV SERIALS", p.tv_serials),
            ("TELEVISION COMMERCIALS", p.tvc)
        ]
        
        for (idx, (title, content)) in actorSections.enumerated() {
            let formattedList = normalizedProjects(from: content)
            if !formattedList.isEmpty {
                contentStack.addArrangedSubview(makeProjectSectionCard(title: title, projects: formattedList))
                contentStack.addArrangedSubview(makeSectionSpacer())
            } else if isOwnProfile {
                contentStack.addArrangedSubview(makeEmptyActorSection(title: title, tag: idx))
                contentStack.addArrangedSubview(makeSectionSpacer())
            }
        }

        // --- 4. BIOGRAPHY / ADDITIONAL EXPERIENCE ---
        if let exp = p.previous_experience, !exp.isEmpty {
            contentStack.addArrangedSubview(makeExperienceSection(exp))
            contentStack.addArrangedSubview(makeSectionSpacer())
        }

        // Bottom padding
        let pad = UIView()
        pad.translatesAutoresizingMaskIntoConstraints = false
        pad.heightAnchor.constraint(equalToConstant: 80).isActive = true
        contentStack.addArrangedSubview(pad)
    }

    private func rebuildStatBar(items: [PortfolioItem]) {
        statStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let filmCount  = items.filter { $0.type == .film || $0.type == .tvShow || $0.type == .webseries }.count
        let stageCount = items.filter { $0.type == .theatre }.count
        let trainCount = items.filter { $0.type == .workshop || $0.type == .training }.count
        let adCount    = items.filter { $0.type == .commercial }.count

        let stats: [(String, String)] = [
            ("\(filmCount)", "Films"),
            ("\(stageCount)", "Theatre"),
            ("\(trainCount)", "Training"),
            ("\(adCount)", "Ads"),
        ]
        for (val, lbl) in stats {
            statStack.addArrangedSubview(makeStatCell(value: val, label: lbl))
        }
    }

    // MARK: - Section Card Builder
    private func buildSectionCard(section: PortfolioSection, index: Int) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false

        // Glass card container
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = PDS.glass
        card.layer.cornerRadius = 20
        card.layer.borderWidth  = 1
        card.layer.borderColor  = PDS.glassBorder.cgColor
        card.clipsToBounds = true
        wrapper.addSubview(card)

        // Section header row
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 10
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = section.icon
        iconLabel.font = UIFont.systemFont(ofSize: 22)

        let titleLabel = UILabel()
        titleLabel.text = section.title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = PDS.textPrimary

        let countBadge = UILabel()
        countBadge.text = " \(section.items.count) "
        countBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        countBadge.textColor = PDS.gradEnd
        countBadge.backgroundColor = PDS.accentGold
        countBadge.layer.cornerRadius = 8
        countBadge.clipsToBounds = true
        countBadge.textAlignment = .center

        let spacer = UIView(); spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        headerRow.addArrangedSubview(iconLabel)
        headerRow.addArrangedSubview(titleLabel)
        headerRow.addArrangedSubview(countBadge)
        headerRow.addArrangedSubview(spacer)

        if isOwnProfile {
            let addBtn = UIButton(type: .system)
            addBtn.setTitle("+ Add", for: .normal)
            addBtn.setTitleColor(PDS.accent, for: .normal)
            addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            addBtn.tag = index
            addBtn.addTarget(self, action: #selector(addItemTapped(_:)), for: .touchUpInside)
            headerRow.addArrangedSubview(addBtn)
        }

        card.addSubview(headerRow)

        // Content stack for items
        let itemsStack = UIStackView()
        itemsStack.axis = .vertical
        itemsStack.spacing = 12
        itemsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(itemsStack)

        if section.items.isEmpty {
            let emptyView = buildEmptyState(section: section, index: index)
            itemsStack.addArrangedSubview(emptyView)
        } else {
            for item in section.items {
                itemsStack.addArrangedSubview(buildItemRow(item: item))
            }
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -8),

            headerRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            headerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            headerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            itemsStack.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 14),
            itemsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            itemsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            itemsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])

        return wrapper
    }

    // MARK: - Item Row
    private func buildItemRow(item: PortfolioItem) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        row.layer.cornerRadius = 14

        // Poster thumbnail
        let thumb = UIImageView()
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 10
        thumb.backgroundColor = PDS.cardBg
        thumb.image = UIImage(systemName: "film.fill")
        thumb.tintColor = PDS.textTertiary
        thumb.translatesAutoresizingMaskIntoConstraints = false
        if let urlStr = item.posterUrl, let url = URL(string: urlStr) {
            loadRemoteImage(url: url, into: thumb)
        }

        // Type pill
        let typePill = makeTypePill(item.type)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = PDS.textPrimary
        titleLabel.numberOfLines = 2

        // Sub info
        var subParts: [String] = ["\(item.year)"]
        if let role = item.role, !role.isEmpty { subParts.append(role) }
        if let prod = item.productionCompany, !prod.isEmpty { subParts.append(prod) }
        let subLabel = UILabel()
        subLabel.text = subParts.joined(separator: "  •  ")
        subLabel.font = UIFont.systemFont(ofSize: 12)
        subLabel.textColor = PDS.textSecondary

        // Desc
        let descLabel = UILabel()
        descLabel.text = item.description
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = PDS.textTertiary
        descLabel.numberOfLines = 2
        descLabel.isHidden = (item.description?.isEmpty ?? true)

        let textStack = UIStackView(arrangedSubviews: [typePill, titleLabel, subLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(thumb)
        row.addSubview(textStack)

        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            thumb.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 72),
            thumb.heightAnchor.constraint(equalToConstant: 72),

            textStack.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
        ])

        return row
    }

    private func buildEmptyState(section: PortfolioSection, index: Int) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: isOwnProfile ? 100 : 70).isActive = true

        let icon = UILabel()
        icon.text = section.icon
        icon.font = UIFont.systemFont(ofSize: 32)
        icon.textAlignment = .center
        icon.translatesAutoresizingMaskIntoConstraints = false

        let msg = UILabel()
        msg.text = isOwnProfile ? "Nothing here yet — tap + Add to start" : "No \(section.title.lowercased()) added yet"
        msg.font = UIFont.systemFont(ofSize: 13)
        msg.textColor = PDS.textTertiary
        msg.textAlignment = .center
        msg.numberOfLines = 2
        msg.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(icon)
        v.addSubview(msg)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: v.topAnchor, constant: 12),
            icon.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            msg.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 6),
            msg.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            msg.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
        ])
        return v
    }

    // MARK: - Actions
    @objc private func backTapped() {
        if let nav = navigationController {
            // If we are the root of the nav stack it was presented modally —
            // dismiss the whole navigation controller, not just pop (which would be a no-op).
            if nav.viewControllers.first === self {
                nav.dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func editBasicInfoTapped() {
        guard let p = portfolio else { return }
        openBasicInfoEditor(portfolio: p)
    }

    @objc private func shareTapped() {
        guard let p = portfolio else { return }
        let name = p.full_name ?? p.stage_name ?? "Artist"
        let shareText = "Check out \(name)'s portfolio on CineMyst 🎬\n\nhttps://cinemyst.com/portfolio/\(p.id)"
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }

    @objc private func exportTapped() {
        guard let p = portfolio else { return }
        
        // Generate a text-based resume/export summary
        var exportContent = "CINEMYST PORTFOLIO: \(p.full_name?.uppercased() ?? "ARTIST")\n"
        exportContent += "====================================\n\n"
        if let bio = p.bio { exportContent += "BIO: \(bio)\n\n" }
        
        for section in sections {
            if !section.items.isEmpty {
                exportContent += "【 \(section.title.uppercased()) 】\n"
                for item in section.items {
                    exportContent += "- \(item.title) (\(item.year))"
                    if let role = item.role { exportContent += " as \(role)" }
                    exportContent += "\n"
                }
                exportContent += "\n"
            }
        }
        
        exportContent += "Generated via CineMyst 🎬"
        
        let activityVC = UIActivityViewController(activityItems: [exportContent], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }

    @objc private func addItemTapped(_ sender: UIButton) {
        Task {
            do {
                guard let session = try? await AuthManager.shared.currentSession() else { throw NSError(domain: "Auth", code: 401) }
                let myUid = session.user.id.uuidString.lowercased()
                
                let categories = ["movies", "theatre", "advertisement", "web_series", "tv_serials", "tvc"]
                let category = categories[sender.tag]
                
                await MainActor.run {
                    let addVC = AddPortfolioItemViewController()
                    addVC.onItemAdded = { [weak self] item in
                        Task {
                            do {
                                // SECURE ACTOR PERSISTENCE
                                try await PortfolioManager.shared.addActorProject(
                                    userId: myUid,
                                    category: category,
                                    item: PortfolioManager.PortfolioItemInsert(
                                        title: item.title, year: item.year, role: item.role,
                                        production_company: item.productionCompany,
                                        genre: item.genre, description: item.description,
                                        poster_url: item.posterUrl,
                                        media_urls: item.mediaUrls
                                    )
                                )
                                print("✅ Artist project saved successfully, refreshing UI...")
                                await MainActor.run { 
                                    self?.fetchPortfolioData() 
                                }
                            } catch {
                                print("❌ Failed to save artist project: \(error)")
                                await MainActor.run {
                                    let a = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
                                    a.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(a, animated: true)
                                }
                            }
                        }
                    }
                    self.navigationController?.pushViewController(addVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Security Violation", message: error.localizedDescription, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    private func makeEmptyActorSection(title: String, tag: Int) -> UIView {
        let card = UIView(); card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = PDS.glass; card.layer.cornerRadius = 20
        card.layer.borderWidth = 1; card.layer.borderColor = PDS.glassBorder.cgColor
        
        let header = UILabel(); header.text = title.uppercased(); header.font = .systemFont(ofSize: 11, weight: .bold); header.textColor = .white.withAlphaComponent(0.5); header.translatesAutoresizingMaskIntoConstraints = false
        let addBtn = UIButton(type: .system); addBtn.setTitle("+ Add Content", for: .normal); addBtn.setTitleColor(PDS.accent, for: .normal); addBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold); addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtn.tag = tag // CRITICAL FIX: Set section tag
        addBtn.addTarget(self, action: #selector(addItemTapped(_:)), for: .touchUpInside)
        
        card.addSubview(header); card.addSubview(addBtn)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            addBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            addBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: 16)
        ])
        return card
    }

    private func makeTextCard(title: String, body: String) -> UIView {
        let card = UIView(); card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = PDS.glass; card.layer.cornerRadius = 20
        card.layer.borderWidth = 1; card.layer.borderColor = PDS.glassBorder.cgColor
        
        let header = UILabel(); header.text = title.uppercased(); header.font = .systemFont(ofSize: 11, weight: .bold); header.textColor = .white.withAlphaComponent(0.5); header.translatesAutoresizingMaskIntoConstraints = false
        let textLbl = UILabel(); textLbl.text = body; textLbl.font = .systemFont(ofSize: 14); textLbl.textColor = .white; textLbl.numberOfLines = 0; textLbl.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(header); card.addSubview(textLbl)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textLbl.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            textLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 16)
        ])
        return card
    }

    private func openBasicInfoEditor(portfolio: PortfolioResponse) {
        // Show editable fields for basic portfolio info using an alert-driven flow
        let vc = PortfolioBasicInfoEditViewController(portfolio: portfolio)
        vc.onSaved = { [weak self] in self?.fetchPortfolioData() }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Entrance animation
    private func animateIn() {
        contentStack.alpha = 0
        contentStack.transform = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.contentStack.alpha = 1
            self.contentStack.transform = .identity
        }
    }

    private func makeProjectMediaCard(_ dict: [String: Any]) -> UIView {
        let card = UIView(); card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: 160).isActive = true
        card.backgroundColor = PDS.glass; card.layer.cornerRadius = 20; card.clipsToBounds = true
        card.layer.borderWidth = 1; card.layer.borderColor = PDS.glassBorder.cgColor
        
        let poster = UIImageView(); poster.contentMode = .scaleAspectFill; poster.clipsToBounds = true; poster.translatesAutoresizingMaskIntoConstraints = false
        let posterURL = resolvePortfolioMediaURL((dict["poster_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
        let videoURL = resolvePortfolioMediaURL((dict["video_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
        let mediaURL = resolvePortfolioMediaURL((dict["media_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
        let genericURL = resolvePortfolioMediaURL((dict["url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
        let thumbnailURL = resolvePortfolioMediaURL((dict["thumbnail_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
        let nestedMediaURLs = extractMediaURLs(from: dict)
        let mediaCandidates: [String?] = [posterURL, thumbnailURL, videoURL, mediaURL, genericURL]
        let primaryMediaURL = mediaCandidates
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .first ?? nestedMediaURLs.first
        if let primaryMediaURL {
            Task { poster.image = await ImageLoader.shared.image(from: primaryMediaURL) }
        } else {
            poster.backgroundColor = .white.withAlphaComponent(0.05)
        }
        
        let title = UILabel(); title.text = dict["title"] as? String; title.font = .systemFont(ofSize: 12, weight: .bold); title.textColor = .white; title.translatesAutoresizingMaskIntoConstraints = false
        let role  = UILabel(); role.text  = dict["role"] as? String;  role.font  = .systemFont(ofSize: 11); role.textColor = .white.withAlphaComponent(0.7); role.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 2
        role.numberOfLines = 2
        
        card.addSubview(poster); card.addSubview(title); card.addSubview(role)
        NSLayoutConstraint.activate([
            poster.topAnchor.constraint(equalTo: card.topAnchor),
            poster.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            poster.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            poster.heightAnchor.constraint(equalToConstant: 152),
            
            title.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            
            role.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            role.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            role.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            role.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        // If it's a video, add a play indicator
        let lowerCandidates: [String?] = [videoURL, mediaURL, genericURL, posterURL] + nestedMediaURLs.map { Optional($0) }
        let lowerURL = lowerCandidates
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value.lowercased()
            }
            .first ?? ""
        let isVideo = lowerURL.hasSuffix(".mp4") || lowerURL.hasSuffix(".mov") || lowerURL.hasSuffix(".m4v") || lowerURL.contains("video") || lowerURL.contains("youtube.com") || lowerURL.contains("youtu.be")
        if isVideo {
            let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            playIcon.tintColor = .white
            playIcon.translatesAutoresizingMaskIntoConstraints = false
            playIcon.alpha = 0.86
            card.addSubview(playIcon)
            NSLayoutConstraint.activate([
                playIcon.centerXAnchor.constraint(equalTo: poster.centerXAnchor),
                playIcon.centerYAnchor.constraint(equalTo: poster.centerYAnchor),
                playIcon.widthAnchor.constraint(equalToConstant: 30),
                playIcon.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
        
        return card
    }

    private func normalizedProjects(from content: AnyCodable?) -> [[String: Any]] {
        guard let value = content?.value else { return [] }

        if let list = value as? [[String: Any]] {
            return list
        }

        if let list = value as? [[String: AnyCodable]] {
            return list.map { dict in
                var normalized: [String: Any] = [:]
                dict.forEach { key, value in normalized[key] = value.value }
                return normalized
            }
        }

        if let list = value as? [Any] {
            return list.compactMap { item in
                if let dict = item as? [String: Any] {
                    return dict
                }
                if let dict = item as? [String: AnyCodable] {
                    var normalized: [String: Any] = [:]
                    dict.forEach { key, value in normalized[key] = value.value }
                    return normalized
                }
                return nil
            }
        }

        return []
    }

    private func extractMediaURLs(from dict: [String: Any]) -> [String] {
        let possibleKeys = ["media_urls", "media", "assets", "files"]
        var urls: [String] = []

        for key in possibleKeys {
            guard let raw = dict[key] else { continue }

            if let values = raw as? [String] {
                urls.append(contentsOf: values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                continue
            }

            if let values = raw as? [[String: Any]] {
                urls.append(contentsOf: values.compactMap { mediaDict in
                    let candidates = [
                        mediaDict["url"] as? String,
                        mediaDict["video_url"] as? String,
                        mediaDict["media_url"] as? String,
                        mediaDict["thumbnail_url"] as? String,
                        mediaDict["poster_url"] as? String
                    ]
                    return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first
                })
                continue
            }

            if let values = raw as? [[String: AnyCodable]] {
                urls.append(contentsOf: values.compactMap { mediaDict in
                    let candidates = [
                        mediaDict["url"]?.value as? String,
                        mediaDict["video_url"]?.value as? String,
                        mediaDict["media_url"]?.value as? String,
                        mediaDict["thumbnail_url"]?.value as? String,
                        mediaDict["poster_url"]?.value as? String
                    ]
                    return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first
                })
                continue
            }

            if let values = raw as? [Any] {
                urls.append(contentsOf: values.compactMap { item in
                    if let text = item as? String {
                        return text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let mediaDict = item as? [String: Any] {
                        let candidates = [
                            mediaDict["url"] as? String,
                            mediaDict["video_url"] as? String,
                            mediaDict["media_url"] as? String,
                            mediaDict["thumbnail_url"] as? String,
                            mediaDict["poster_url"] as? String
                        ]
                        return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first
                    }
                    if let mediaDict = item as? [String: AnyCodable] {
                        let candidates = [
                            mediaDict["url"]?.value as? String,
                            mediaDict["video_url"]?.value as? String,
                            mediaDict["media_url"]?.value as? String,
                            mediaDict["thumbnail_url"]?.value as? String,
                            mediaDict["poster_url"]?.value as? String
                        ]
                        return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first
                    }
                    return nil
                })
            }
        }

        return urls
            .compactMap { resolvePortfolioMediaURL($0) }
            .filter { !$0.isEmpty }
    }

    private func resolvePortfolioMediaURL(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }

        let knownBuckets = ["portfolio-media", "portfolio-images", "videos", "portfolio_images"]
        for bucket in knownBuckets {
            let prefix = "\(bucket)/"
            if trimmed.hasPrefix(prefix) {
                let path = String(trimmed.dropFirst(prefix.count))
                return try? supabase.storage.from(bucket).getPublicURL(path: path).absoluteString
            }
        }

        if trimmed.contains(".") {
            return try? supabase.storage.from("portfolio-media").getPublicURL(path: trimmed).absoluteString
        }

        return trimmed
    }

    private func makeProjectSectionCard(title: String, projects: [[String: Any]]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = PDS.glass
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = PDS.glassBorder.cgColor

        let sectionTitle = UILabel()
        sectionTitle.text = title
        sectionTitle.font = .systemFont(ofSize: 11, weight: .bold)
        sectionTitle.textColor = .white.withAlphaComponent(0.5)
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.heightAnchor.constraint(equalToConstant: 214).isActive = true

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(sectionTitle)
        card.addSubview(scroll)
        scroll.addSubview(stack)

        for project in projects {
            stack.addArrangedSubview(makeProjectMediaCard(project))
        }

        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            sectionTitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            sectionTitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            scroll.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            scroll.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor)
        ])

        return card
    }

    private func formatProjectContent(_ content: AnyCodable?) -> String {
        guard let value = content?.value else { return "" }
        
        if let text = value as? String, !text.isEmpty {
            return text
        }
        
        // Handle structured JSON array
        if let list = value as? [[String: Any]] {
            return list.map { dict in
                let title = dict["title"] as? String ?? "Untitled"
                let year  = (dict["year"] as? Int).map { String($0) } ?? "..."
                let role  = dict["role"] as? String
                var res = "• \(title) (\(year))"
                if let r = role, !r.isEmpty { res += " as \(r)" }
                return res
            }.joined(separator: "\n")
        }
        
        return ""
    }

    private func makeGlassTag(icon: String, text: String, color: UIColor) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color.withAlphaComponent(0.18)
        v.layer.cornerRadius = 12
        v.layer.borderWidth  = 1
        v.layer.borderColor  = color.withAlphaComponent(0.4).cgColor

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = color
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 14).isActive = true

        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = color

        let row = UIStackView(arrangedSubviews: [img, lbl])
        row.axis = .horizontal
        row.spacing = 4
        row.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: v.topAnchor, constant: 5),
            row.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -5),
            row.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 10),
            row.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -10),
        ])
        return v
    }

    private func makeSocialBtn(icon: String, label: String, url: String) -> UIButton {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = PDS.glass
        config.baseForegroundColor = PDS.textSecondary
        config.image = UIImage(systemName: icon)
        config.imagePadding = 4
        config.title = label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        btn.configuration = config
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        btn.addAction(UIAction { [weak self] _ in self?.openURL(url) }, for: .touchUpInside)
        return btn
    }

    private func makeStatCell(value: String, label: String) -> UIView {
        let v = UIView()
        v.backgroundColor = PDS.glass

        let val = UILabel()
        val.text = value
        val.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        val.textColor = PDS.textPrimary
        val.textAlignment = .center
        val.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = label
        lbl.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        lbl.textColor = PDS.textTertiary
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(val)
        v.addSubview(lbl)
        NSLayoutConstraint.activate([
            val.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            val.topAnchor.constraint(equalTo: v.topAnchor, constant: 10),
            lbl.topAnchor.constraint(equalTo: val.bottomAnchor, constant: 2),
            lbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            lbl.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10),
        ])
        return v
    }

    private func makeTypePill(_ type: PortfolioItemType) -> UIView {
        let colors: [PortfolioItemType: UIColor] = [
            .film: UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1),
            .tvShow: UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1),
            .webseries: UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1),
            .theatre: UIColor(red: 0.9, green: 0.5, blue: 0.8, alpha: 1),
            .workshop: PDS.accentGold,
            .training: PDS.accentGold,
            .commercial: UIColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 1),
        ]
        let color = colors[type] ?? PDS.accent
        let pill = UILabel()
        pill.text = " \(type.displayName.uppercased()) "
        pill.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        pill.textColor = color
        pill.backgroundColor = color.withAlphaComponent(0.15)
        pill.layer.cornerRadius = 4
        pill.clipsToBounds = true
        return pill
    }

    private func loadRemoteImage(url: URL, into imageView: UIImageView) {
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = UIImage(data: data) else { return }
            await MainActor.run { imageView.image = img }
        }
    }

    private func openURL(_ urlString: String) {
        var s = urlString
        if !s.hasPrefix("http") { s = "https://" + s }
        if let url = URL(string: s) { UIApplication.shared.open(url) }
    }

    private func showError(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func makeMediaGallerySection(_ media: [[String: String]]) -> UIView {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.04)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = "PHOTOS & VIDEOS"
        title.font = .systemFont(ofSize: 11, weight: .bold)
        title.textColor = .white.withAlphaComponent(0.5)
        title.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(title)
        
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(scroll)
        
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(hStack)
        
        for item in media {
            let url  = item["url"] ?? ""
            let type = item["type"] ?? "image"
            let resolvedURL = resolvePortfolioMediaURL(url) ?? url
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 12
            iv.backgroundColor = .white.withAlphaComponent(0.05)
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 110).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 140).isActive = true
            if let _ = URL(string: resolvedURL) {
                Task {
                    let img = await ImageLoader.shared.image(from: resolvedURL)
                    await MainActor.run { iv.image = img }
                }
            }
            
            if type == "video" {
                let icon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                icon.tintColor = .white; icon.translatesAutoresizingMaskIntoConstraints = false
                iv.addSubview(icon)
                NSLayoutConstraint.activate([
                    icon.centerXAnchor.constraint(equalTo: iv.centerXAnchor),
                    icon.centerYAnchor.constraint(equalTo: iv.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: 28), icon.heightAnchor.constraint(equalToConstant: 28)
                ])
            }

            let tap = MediaTapGesture(target: self, action: #selector(mediaGalleryItemTapped(_:)))
            tap.item = PortfolioMedia(url: resolvedURL, type: type)
            iv.addGestureRecognizer(tap)
            iv.isUserInteractionEnabled = true
            hStack.addArrangedSubview(iv)
        }
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: v.topAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            
            scroll.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            scroll.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -14),
            scroll.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -12),
            scroll.heightAnchor.constraint(equalToConstant: 140),
            
            hStack.topAnchor.constraint(equalTo: scroll.topAnchor), hStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor), hStack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            hStack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])
        return v
    }

    @objc private func mediaGalleryItemTapped(_ gesture: MediaTapGesture) {
        guard let item = gesture.item else { return }

        if item.type == "video", let url = URL(string: item.url) {
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            present(playerVC, animated: true) { player.play() }
        } else {
            let vc = FullScreenImageViewController(imageURL: item.url)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        }
    }

    private func makeVitalsSection(_ p: PortfolioResponse) -> UIView {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.05)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = "VITAL STATISTICS"
        title.font = .systemFont(ofSize: 11, weight: .bold)
        title.textColor = .white.withAlphaComponent(0.5)
        title.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(title)
        
        let grid = UIStackView()
        grid.axis = .vertical; grid.spacing = 14; grid.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(grid)
        
        func row(_ l1: String, _ v1: String?, _ l2: String, _ v2: String?) -> UIStackView {
            let s = UIStackView()
            s.axis = .horizontal; s.distribution = .fillEqually
            func item(_ l: String, _ val: String?) -> UIView {
                let cnt = UIView(); let ll = UILabel(); let vv = UILabel()
                ll.text = l.uppercased(); ll.font = .systemFont(ofSize: 9, weight: .bold); ll.textColor = .white.withAlphaComponent(0.4)
                vv.text = val ?? "—"; vv.font = .systemFont(ofSize: 14, weight: .semibold); vv.textColor = .white
                ll.translatesAutoresizingMaskIntoConstraints = false; vv.translatesAutoresizingMaskIntoConstraints = false
                cnt.addSubview(ll); cnt.addSubview(vv)
                NSLayoutConstraint.activate([
                    ll.topAnchor.constraint(equalTo: cnt.topAnchor), ll.leadingAnchor.constraint(equalTo: cnt.leadingAnchor),
                    vv.topAnchor.constraint(equalTo: ll.bottomAnchor, constant: 4),
                    vv.leadingAnchor.constraint(equalTo: cnt.leadingAnchor), vv.bottomAnchor.constraint(equalTo: cnt.bottomAnchor)
                ])
                return cnt
            }
            s.addArrangedSubview(item(l1, v1)); s.addArrangedSubview(item(l2, v2))
            return s
        }
        
        grid.addArrangedSubview(row("Age", p.age, "Sex", p.sex))
        grid.addArrangedSubview(row("Height", p.height_cm, "Weight", p.weight_kg))
        grid.addArrangedSubview(row("Bust/Waist/Hips", "\(p.bust ?? "—")/\(p.waist ?? "—")/\(p.hips ?? "—")", "Skin Tone", p.skin_tone))
        grid.addArrangedSubview(row("Eye Color", p.eye_color, "Hair Color", p.hair_color))
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: v.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            grid.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            grid.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            grid.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            grid.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -14)
        ])
        return v
    }

    private func makeExperienceSection(_ text: String) -> UIView {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.05)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel()
        title.text = "BIOGRAPHY & EXPERIENCE"
        title.font = .systemFont(ofSize: 11, weight: .bold)
        title.textColor = .white.withAlphaComponent(0.5)
        title.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(title)
        let body = UILabel(); body.text = text; body.font = .systemFont(ofSize: 14); body.textColor = .white.withAlphaComponent(0.84); body.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        body.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.84),
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraph
            ]
        )
        body.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(body)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: v.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            body.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            body.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            body.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -16)
        ])
        return v
    }

    private func makeSectionSpacer(_ height: CGFloat = 14) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }
}

// MARK: - Basic Info Editor (lightweight inline editor)
class PortfolioBasicInfoEditViewController: UIViewController {
    
    var onSaved: (() -> Void)?
    private let portfolio: PortfolioResponse
    private let bioField = UITextView()
    private let instagramField = UITextField()
    private let youtubeField = UITextField()
    private let imdbField = UITextField()
    
    init(portfolio: PortfolioResponse) {
        self.portfolio = portfolio
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Portfolio"
        navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,   target: self, action: #selector(saveTapped))
        buildUI()
    }
    
    private func buildUI() {
        let scroll = UIScrollView(); scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let content = UIView(); content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])
        
        func sectionHeader(_ text: String) -> UILabel {
            let l = UILabel(); l.text = text
            l.font = .systemFont(ofSize: 12, weight: .semibold)
            l.textColor = .secondaryLabel
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }
        
        let bioHeader = sectionHeader("BIO")
        bioField.text = portfolio.bio ?? ""
        bioField.font = .systemFont(ofSize: 15)
        bioField.backgroundColor = .systemGray6
        bioField.layer.cornerRadius = 10
        bioField.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        bioField.translatesAutoresizingMaskIntoConstraints = false
        
        let socialHeader = sectionHeader("SOCIAL LINKS")
        let fields: [(UITextField, String?, String)] = [
            (instagramField, portfolio.instagram_url, "📱  Instagram URL"),
            (youtubeField,   portfolio.youtube_url,   "📺  YouTube URL"),
            (imdbField,      portfolio.imdb_url,      "🎬  IMDb URL"),
        ]
        for (f, val, placeholder) in fields {
            f.text = val
            f.placeholder = placeholder
            f.borderStyle = .none
            f.backgroundColor = .systemGray6
            f.font = .systemFont(ofSize: 15)
            f.layer.cornerRadius = 10
            f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 44))
            f.leftViewMode = .always
            f.autocapitalizationType = .none
            f.keyboardType = .URL
            f.translatesAutoresizingMaskIntoConstraints = false
            f.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        [bioHeader, bioField, socialHeader, instagramField, youtubeField, imdbField].forEach { content.addSubview($0) }
        
        NSLayoutConstraint.activate([
            bioHeader.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            bioHeader.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            bioField.topAnchor.constraint(equalTo: bioHeader.bottomAnchor, constant: 8),
            bioField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            bioField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            bioField.heightAnchor.constraint(equalToConstant: 120),
            socialHeader.topAnchor.constraint(equalTo: bioField.bottomAnchor, constant: 24),
            socialHeader.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            instagramField.topAnchor.constraint(equalTo: socialHeader.bottomAnchor, constant: 8),
            instagramField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            instagramField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            youtubeField.topAnchor.constraint(equalTo: instagramField.bottomAnchor, constant: 10),
            youtubeField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            youtubeField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            imdbField.topAnchor.constraint(equalTo: youtubeField.bottomAnchor, constant: 10),
            imdbField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            imdbField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            imdbField.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -40),
        ])
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    @objc private func saveTapped() {
        Task {
            do {
                struct PortfolioUpdate: Encodable {
                    let bio: String?
                    let instagram_url: String?
                    let youtube_url: String?
                    let imdb_url: String?
                }
                let update = PortfolioUpdate(
                    bio: bioField.text.isEmpty ? nil : bioField.text,
                    instagram_url: instagramField.text?.isEmpty == true ? nil : instagramField.text,
                    youtube_url:   youtubeField.text?.isEmpty == true ? nil : youtubeField.text,
                    imdb_url:      imdbField.text?.isEmpty == true ? nil : imdbField.text
                )
                try await supabase
                    .from("portfolios")
                    .update(update)
                    .eq("id", value: portfolio.id)
                    .execute()
                
                await MainActor.run {
                    self.onSaved?()
                    self.dismiss(animated: true)
                }
            } catch {
                let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                present(a, animated: true)
            }
        }
    }
}

// MARK: - Image Loader Helper
import AVFoundation

class ImageLoader {
    static let shared = ImageLoader()
    private init() {}
    
    // Cache to prevent redundant processing
    private let cache = NSCache<NSString, UIImage>()
    
    func image(from urlString: String) async -> UIImage? {
        if let cached = cache.object(forKey: urlString as NSString) { return cached }
        
        guard let url = URL(string: urlString) else { return nil }
        
        let lower = urlString.lowercased()
        if lower.contains("youtube.com") || lower.contains("youtu.be") {
            let pattern = "(?i)(?:youtube\\.com\\/(?:[^\\/]+\\/.+\\/|(?:v|e(?:mbed)?)\\/|.*[?&]v=)|youtu\\.be\\/)([^\"&?\\/\\s]{11})"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.utf16.count)),
               let range = Range(match.range(at: 1), in: urlString) {
                let videoId = String(urlString[range])
                let thumbUrlStr = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
                if let thumbUrl = URL(string: thumbUrlStr) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: thumbUrl)
                        if let img = UIImage(data: data) {
                            cache.setObject(img, forKey: urlString as NSString)
                            return img
                        }
                    } catch {}
                }
            }
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.contains("video") {
            // It's a video, generate thumbnail
            if let thumb = await generateThumbnail(url: url) {
                cache.setObject(thumb, forKey: urlString as NSString)
                return thumb
            }
        }
        
        // Default image loading
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                cache.setObject(img, forKey: urlString as NSString)
                return img
            }
        } catch {}
        return nil
    }
    
    private func generateThumbnail(url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        return await withCheckedContinuation { res in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                if let cgImage = image {
                    res.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    res.resume(returning: nil)
                }
            }
        }
    }
}
