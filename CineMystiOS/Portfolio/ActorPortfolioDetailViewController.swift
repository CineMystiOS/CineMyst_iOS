//
//  ActorPortfolioDetailViewController.swift
//  CineMystApp
//
//  Displays a full actor portfolio with photos/videos gallery.

import UIKit
import AVKit
import Supabase

// MARK: - Supabase Model

struct ActorPortfolio: Codable {
    let id: String?
    let userId: String?
    let fullName: String?
    let age: String?
    let heightCm: String?
    let weightKg: String?
    let sex: String?
    let currentAddress: String?
    let contactNo: String?
    let emailAddress: String?
    let education: String?
    let maritalStatus: String?
    let currentProfession: String?
    let passport: String?
    let hobbies: String?
    let languages: String?
    let bust: String?
    let waist: String?
    let hips: String?
    let skinTone: String?
    let eyeColor: String?
    let hairColor: String?
    let bodyType: String?
    let anyTattoo: String?
    let armpitHair: String?
    let bodyHair: String?
    let upperLipsHair: String?
    let shoeSize: String?
    let interestedOutstation: String?
    let interestedOutOfCountry: String?
    let comfortableAllTimings: String?
    let dressesComfortableWith: String?
    let printShoot: String?
    let sareesShoot: String?
    let lahangaShoot: String?
    let rampShows: String?
    let designerShoots: String?
    let indianWears: String?
    let traditionalWear: String?
    let casualWear: String?
    let ethnicWears: String?
    let westernWears: String?
    let sportswear: String?
    let nightWears: String?
    let jewellery: String?
    let bikiniShoots: String?
    let lingerieShoots: String?
    let swimSuits: String?
    let calendarShoots: String?
    let musicAlbums: String?
    let acting: String?
    let movies: String?
    let tvc: String?
    let tvSerials: String?
    let kissingScene: String?
    let intimateScenes: String?
    let backlessScene: String?
    let smokingScenes: String?
    let singing: String?
    let dancing: String?
    let anchoring: String?
    let webSeries: String?
    let adjustment: String?
    let shorts: String?
    let topless: String?
    let compromise: String?
    let nude: String?
    let semiNude: String?
    let dustAllergy: String?
    let previousExperience: String?
    let instagramUrl: String?
    let youtubeUrl: String?
    let imdbUrl: String?
    let isPublic: Bool?
    /// JSON array of {url, type} objects stored as text
    let mediaUrls: [PortfolioMedia]?

    enum CodingKeys: String, CodingKey {
        case id, bust, waist, hips, acting, movies, tvc, singing, dancing, anchoring, shorts, nude, compromise, adjustment
        case userId = "user_id"
        case fullName = "full_name"
        case age, sex, education, hobbies, languages, passport
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case currentAddress = "current_address"
        case contactNo = "contact_no"
        case emailAddress = "email_address"
        case maritalStatus = "marital_status"
        case currentProfession = "current_profession"
        case skinTone = "skin_tone"
        case eyeColor = "eye_color"
        case hairColor = "hair_color"
        case bodyType = "body_type"
        case anyTattoo = "any_tattoo"
        case armpitHair = "armpit_hair"
        case bodyHair = "body_hair"
        case upperLipsHair = "upper_lips_hair"
        case shoeSize = "shoe_size"
        case interestedOutstation = "interested_outstation"
        case interestedOutOfCountry = "interested_out_of_country"
        case comfortableAllTimings = "comfortable_all_timings"
        case dressesComfortableWith = "dresses_comfortable_with"
        case printShoot = "print_shoot"
        case sareesShoot = "sarees_shoot"
        case lahangaShoot = "lahanga_shoot"
        case rampShows = "ramp_shows"
        case designerShoots = "designer_shoots"
        case indianWears = "indian_wears"
        case traditionalWear = "traditional_wear"
        case casualWear = "casual_wear"
        case ethnicWears = "ethnic_wears"
        case westernWears = "western_wears"
        case nightWears = "night_wears"
        case jewellery
        case bikiniShoots = "bikini_shoots"
        case lingerieShoots = "lingerie_shoots"
        case swimSuits = "swim_suits"
        case calendarShoots = "calendar_shoots"
        case musicAlbums = "music_albums"
        case tvSerials = "tv_serials"
        case kissingScene = "kissing_scene"
        case intimateScenes = "intimate_scenes"
        case backlessScene = "backless_scene"
        case smokingScenes = "smoking_scenes"
        case webSeries = "web_series"
        case topless, semiNude = "semi_nude"
        case dustAllergy = "dust_allergy"
        case previousExperience = "previous_experience"
        case instagramUrl = "instagram_url"
        case youtubeUrl = "youtube_url"
        case imdbUrl = "imdb_url"
        case isPublic = "is_public"
        case sportswear
        case mediaUrls = "media_urls"
    }
}

struct PortfolioMedia: Codable {
    let url: String
    let type: String   // "image" | "video"
}

// MARK: - View Controller

class ActorPortfolioDetailViewController: UIViewController {

    var targetUserId: UUID?
    var isOwnProfile: Bool = false

    private let scrollView    = UIScrollView()
    private let contentStack  = UIStackView()
    private let gradLayer     = CAGradientLayer()
    private let loader        = UIActivityIndicatorView(style: .large)
    private var portfolio: ActorPortfolio?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupNav()
        setupScrollView()
        setupLoader()
        fetchPortfolio()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradLayer.frame = view.bounds
    }

    // MARK: Setup

    private func setupBackground() {
        gradLayer.colors = [
            UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.04, blue: 0.14, alpha: 1).cgColor,
        ]
        gradLayer.startPoint = .zero
        gradLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradLayer, at: 0)
    }

    private func setupNav() {
        title = "Portfolio"
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        // ✅ Fix: the VC is always the ROOT of a modally-presented nav → must dismiss
        let closeBtn = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain, target: self, action: #selector(closeTapped))
        closeBtn.tintColor = .white
        navigationItem.leftBarButtonItem = closeBtn

        if isOwnProfile {
            let editBtn = UIBarButtonItem(
                title: "Edit", style: .plain, target: self, action: #selector(editTapped))
            editBtn.tintColor = UIColor(red: 0.95, green: 0.55, blue: 0.75, alpha: 1)
            navigationItem.rightBarButtonItem = editBtn
        }
    }

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis         = .vertical
        contentStack.spacing      = 14
        contentStack.distribution = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    private func setupLoader() {
        loader.color = .white
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: Fetch

    private func fetchPortfolio() {
        loader.startAnimating()
        Task {
            do {
                let uid: String
                if let targetUserId = self.targetUserId {
                    uid = targetUserId.uuidString
                } else {
                    guard let session = try await AuthManager.shared.currentSession() else { return }
                    uid = session.user.id.uuidString
                }

                print("📍 Fetching detailed actor portfolio for user: \(uid)")
                let response = try await supabase
                    .from("actor_portfolios")
                    .select()
                    .eq("user_id", value: uid)
                    .execute()

                let decoder = JSONDecoder()
                let portfolios = try decoder.decode([ActorPortfolio].self, from: response.data)
                
                guard let p = portfolios.first else {
                    print("⚠️ No portfolio row found in 'actor_portfolios' for user \(uid)")
                    throw NSError(domain: "Portfolio", code: 404)
                }

                await MainActor.run {
                    self.portfolio = p
                    self.loader.stopAnimating()
                    self.buildUI()
                }
            } catch {
                print("❌ Detail fetch failed: \(error)")
                await MainActor.run {
                    self.loader.stopAnimating()
                    self.showEmpty()
                }
            }
        }
    }

    // MARK: Build UI

    private func buildUI() {
        guard let p = portfolio else { showEmpty(); return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Media gallery — always first if present
        if let media = p.mediaUrls, !media.isEmpty {
            contentStack.addArrangedSubview(makeMediaGallery(media))
        }

        contentStack.addArrangedSubview(makeHeroCard(p))
        contentStack.addArrangedSubview(makeSection(title: "Vital Statistics", rows: [
            ("Bust / Waist / Hips", "\(p.bust ?? "—") / \(p.waist ?? "—") / \(p.hips ?? "—")"),
            ("Skin Tone",       p.skinTone        ?? "—"),
            ("Eye Color",       p.eyeColor        ?? "—"),
            ("Hair Color",      p.hairColor       ?? "—"),
            ("Body Type",       p.bodyType        ?? "—"),
            ("Shoe Size",       p.shoeSize        ?? "—"),
            ("Tattoo",          p.anyTattoo       ?? "—"),
            ("Body Hair",       p.bodyHair        ?? "—"),
            ("Armpit Hair",     p.armpitHair      ?? "—"),
            ("Upper Lips Hair", p.upperLipsHair   ?? "—"),
        ]))
        contentStack.addArrangedSubview(makeSection(title: "Shoot Preferences", rows: [
            ("Outstation Shoot",     p.interestedOutstation   ?? "—"),
            ("Out of Country Shoot", p.interestedOutOfCountry ?? "—"),
            ("All Timings",          p.comfortableAllTimings  ?? "—"),
            ("Dresses Comfortable",  p.dressesComfortableWith ?? "—"),
        ]))
        contentStack.addArrangedSubview(makeInterestsSection(p))
        if let exp = p.previousExperience, !exp.isEmpty {
            contentStack.addArrangedSubview(makeTextCard(title: "Previous Experience", body: exp))
        }
        if p.instagramUrl != nil || p.youtubeUrl != nil || p.imdbUrl != nil {
            contentStack.addArrangedSubview(makeSocialCard(p))
        }
    }

    // MARK: Media Gallery

    private func makeMediaGallery(_ media: [PortfolioMedia]) -> UIView {
        let card = makeCard()
        let title = makeSectionTitle("Photos & Videos")
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let galleryScroll = UIScrollView()
        galleryScroll.showsHorizontalScrollIndicator = false
        galleryScroll.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView()
        hStack.axis    = .horizontal
        hStack.spacing = 10
        hStack.translatesAutoresizingMaskIntoConstraints = false
        galleryScroll.addSubview(hStack)

        for (idx, item) in media.enumerated() {
            let thumb = makeMediaThumb(item: item, index: idx, allMedia: media)
            hStack.addArrangedSubview(thumb)
        }

        card.addSubview(galleryScroll)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            galleryScroll.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            galleryScroll.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            galleryScroll.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            galleryScroll.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            galleryScroll.heightAnchor.constraint(equalToConstant: 160),

            hStack.topAnchor.constraint(equalTo: galleryScroll.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: galleryScroll.bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: galleryScroll.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: galleryScroll.trailingAnchor),
            hStack.heightAnchor.constraint(equalTo: galleryScroll.heightAnchor),
        ])
        return card
    }

    private func makeMediaThumb(item: PortfolioMedia, index: Int, allMedia: [PortfolioMedia]) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 130).isActive = true

        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: container.topAnchor),
            iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        if item.type == "video" {
            // Show play icon overlay
            let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            playIcon.tintColor = .white
            playIcon.contentMode = .scaleAspectFit
            playIcon.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(playIcon)
            NSLayoutConstraint.activate([
                playIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                playIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                playIcon.widthAnchor.constraint(equalToConstant: 40),
                playIcon.heightAnchor.constraint(equalToConstant: 40),
            ])
            // Generate video thumbnail
            DispatchQueue.global(qos: .userInitiated).async {
                guard let url = URL(string: item.url) else { return }
                let asset = AVAsset(url: url)
                let gen = AVAssetImageGenerator(asset: asset)
                gen.appliesPreferredTrackTransform = true
                if let cgImg = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                    let thumb = UIImage(cgImage: cgImg)
                    DispatchQueue.main.async { iv.image = thumb }
                }
            }
        } else {
            // Load image
            if let url = URL(string: item.url) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data, let img = UIImage(data: data) else { return }
                    DispatchQueue.main.async { iv.image = img }
                }.resume()
            }
        }

        // Tap gesture
        let tap = MediaTapGesture(target: self, action: #selector(mediaTapped(_:)))
        tap.item = item
        tap.allMedia = allMedia
        tap.index = index
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func mediaTapped(_ gesture: MediaTapGesture) {
        guard let item = gesture.item else { return }
        if item.type == "video", let url = URL(string: item.url) {
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            present(playerVC, animated: true) { player.play() }
        } else {
            // Full-screen image viewer
            let vc = FullScreenImageViewController(imageURL: item.url)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle   = .crossDissolve
            present(vc, animated: true)
        }
    }

    // MARK: Hero Card

    private func makeHeroCard(_ p: ActorPortfolio) -> UIView {
        let card = makeCard()

        func makeLabel(_ text: String, _ font: UIFont, _ alpha: CGFloat = 1) -> UILabel {
            let l = UILabel()
            l.text = text; l.font = font
            l.textColor = UIColor.white.withAlphaComponent(alpha)
            l.numberOfLines = 0
            return l
        }

        func row(_ label: String, _ value: String?) -> UIStackView {
            let l = makeLabel(label, .systemFont(ofSize: 11, weight: .medium), 0.5)
            let v = makeLabel(value ?? "—", .systemFont(ofSize: 14, weight: .semibold))
            let s = UIStackView(arrangedSubviews: [l, v])
            s.axis = .vertical; s.spacing = 2
            return s
        }

        func grid(_ pairs: [(String, String?)]) -> UIStackView {
            let s = UIStackView(arrangedSubviews: pairs.map { row($0.0, $0.1) })
            s.axis = .horizontal; s.distribution = .fillEqually; s.spacing = 8
            return s
        }

        func divider() -> UIView {
            let v = UIView()
            v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1).isActive = true
            return v
        }

        let nameLabel = makeLabel(p.fullName ?? "Actor Portfolio", .systemFont(ofSize: 24, weight: .bold))

        let vstack = UIStackView(arrangedSubviews: [
            nameLabel, divider(),
            grid([("AGE", p.age), ("SEX", p.sex)]),
            grid([("HEIGHT", p.heightCm), ("WEIGHT", p.weightKg)]),
            grid([("EDUCATION", p.education), ("MARITAL", p.maritalStatus)]),
            grid([("PROFESSION", p.currentProfession), ("PASSPORT", p.passport)]),
            divider(),
            makeLabel("Contact: \(p.contactNo ?? "—")   Email: \(p.emailAddress ?? "—")", .systemFont(ofSize: 13), 0.8),
            makeLabel("Location: \(p.currentAddress ?? "—")", .systemFont(ofSize: 13), 0.7),
            makeLabel("Languages: \(p.languages ?? "—")", .systemFont(ofSize: 13), 0.7),
            makeLabel("Hobbies: \(p.hobbies ?? "—")", .systemFont(ofSize: 13), 0.7),
        ])
        vstack.axis    = .vertical
        vstack.spacing = 10
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])
        return card
    }

    // MARK: Section Card

    private func makeSection(title: String, rows: [(String, String)]) -> UIView {
        let card = makeCard()
        var views: [UIView] = [makeSectionTitle(title)]
        for (k, v) in rows { views.append(makeKVRow(key: k, value: v)) }
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .vertical; s.spacing = 8; s.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(s)
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    // MARK: Interests Grid

    private func makeInterestsSection(_ p: ActorPortfolio) -> UIView {
        let card = makeCard()
        let items: [(String, String?)] = [
            ("Print/Catalog", p.printShoot), ("Sarees", p.sareesShoot),
            ("Lahanga", p.lahangaShoot), ("Ramp Shows", p.rampShows),
            ("Designer", p.designerShoots), ("Indian Wears", p.indianWears),
            ("Traditional", p.traditionalWear), ("Casual Wear", p.casualWear),
            ("Ethnic", p.ethnicWears), ("Western", p.westernWears),
            ("Sports Wear", p.sportswear), ("Night Wear", p.nightWears),
            ("Jewellery", p.jewellery), ("Bikini", p.bikiniShoots),
            ("Lingerie", p.lingerieShoots), ("Swim Suits", p.swimSuits),
            ("Calendar", p.calendarShoots), ("Music Albums", p.musicAlbums),
            ("Acting", p.acting), ("Movies", p.movies),
            ("TVC", p.tvc), ("TV Serials", p.tvSerials),
            ("Kissing", p.kissingScene), ("Intimate", p.intimateScenes),
            ("Backless", p.backlessScene), ("Smoking", p.smokingScenes),
            ("Singing", p.singing), ("Dancing", p.dancing),
            ("Anchoring", p.anchoring), ("Web Series", p.webSeries),
            ("Shorts", p.shorts), ("Topless", p.topless),
            ("Nude", p.nude), ("Semi Nude", p.semiNude),
            ("Dust Allergy", p.dustAllergy),
        ]

        var rows: [[UIView]] = []
        var current: [UIView] = []
        for (name, value) in items {
            current.append(makeChip(name: name, value: value))
            if current.count == 3 {
                rows.append(current); current = []
            }
        }
        if !current.isEmpty { rows.append(current) }

        var rowViews: [UIView] = [makeSectionTitle("Work Interests")]
        for chips in rows {
            let s = UIStackView(arrangedSubviews: chips)
            s.axis = .horizontal; s.spacing = 6; s.distribution = .fillEqually
            rowViews.append(s)
        }

        let vstack = UIStackView(arrangedSubviews: rowViews)
        vstack.axis = .vertical; vstack.spacing = 8; vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func makeChip(name: String, value: String?) -> UILabel {
        let isYes = value == "Yes"
        let chip = UILabel()
        chip.text = "\(isYes ? "✓" : "✗") \(name)"
        chip.font = .systemFont(ofSize: 11, weight: .medium)
        chip.textColor = isYes ? .white : UIColor.white.withAlphaComponent(0.30)
        chip.backgroundColor = isYes ? UIColor.white.withAlphaComponent(0.16) : UIColor.white.withAlphaComponent(0.04)
        chip.layer.cornerRadius = 10
        chip.clipsToBounds = true
        chip.textAlignment = .center
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return chip
    }

    // MARK: Text Card

    private func makeTextCard(title: String, body: String) -> UIView {
        let card = makeCard()
        let bodyLabel = UILabel()
        bodyLabel.text = body; bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        bodyLabel.numberOfLines = 0
        let s = UIStackView(arrangedSubviews: [makeSectionTitle(title), bodyLabel])
        s.axis = .vertical; s.spacing = 10; s.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(s)
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    // MARK: Social Card

    private func makeSocialCard(_ p: ActorPortfolio) -> UIView {
        let card = makeCard()
        var rows: [UIView] = [makeSectionTitle("Social Presence")]
        if let ig = p.instagramUrl, !ig.isEmpty { rows.append(makeKVRow(key: "Instagram", value: ig)) }
        if let yt = p.youtubeUrl, !yt.isEmpty   { rows.append(makeKVRow(key: "YouTube", value: yt)) }
        if let im = p.imdbUrl, !im.isEmpty       { rows.append(makeKVRow(key: "IMDb", value: im)) }
        let s = UIStackView(arrangedSubviews: rows)
        s.axis = .vertical; s.spacing = 8; s.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(s)
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    // MARK: Empty State

    private func showEmpty() {
        let label = UILabel()
        label.text = "No portfolio found.\nTap 'Create Portfolio' on your profile."
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.numberOfLines = 0; label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    // MARK: Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        v.layer.cornerRadius = 18
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.18).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text; l.font = .systemFont(ofSize: 16, weight: .bold); l.textColor = .white
        return l
    }

    private func makeKVRow(key: String, value: String) -> UIView {
        let kl = UILabel()
        kl.text = key; kl.font = .systemFont(ofSize: 12, weight: .medium)
        kl.textColor = UIColor.white.withAlphaComponent(0.5)
        kl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let vl = UILabel()
        vl.text = value; vl.font = .systemFont(ofSize: 13, weight: .semibold)
        vl.textColor = .white; vl.textAlignment = .right; vl.numberOfLines = 0
        vl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let s = UIStackView(arrangedSubviews: [kl, vl])
        s.axis = .horizontal; s.spacing = 8; s.alignment = .top; s.distribution = .fill
        return s
    }

    // MARK: Actions

    @objc private func editTapped() {
        let vc = PortfolioCreationViewController()
        vc.isEditingEnabled = true
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    /// ✅ Fixed: dismiss the modally-presented nav controller
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Custom Tap Gesture (carries media context)

class MediaTapGesture: UITapGestureRecognizer {
    var item: PortfolioMedia?
    var allMedia: [PortfolioMedia] = []
    var index: Int = 0
}

// MARK: - Full Screen Image Viewer

class FullScreenImageViewController: UIViewController {
    private let imageURL: String
    private let imageView = UIImageView()

    init(imageURL: String) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        view.addGestureRecognizer(tap)

        if let url = URL(string: imageURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.imageView.image = img }
            }.resume()
        }
    }

    @objc private func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
}
