//
//  ShortlistedViewController.swift
//  CineMystApp
//
import UIKit
import Supabase

// MARK: - Model
struct ShortlistedCandidate {
    let actorId: UUID
    let name: String
    let location: String
    let daysAgo: String
    let isConnected: Bool
    let profileImageURL: String?
}

// MARK: - Custom Cell
final class ShortlistedCell: UITableViewCell {

    static let id = "ShortlistedCell"
    private let plum = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)

    // MARK: - Subviews
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowRadius = 10
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.masksToBounds = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 26
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.07)
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.15).cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
        iv.image = UIImage(systemName: "person.fill", withConfiguration: config)
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.35)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lbl.textColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let locationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let clockLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let connectedTag: UILabel = {
        let lbl = UILabel()
        lbl.text = "  Connected  "
        lbl.textColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textAlignment = .center
        lbl.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.09)
        lbl.layer.cornerRadius = 9
        lbl.clipsToBounds = true
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let messageButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        btn.setImage(UIImage(systemName: "message", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.09)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    var onChatTapped: (() -> Void)?

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Configure
    func configure(with candidate: ShortlistedCandidate) {
        nameLabel.text = candidate.name
        locationLabel.attributedText = iconText("mappin.and.ellipse", text: candidate.location)
        clockLabel.attributedText = iconText("clock", text: candidate.daysAgo)
        connectedTag.isHidden = !candidate.isConnected

        // Reset to placeholder
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
        profileImageView.image = UIImage(systemName: "person.fill", withConfiguration: cfg)
        profileImageView.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.35)

        if let urlStr = candidate.profileImageURL, !urlStr.isEmpty {
            Task {
                let img = await ImageLoader.shared.image(from: urlStr)
                await MainActor.run {
                    self.profileImageView.image = img
                    self.profileImageView.tintColor = nil
                }
            }
        }
    }

    func setSelection(_ selected: Bool) {
        cardView.layer.borderWidth = selected ? 2 : 0
        cardView.layer.borderColor = selected
            ? UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.6).cgColor
            : UIColor.clear.cgColor
    }

    @objc private func chatTapped() { onChatTapped?() }

    // MARK: Tag + Icon builder
    private func iconText(_ icon: String, text: String) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: icon)?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -2, width: 12, height: 12)
        let attr = NSMutableAttributedString(attachment: attachment)
        attr.append(NSAttributedString(
            string: "  \(text)",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        ))
        return attr
    }

    // MARK: Layout
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(profileImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(locationLabel)
        cardView.addSubview(clockLabel)
        cardView.addSubview(connectedTag)
        cardView.addSubview(messageButton)

        messageButton.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Profile image
            profileImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 52),
            profileImageView.heightAnchor.constraint(equalToConstant: 52),

            // Message button
            messageButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            messageButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            messageButton.widthAnchor.constraint(equalToConstant: 40),
            messageButton.heightAnchor.constraint(equalToConstant: 40),

            // Name — anchored to card top
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: messageButton.leadingAnchor, constant: -8),

            // Location row
            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            // Clock — same row as location
            clockLabel.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            clockLabel.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 12),

            // Connected badge
            connectedTag.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 6),
            connectedTag.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            connectedTag.heightAnchor.constraint(equalToConstant: 20),
            connectedTag.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14),
        ])

        // Ensure card height is driven by content when connectedTag is hidden
        locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16).isActive = true
    }
}



// MARK: - ShortlistedViewController
final class ShortlistedViewController: UIViewController {

    var job: Job?
    var showOnlySelected: Bool = false
    private var tableView = UITableView(frame: .zero, style: .plain)
    private var candidates: [ShortlistedCandidate] = []
    private let backgroundGradient = CAGradientLayer()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "2 applications"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let cueCastLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Cue Cast"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = CineMystTheme.ink
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let hireNowButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Hire This Actor", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 24
        btn.alpha = 0.5
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var selectedActorId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CineMystTheme.pinkPale
        setupTheme()
        setupNavBar()
        setupUI()
        setupTable()
        loadShortlistedCandidates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadShortlistedCandidates() // Refresh when view appears
    }


    // MARK: Navigation Bar
    private func setupNavBar() {

        navigationItem.title = "Cue Cast"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: CineMystTheme.ink,
            .font: UIFont.systemFont(ofSize: 22, weight: .bold)
        ]

        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backAction)
        )

        backBtn.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        navigationItem.leftBarButtonItem = backBtn
    }

    private func setupTheme() {
        backgroundGradient.colors = [
            UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1).cgColor,
            CineMystTheme.plumMist.cgColor,
            UIColor(red: 0.936, green: 0.892, blue: 0.917, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.45, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Load Shortlisted
    private func loadShortlistedCandidates() {
        Task {
            do {
                guard let job = job else {
                    print("❌ No job provided to ShortlistedViewController")
                    return
                }
                
                print("🔍 Loading shortlisted candidates for job: \(job.id.uuidString)")
                
                // Fetch shortlisted/selected applications
                var query = supabase
                    .from("applications")
                    .select()
                    .eq("job_id", value: job.id.uuidString)
                
                if showOnlySelected {
                    query = query.eq("status", value: "selected")
                } else {
                    query = query.in("status", values: ["shortlisted", "selected"])
                }
                
                let shortlistedApps: [Application] = try await query
                    .execute()
                    .value
                
                print("📊 Found \(shortlistedApps.count) shortlisted applications")
                for app in shortlistedApps {
                    print("   - App \(app.id.uuidString.prefix(8)): status=\(app.status.rawValue)")
                }
                
                // Fetch user profiles for all actors
                var userProfiles: [UUID: (name: String, avatarURL: String?)] = [:]
                for app in shortlistedApps {
                    if let profile = try? await self.fetchUserProfile(userId: app.actorId) {
                        userProfiles[app.actorId] = profile
                    }
                }
                
                // Convert to ShortlistedCandidate with real user data
                self.candidates = shortlistedApps.map { app in
                    let userData = userProfiles[app.actorId]
                    return ShortlistedCandidate(
                        actorId: app.actorId,
                        name: userData?.name ?? "Applicant \(app.id.uuidString.prefix(8))",
                        location: "India",
                        daysAgo: self.timeAgoString(from: app.appliedAt),
                        isConnected: false,
                        profileImageURL: userData?.avatarURL
                    )
                }
                
                print("✅ Mapped \(self.candidates.count) candidates")
                
                DispatchQueue.main.async {
                    print("🔄 Updating UI: \(self.candidates.count) applications")
                    self.subtitleLabel.text = "\(self.candidates.count) applications"
                    self.tableView.reloadData()
                    print("✅ TableView reloaded")
                }
            } catch {
                print("❌ Error loading shortlisted candidates: \(error)")
            }
        }
    }
    
    private func fetchUserProfile(userId: UUID) async throws -> (name: String, avatarURL: String?) {
        struct UserProfile: Codable {
            let fullName: String?
            let username: String?
            let avatarUrl: String?
            let profilePictureUrl: String?
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case username
                case avatarUrl = "avatar_url"
                case profilePictureUrl = "profile_picture_url"
            }
        }
        let profile: UserProfile = try await supabase
            .from("profiles")
            .select("full_name, username, avatar_url, profile_picture_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        let name = profile.fullName ?? profile.username ?? "User \(userId.uuidString.prefix(8))"
        let avatarURL = profile.avatarUrl ?? profile.profilePictureUrl
        return (name, avatarURL)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }


    // MARK: UI
    private func setupUI() {
        view.addSubview(cueCastLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(hireNowButton)

        NSLayoutConstraint.activate([
            cueCastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cueCastLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: cueCastLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: cueCastLabel.bottomAnchor, constant: 4),

            hireNowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            hireNowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            hireNowButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            hireNowButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        hireNowButton.addTarget(self, action: #selector(didTapHireNow), for: .touchUpInside)
    }

    private func setupTable() {
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(ShortlistedCell.self, forCellReuseIdentifier: ShortlistedCell.id)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: hireNowButton.topAnchor, constant: -10)
        ])
    }

    @objc private func didTapHireNow() {
        guard let actorId = selectedActorId,
              let candidate = candidates.first(where: { $0.actorId == actorId }) else { return }
        finalizeHiring(candidate: candidate)
    }
    
    // MARK: - Finalize Hiring
    
    private func finalizeHiring(candidate: ShortlistedCandidate) {
        let alert = UIAlertController(
            title: "Finalize Role",
            message: "Are you sure you want to select \(candidate.name) for this role? This will mark the job as completed.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes, Hire", style: .default) { [weak self] _ in
            self?.executeHiring(candidate: candidate)
        })
        
        present(alert, animated: true)
    }
    
    private func executeHiring(candidate: ShortlistedCandidate) {
        Task {
            do {
                guard let job = job else { return }
                
                // 1. Update application status to 'selected'
                try await supabase
                    .from("applications")
                    .update(["status": "selected"])
                    .eq("job_id", value: job.id.uuidString)
                    .eq("actor_id", value: candidate.actorId.uuidString)
                    .execute()
                
                // 2. Update job status to 'completed'
                try await supabase
                    .from("jobs")
                    .update(["status": "completed"])
                    .eq("id", value: job.id.uuidString)
                    .execute()
                
                print("🏆 Hiring finalized for \(candidate.name)!")
                
                await MainActor.run {
                    self.showHiringCelebration(for: candidate)
                }
            } catch {
                print("❌ Hiring failed: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to finalize hiring: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Hiring Celebration

    private func showHiringCelebration(for candidate: ShortlistedCandidate) {
        let plum = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        let gold = UIColor(red: 255/255, green: 196/255, blue: 100/255, alpha: 1)

        // Full-screen overlay
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0)
        overlay.alpha = 0
        view.addSubview(overlay)

        // Card
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 28
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.25
        card.layer.shadowRadius = 30
        card.layer.shadowOffset = CGSize(width: 0, height: 10)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        card.alpha = 0
        overlay.addSubview(card)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            card.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.82),
        ])

        // Gradient bar at top of card
        let gradientBar = CAGradientLayer()
        gradientBar.colors = [plum.cgColor, UIColor(red: 120/255, green: 40/255, blue: 90/255, alpha: 1).cgColor]
        gradientBar.startPoint = CGPoint(x: 0, y: 0)
        gradientBar.endPoint = CGPoint(x: 1, y: 1)
        gradientBar.cornerRadius = 28
        gradientBar.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let gradientBarView = UIView()
        gradientBarView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(gradientBarView)
        NSLayoutConstraint.activate([
            gradientBarView.topAnchor.constraint(equalTo: card.topAnchor),
            gradientBarView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            gradientBarView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            gradientBarView.heightAnchor.constraint(equalToConstant: 110),
        ])

        // Animated checkmark circle
        let checkCircle = UIView()
        checkCircle.backgroundColor = .white
        checkCircle.layer.cornerRadius = 36
        checkCircle.layer.shadowColor = plum.cgColor
        checkCircle.layer.shadowOpacity = 0.3
        checkCircle.layer.shadowRadius = 10
        checkCircle.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(checkCircle)
        NSLayoutConstraint.activate([
            checkCircle.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            checkCircle.topAnchor.constraint(equalTo: gradientBarView.bottomAnchor, constant: -36),
            checkCircle.widthAnchor.constraint(equalToConstant: 72),
            checkCircle.heightAnchor.constraint(equalToConstant: 72),
        ])

        // Checkmark shape
        let checkLayer = CAShapeLayer()
        checkLayer.strokeColor = plum.cgColor
        checkLayer.fillColor = UIColor.clear.cgColor
        checkLayer.lineWidth = 4
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        checkLayer.strokeEnd = 0
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: 20, y: 36))
        checkPath.addLine(to: CGPoint(x: 30, y: 48))
        checkPath.addLine(to: CGPoint(x: 52, y: 24))
        checkLayer.path = checkPath.cgPath
        checkCircle.layer.addSublayer(checkLayer)

        // "Congratulations!" label
        let congLabel = UILabel()
        congLabel.text = "It's a wrap! 🎬"
        congLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        congLabel.textColor = gold
        congLabel.textAlignment = .center
        congLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(congLabel)

        // Actor name label
        let nameLabel = UILabel()
        nameLabel.text = candidate.name
        nameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = plum
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        // Sub label
        let subLabel = UILabel()
        subLabel.text = "has been officially hired\nfor this role."
        subLabel.font = UIFont.systemFont(ofSize: 15)
        subLabel.textColor = UIColor.secondaryLabel
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 2
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subLabel)

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.92, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(divider)

        // Done button
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        doneBtn.backgroundColor = plum
        doneBtn.layer.cornerRadius = 20
        doneBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(doneBtn)

        NSLayoutConstraint.activate([
            congLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            congLabel.topAnchor.constraint(equalTo: checkCircle.bottomAnchor, constant: 14),

            nameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: congLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            subLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            subLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            divider.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 24),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            doneBtn.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            doneBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            doneBtn.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.75),
            doneBtn.heightAnchor.constraint(equalToConstant: 44),
            doneBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])

        // Apply gradient after layout
        DispatchQueue.main.async {
            gradientBar.frame = gradientBarView.bounds
            gradientBarView.layer.insertSublayer(gradientBar, at: 0)
        }

        // Confetti emitter
        let emitter = makeConfetti(in: overlay.bounds, plum: plum, gold: gold)
        overlay.layer.addSublayer(emitter)

        // Done action
        let tapHandler = UIAction { [weak self, weak overlay] _ in
            UIView.animate(withDuration: 0.3, animations: {
                overlay?.alpha = 0
            }, completion: { _ in
                overlay?.removeFromSuperview()
                emitter.removeFromSuperlayer()
                guard let self = self, let nav = self.navigationController else { return }
                if let dashboard = nav.viewControllers.first(where: { $0 is PostedJobsDashboardViewController }) {
                    nav.popToViewController(dashboard, animated: true)
                } else {
                    nav.popViewController(animated: true)
                }
            })
        }
        doneBtn.addAction(tapHandler, for: .touchUpInside)

        // Animate in: overlay fade + card spring
        UIView.animate(withDuration: 0.25) {
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            overlay.alpha = 1
        }
        UIView.animate(
            withDuration: 0.55,
            delay: 0.1,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.5
        ) {
            card.alpha = 1
            card.transform = .identity
        }

        // Animate checkmark stroke after card appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let strokeAnim = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnim.fromValue = 0
            strokeAnim.toValue = 1
            strokeAnim.duration = 0.4
            strokeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            strokeAnim.fillMode = .forwards
            strokeAnim.isRemovedOnCompletion = false
            checkLayer.add(strokeAnim, forKey: "checkStroke")
            checkLayer.strokeEnd = 1

            // Pulse the circle
            let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
            pulse.values = [1.0, 1.15, 0.95, 1.05, 1.0]
            pulse.keyTimes = [0, 0.3, 0.6, 0.8, 1.0]
            pulse.duration = 0.5
            checkCircle.layer.add(pulse, forKey: "pulse")
        }
    }

    private func makeConfetti(in rect: CGRect, plum: UIColor, gold: UIColor) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: rect.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: rect.width, height: 1)

        let colors: [UIColor] = [
            plum, gold,
            UIColor(red: 220/255, green: 120/255, blue: 180/255, alpha: 1),
            UIColor(red: 255/255, green: 220/255, blue: 150/255, alpha: 1),
            UIColor.white
        ]

        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 7
            cell.lifetime = 5.5
            cell.lifetimeRange = 1.5
            cell.velocity = 180
            cell.velocityRange = 60
            cell.emissionRange = .pi / 4
            cell.emissionLongitude = .pi
            cell.spin = 3.5
            cell.spinRange = 2
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.yAcceleration = 120
            cell.color = color.cgColor
            cell.contents = UIImage.confettiRect(size: CGSize(width: 8, height: 5))?.cgImage
            return cell
        }

        return emitter
    }


    // MARK: - Messaging
    
    private func openChatWithApplicant(actorId: UUID, name: String) {
        Task {
            do {
                let conversation = try await MessagesService.shared.getOrCreateConversation(withUserId: actorId)
                
                await MainActor.run {
                    let chatVC = ChatViewController()
                    chatVC.conversationId = conversation.id
                    chatVC.otherUserName = name
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to start conversation: \(error.localizedDescription)")
                }
            }
        }
    }
}


// MARK: - Table Delegate
extension ShortlistedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let candidate = candidates[indexPath.row]
        selectedActorId = candidate.actorId
        
        // Update Hire button state
        hireNowButton.alpha = 1.0
        hireNowButton.isEnabled = true
        
        tableView.reloadData()
    }
}

// MARK: - Table DataSource
extension ShortlistedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("📊 TableView asking for row count: \(candidates.count)")
        return candidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShortlistedCell.id, for: indexPath) as! ShortlistedCell
        let candidate = candidates[indexPath.row]

        cell.configure(with: candidate)
        cell.setSelection(candidate.actorId == selectedActorId)
        cell.selectionStyle = .none
        
        // Set chat button action
        cell.onChatTapped = { [weak self] in
            self?.openChatWithApplicant(actorId: candidate.actorId, name: candidate.name)
        }
        
        return cell
    }
}

// MARK: - Confetti Image Helper
private extension UIImage {
    static func confettiRect(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 1.5).fill()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}
