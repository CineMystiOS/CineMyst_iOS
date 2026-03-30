import UIKit
import Supabase

class ApplicationStartedViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://kyhyunyobgouumgwcigk.supabase.co")!,
        supabaseKey: "sb_publishable_oJe1X9aiPdKm6wqR1zvFhA_aIiej9-d"
    )
    
    // MARK: - Modern UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let heroContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let successAnimationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        view.layer.cornerRadius = 60
        return view
    }()
    
    private let checkmarkCircle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 35
        return view
    }()
    
    private let checkIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: config))
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Application Started!"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your journey begins here"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let jobInfoCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 20
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        return view
    }()
    
    private let jobTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "Next Steps"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = false
        
        // Shadow
        btn.layer.shadowColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.5).cgColor
        btn.layer.shadowOpacity = 0.4
        btn.layer.shadowRadius = 12
        btn.layer.shadowOffset = CGSize(width: 0, height: 8)
        
        return btn
    }()
    
    private let submitButtonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let submitIconView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let submitIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "square.and.arrow.up", withConfiguration: config))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let submitLabel: UILabel = {
        let label = UILabel()
        label.text = "Submit Portfolio"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let taskButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.systemGray6
        btn.layer.cornerRadius = 16
        return btn
    }()
    
    private let taskButtonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let taskIconView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 0.15)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let taskIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: config))
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let taskLabel: UILabel = {
        let label = UILabel()
        label.text = "Go to Task"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let taskArrow: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "arrow.right", withConfiguration: config))
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupNavigation()
        setupLayout()
        setupActions()
        populateJobInfo()
        animateEntrance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        title = "Application"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        back.tintColor = .label
        navigationItem.leftBarButtonItem = back
    }
    
    private func setupActions() {
        submitButton.addTarget(self, action: #selector(portfolioSubmitted), for: .touchUpInside)
        taskButton.addTarget(self, action: #selector(goToTask), for: .touchUpInside)
    }
    
    private func populateJobInfo() {
        guard let job = job else { return }
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
    }
    
    // MARK: - Animation
    
    private func animateEntrance() {
        // Initial state
        successAnimationView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        successAnimationView.alpha = 0
        
        checkmarkCircle.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        checkmarkCircle.alpha = 0
        
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        jobInfoCard.alpha = 0
        jobInfoCard.transform = CGAffineTransform(translationX: 0, y: 30)
        
        submitButton.alpha = 0
        submitButton.transform = CGAffineTransform(translationX: 0, y: 30)
        
        taskButton.alpha = 0
        taskButton.transform = CGAffineTransform(translationX: 0, y: 30)
        
        // Animate
        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.successAnimationView.transform = .identity
            self.successAnimationView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.checkmarkCircle.transform = .identity
            self.checkmarkCircle.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.5) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.6) {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.7, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.jobInfoCard.alpha = 1
            self.jobInfoCard.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.85, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.submitButton.alpha = 1
            self.submitButton.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.95, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.taskButton.alpha = 1
            self.taskButton.transform = .identity
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func goToTask() {
        let vc = TaskDetailsViewController()
        vc.job = job
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func portfolioSubmitted() {
        // Button press animation
        UIView.animate(withDuration: 0.1, animations: {
            self.submitButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.submitButton.transform = .identity
            }
        }
        
        Task {
            await submitPortfolio()
        }
    }
    
    private func submitPortfolio() async {
        guard let job = job,
              let currentUser = supabase.auth.currentUser else {
            showAlert(title: "Error", message: "Missing job or user information")
            return
        }
        
        do {
            let actorId = currentUser.id
            
            print("📝 Submitting Portfolio:")
            print("  - Actor ID: \(actorId.uuidString)")
            print("  - Job ID: \(job.id.uuidString)")
            
            // Check if application already exists
            let existingApps: [Application] = try await supabase
                .from("applications")
                .select()
                .eq("job_id", value: job.id.uuidString)
                .eq("actor_id", value: actorId.uuidString)
                .execute()
                .value
            
            print("  - Existing apps found: \(existingApps.count)")
            
            if let existingApp = existingApps.first {
                // Update existing application
                let updatedApplication = Application(
                    id: existingApp.id,
                    jobId: existingApp.jobId,
                    actorId: existingApp.actorId,
                    status: .portfolioSubmitted,
                    portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                    portfolioSubmittedAt: Date(),
                    appliedAt: existingApp.appliedAt,
                    updatedAt: Date()
                )
                
                let _: [Application] = try await supabase
                    .from("applications")
                    .update(updatedApplication)
                    .eq("id", value: existingApp.id.uuidString)
                    .select()
                    .execute()
                    .value
                
                print("  ✅ Updated existing application")
            } else {
                // Create new application
                let application = Application(
                    id: UUID(),
                    jobId: job.id,
                    actorId: actorId,
                    status: .portfolioSubmitted,
                    portfolioUrl: currentUser.userMetadata["portfolio_url"] as? String,
                    portfolioSubmittedAt: Date(),
                    appliedAt: Date(),
                    updatedAt: Date()
                )
                
                print("  - Creating new application")
                
                let _: Application = try await supabase
                    .from("applications")
                    .insert(application)
                    .single()
                    .execute()
                    .value
                
                print("  ✅ Created new application")
            }
            
            // Show success with animation
            await MainActor.run {
                showSuccessAlert(title: "✓ Success", message: "Portfolio submitted successfully! Your application is now active.") { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        } catch {
            await MainActor.run {
                showAlert(title: "Error", message: "Failed to submit portfolio: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Hero section
        contentView.addSubview(heroContainer)
        heroContainer.addSubview(successAnimationView)
        heroContainer.addSubview(checkmarkCircle)
        heroContainer.addSubview(checkIcon)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        // Job info card
        contentView.addSubview(jobInfoCard)
        jobInfoCard.addSubview(jobTitleLabel)
        jobInfoCard.addSubview(companyLabel)
        jobInfoCard.addSubview(divider)
        
        // Steps section
        contentView.addSubview(stepsLabel)
        
        // Submit button
        contentView.addSubview(submitButton)
        submitButton.addSubview(submitButtonStack)
        submitIconView.addSubview(submitIcon)
        submitButtonStack.addArrangedSubview(submitIconView)
        submitButtonStack.addArrangedSubview(submitLabel)
        
        // Task button
        contentView.addSubview(taskButton)
        taskButton.addSubview(taskButtonStack)
        taskIconView.addSubview(taskIcon)
        taskButtonStack.addArrangedSubview(taskIconView)
        taskButtonStack.addArrangedSubview(taskLabel)
        taskButtonStack.addArrangedSubview(UIView()) // Spacer
        taskButtonStack.addArrangedSubview(taskArrow)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Hero container
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            heroContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            heroContainer.widthAnchor.constraint(equalToConstant: 120),
            heroContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Success animation view
            successAnimationView.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            successAnimationView.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor),
            successAnimationView.widthAnchor.constraint(equalToConstant: 120),
            successAnimationView.heightAnchor.constraint(equalToConstant: 120),
            
            // Checkmark circle
            checkmarkCircle.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            checkmarkCircle.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor),
            checkmarkCircle.widthAnchor.constraint(equalToConstant: 70),
            checkmarkCircle.heightAnchor.constraint(equalToConstant: 70),
            
            // Check icon
            checkIcon.centerXAnchor.constraint(equalTo: checkmarkCircle.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkmarkCircle.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 32),
            checkIcon.heightAnchor.constraint(equalToConstant: 32),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Job info card
            jobInfoCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            jobInfoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            jobInfoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Job title
            jobTitleLabel.topAnchor.constraint(equalTo: jobInfoCard.topAnchor, constant: 20),
            jobTitleLabel.leadingAnchor.constraint(equalTo: jobInfoCard.leadingAnchor, constant: 20),
            jobTitleLabel.trailingAnchor.constraint(equalTo: jobInfoCard.trailingAnchor, constant: -20),
            
            // Company
            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 6),
            companyLabel.leadingAnchor.constraint(equalTo: jobInfoCard.leadingAnchor, constant: 20),
            companyLabel.trailingAnchor.constraint(equalTo: jobInfoCard.trailingAnchor, constant: -20),
            
            // Divider
            divider.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: jobInfoCard.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: jobInfoCard.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.bottomAnchor.constraint(equalTo: jobInfoCard.bottomAnchor, constant: -20),
            
            // Steps label
            stepsLabel.topAnchor.constraint(equalTo: jobInfoCard.bottomAnchor, constant: 40),
            stepsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            // Submit button
            submitButton.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 20),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            submitButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Submit button stack
            submitButtonStack.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            submitButtonStack.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
            
            // Submit icon view
            submitIconView.widthAnchor.constraint(equalToConstant: 40),
            submitIconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Submit icon
            submitIcon.centerXAnchor.constraint(equalTo: submitIconView.centerXAnchor),
            submitIcon.centerYAnchor.constraint(equalTo: submitIconView.centerYAnchor),
            submitIcon.widthAnchor.constraint(equalToConstant: 20),
            submitIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Task button
            taskButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 16),
            taskButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            taskButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            taskButton.heightAnchor.constraint(equalToConstant: 60),
            taskButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Task button stack
            taskButtonStack.leadingAnchor.constraint(equalTo: taskButton.leadingAnchor, constant: 20),
            taskButtonStack.trailingAnchor.constraint(equalTo: taskButton.trailingAnchor, constant: -20),
            taskButtonStack.centerYAnchor.constraint(equalTo: taskButton.centerYAnchor),
            
            // Task icon view
            taskIconView.widthAnchor.constraint(equalToConstant: 40),
            taskIconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Task icon
            taskIcon.centerXAnchor.constraint(equalTo: taskIconView.centerXAnchor),
            taskIcon.centerYAnchor.constraint(equalTo: taskIconView.centerYAnchor),
            taskIcon.widthAnchor.constraint(equalToConstant: 20),
            taskIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Task arrow
            taskArrow.widthAnchor.constraint(equalToConstant: 20),
            taskArrow.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}