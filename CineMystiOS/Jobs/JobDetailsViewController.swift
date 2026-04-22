import UIKit
import Supabase

class JobDetailsViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    private var associatedTask: JobTask?
    
    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundGradient = CAGradientLayer()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Details"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = CineMystTheme.ink
        return lbl
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = CineMystTheme.brandPlum
        button.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        button.layer.cornerRadius = 24
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.16).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 20
        button.layer.shadowOffset = CGSize(width: 0, height: 10)
        return button
    }()
    
    private let applyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Checking Task...", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 16
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.backgroundColor = CineMystTheme.brandPlum
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        btn.layer.shadowOpacity = 0.28
        btn.layer.shadowRadius = 14
        btn.layer.shadowOffset = CGSize(width: 0, height: 8)
        return btn
    }()

    // Profile Data
    private var productionHouseName: String?
    private var profilePictureUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        navigationItem.hidesBackButton = true
        setupBackground()
        setupLayout()
        setupScrollView()
        
        applyButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        Task {
            await checkTaskStatus()
            await fetchCompanyInfo()
            await MainActor.run {
                self.buildContentCards()
            }
        }
    }
    
    private func fetchCompanyInfo() async {
        guard let directorId = job?.directorId else { return }
        do {
            let directorProfile = try await ProfileService.shared.fetchUserProfile(userId: directorId)
            
            struct CastingProfile: Codable {
                let companyName: String?
                let productionHouse: String?
                enum CodingKeys: String, CodingKey { 
                    case companyName = "company_name" 
                    case productionHouse = "production_house"
                }
            }
            if let prof = try? await supabase.from("casting_profiles")
                .select("company_name, production_house")
                .eq("id", value: directorId.uuidString)
                .single().execute().value as CastingProfile {
                productionHouseName = prof.productionHouse ?? prof.companyName
            }
            
            if let urlStr = directorProfile.profile.profilePictureUrl {
                profilePictureUrl = URL(string: urlStr)
            }
        } catch {
            print("Failed to fetch company info: \(error)")
        }
    }

    private func checkTaskStatus() {
        guard let job = job else { return }
        
        Task {
            do {
                let task = try await JobsService.shared.fetchTaskForJob(jobId: job.id)
                await MainActor.run {
                    self.associatedTask = task
                    self.updateCTAButton()
                }
            } catch {
                await MainActor.run {
                    self.applyButton.setTitle("Apply Now", for: .normal)
                }
            }
        }
    }

    private func updateCTAButton() {
        if associatedTask != nil {
            applyButton.setTitle("Go to Task", for: .normal)
            applyButton.backgroundColor = CineMystTheme.brandPlum
            applyButton.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        } else {
            applyButton.setTitle("Apply Now", for: .normal)
            applyButton.backgroundColor = CineMystTheme.brandPlum
            applyButton.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        }
    }

    @objc private func ctaTapped() {
        guard let job = job else { return }
        
        if let task = associatedTask {
            // GO TO TASK flow
            let vc = TaskDetailsViewController()
            vc.job = job
            vc.task = task
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // SIMPLE APPLY flow -> Submit Portfolio directly
            submitPortfolioAndComplete()
        }
    }

    private func submitPortfolioAndComplete() {
        guard let job = job,
              let currentUser = supabase.auth.currentUser else { return }
        
        applyButton.isEnabled = false
        applyButton.setTitle("Applying...", for: .normal)
        
        _Concurrency.Task {
            do {
                let actorId = currentUser.id
                
                // 1. Check for existing apps
                let existing: [Application] = try await supabase
                    .from("applications")
                    .select()
                    .eq("job_id", value: job.id.uuidString)
                    .eq("actor_id", value: actorId.uuidString)
                    .execute()
                    .value
                
                if let app = existing.first {
                    // Update
                    let updated = Application(
                        id: app.id,
                        jobId: app.jobId,
                        actorId: app.actorId,
                        status: .portfolioSubmitted,
                        portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                        portfolioSubmittedAt: Date(),
                        appliedAt: app.appliedAt,
                        updatedAt: Date()
                    )
                    _ = try await supabase.from("applications").update(updated).eq("id", value: app.id.uuidString).execute()
                } else {
                    // New
                    let newApp = Application(
                        id: UUID(),
                        jobId: job.id,
                        actorId: actorId,
                        status: .portfolioSubmitted,
                        portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                        portfolioSubmittedAt: Date(),
                        appliedAt: Date(),
                        updatedAt: Date()
                    )
                    _ = try await supabase.from("applications").insert(newApp).execute()
                }
                
                await MainActor.run {
                    self.showSuccess()
                }
            } catch {
                await MainActor.run {
                    self.applyButton.isEnabled = true
                    self.applyButton.setTitle("Apply Now", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "Applied!", message: "Your portfolio has been sent to the director.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = true
        buildContentCards()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    private func setupBackground() {
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

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        NSLayoutConstraint.activate([
            // Start below our custom header
            scrollView.topAnchor.constraint(equalTo: topHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -10),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private let topHeaderView = UIView()

    private func setupLayout() {
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topHeaderView)
        
        topHeaderView.addSubview(backButton)
        topHeaderView.addSubview(titleLabel)
        view.addSubview(applyButton)
        
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topHeaderView.heightAnchor.constraint(equalToConstant: 70),
            
            backButton.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor, constant: -20),

            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 58),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func buildContentCards() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 20
        contentView.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            cardStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        if let job = job {
            cardStack.addArrangedSubview(makeTopHeroCard(for: job))
            cardStack.addArrangedSubview(makeSettingsStyleDetailsCard(for: job))
            
            let infoRow = UIStackView(arrangedSubviews: [
                makeMetricCard(title: "Compensation", body: "₹\(job.ratePerDay ?? 0)/day", icon: "banknote"),
                makeMetricCard(
                    title: "Deadline",
                    body: job.applicationDeadline != nil
                        ? DateFormatter.localizedString(from: job.applicationDeadline!, dateStyle: .medium, timeStyle: .none)
                        : "No deadline",
                    icon: "calendar"
                )
            ])
            infoRow.axis = .horizontal
            infoRow.spacing = 14
            infoRow.distribution = .fillEqually
            cardStack.addArrangedSubview(infoRow)
            
            cardStack.addArrangedSubview(makeDescriptionCard(title: "Role Description", body: job.description ?? "No description available."))
            
            if let req = job.requirements, !req.isEmpty {
                cardStack.addArrangedSubview(makeDescriptionCard(title: "Requirements", body: req))
            }
        }
    }

    private func makeGlassCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        card.clipsToBounds = true
        card.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 18
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        return card
    }

    private func makeTopHeroCard(for job: Job) -> UIView {
        let card = makeGlassCard()

        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.1)
        profileImageView.tintColor = CineMystTheme.brandPlum
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let url = profilePictureUrl {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    await MainActor.run { profileImageView.image = UIImage(data: data) }
                }
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        let title = UILabel()
        title.text = job.title ?? "Untitled"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textColor = CineMystTheme.ink
        title.numberOfLines = 0

        let company = UILabel()
        let companyName = productionHouseName ?? job.companyName ?? "CineMyst Production"
        company.text = companyName
        company.font = .systemFont(ofSize: 15, weight: .semibold)
        company.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.8)

        let textStack = UIStackView(arrangedSubviews: [title, company])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading
        
        let headerStack = UIStackView(arrangedSubviews: [profileImageView, textStack])
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(headerStack)
        
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            headerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        
        return card
    }
    
    private func makeSettingsStyleDetailsCard(for job: Job) -> UIView {
        let card = makeGlassCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        func makeRow(icon: String, title: String, value: String?, isLast: Bool = false) -> UIView {
            let container = UIView()
            
            let iconView = UIImageView(image: UIImage(systemName: icon))
            iconView.tintColor = CineMystTheme.brandPlum
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            
            let titleLbl = UILabel()
            titleLbl.text = title
            titleLbl.font = .systemFont(ofSize: 15, weight: .medium)
            titleLbl.textColor = CineMystTheme.ink.withAlphaComponent(0.6)
            titleLbl.translatesAutoresizingMaskIntoConstraints = false
            
            let valLbl = UILabel()
            valLbl.text = value ?? "Not Specified"
            valLbl.font = .systemFont(ofSize: 15, weight: .bold)
            valLbl.textColor = CineMystTheme.ink
            valLbl.textAlignment = .right
            valLbl.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(iconView)
            container.addSubview(titleLbl)
            container.addSubview(valLbl)
            
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalToConstant: 50),
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),
                
                titleLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                titleLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                valLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                valLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                valLbl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLbl.trailingAnchor, constant: 16)
            ])
            
            if !isLast {
                let div = UIView()
                div.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.1)
                div.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(div)
                NSLayoutConstraint.activate([
                    div.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
                    div.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    div.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    div.heightAnchor.constraint(equalToConstant: 1)
                ])
            }
            
            return container
        }
        
        stack.addArrangedSubview(makeRow(icon: "mappin.and.ellipse", title: "Location", value: job.location))
        stack.addArrangedSubview(makeRow(icon: "video.fill", title: "Project Type", value: job.projectType))
        stack.addArrangedSubview(makeRow(icon: "person.fill", title: "Position", value: job.positionType))
        stack.addArrangedSubview(makeRow(icon: "sparkles", title: "Genre", value: job.jobType, isLast: true))
        
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func makeDescriptionCard(title: String, body: String) -> UIView {
        let card = makeGlassCard()
        let titleLabel = UILabel(); titleLabel.text = title; titleLabel.font = .systemFont(ofSize: 18, weight: .bold); titleLabel.textColor = CineMystTheme.ink
        
        let bodyLabel = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        bodyLabel.attributedText = NSAttributedString(string: body, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: CineMystTheme.ink.withAlphaComponent(0.75)
        ])
        bodyLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel]); stack.axis = .vertical; stack.spacing = 10
        card.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        return card
    }

    private func makeMetricCard(title: String, body: String, icon: String) -> UIView {
        let card = makeGlassCard()

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = CineMystTheme.brandPlum
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.8)

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 18, weight: .bold)
        bodyLabel.textColor = CineMystTheme.ink

        let titleRow = UIStackView(arrangedSubviews: [iconView, titleLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 6
        
        let containerStack = UIStackView(arrangedSubviews: [titleRow, bodyLabel])
        containerStack.axis = .vertical
        containerStack.alignment = .leading
        containerStack.spacing = 8
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(containerStack)
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            containerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        return card
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
