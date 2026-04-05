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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        setupScrollView()
        setupLayout()
        
        applyButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        
        Task {
            await checkTaskStatus()
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
            applyButton.backgroundColor = CineMystTheme.accent
            applyButton.layer.shadowColor = CineMystTheme.accent.withAlphaComponent(0.4).cgColor
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
        tabBarController?.tabBar.isHidden = true
        buildContentCards()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(applyButton)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            applyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 54),
            applyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func buildContentCards() {
        contentView.subviews.forEach { if $0 is UIStackView && $0 != titleLabel { $0.removeFromSuperview() } }
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 28
        contentView.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            cardStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardStack.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -40)
        ])
        
        if let job = job {
            cardStack.addArrangedSubview(makeCard(title: job.title ?? "Untitled", body: job.description ?? "No description."))
            if let req = job.requirements, !req.isEmpty { cardStack.addArrangedSubview(makeRequirementsCard(requirements: req)) }
            cardStack.addArrangedSubview(makeCard(title: "Compensation", body: "₹\(job.ratePerDay ?? 0)/day"))
            let deadline = job.applicationDeadline != nil ? "By \(DateFormatter.localizedString(from: job.applicationDeadline!, dateStyle: .medium, timeStyle: .none))" : "No deadline."
            cardStack.addArrangedSubview(makeCard(title: "Deadline", body: deadline))
        }
    }

    private func makeCard(title: String, body: String) -> UIView {
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        card.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.44)
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        let titleLabel = UILabel(); titleLabel.text = title; titleLabel.font = .systemFont(ofSize: 19, weight: .bold); titleLabel.textColor = CineMystTheme.ink
        let bodyLabel = UILabel(); bodyLabel.text = body; bodyLabel.numberOfLines = 0; bodyLabel.font = UIFont.systemFont(ofSize: 15); bodyLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.7)
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel]); stack.axis = .vertical; stack.spacing = 8
        card.contentView.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -18)
        ])
        return card
    }

    private func makeRequirementsCard(requirements: String) -> UIView {
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        card.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.44)
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        let title = UILabel(); title.text = "Requirements"; title.font = .systemFont(ofSize: 19, weight: .bold); title.textColor = CineMystTheme.ink
        let body = UILabel(); body.text = requirements; body.numberOfLines = 0; body.font = UIFont.systemFont(ofSize: 15); body.textColor = CineMystTheme.ink.withAlphaComponent(0.7)
        let stack = UIStackView(arrangedSubviews: [title, body]); stack.axis = .vertical; stack.spacing = 10
        card.contentView.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -18)
        ])
        return card
    }
}
