import UIKit

class JobDetailsViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    
    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundGradient = CAGradientLayer()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Details"
        lbl.font = UIFont(name: "Georgia-Bold", size: 28) ?? UIFont.boldSystemFont(ofSize: 28)
        lbl.textColor = CineMystTheme.ink
        return lbl
    }()
    
    private let applyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Apply Now", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 16
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.backgroundColor = CineMystTheme.brandPlum
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        btn.layer.shadowOpacity = 0.28
        btn.layer.shadowRadius = 14
        btn.layer.shadowOffset = CGSize(width: 0, height: 8)
        btn.addTarget(nil, action: #selector(applyTapped), for: .touchUpInside)
        return btn
   }()
    @objc private func applyTapped() {
        let vc = ApplicationStartedViewController()
        vc.job = job // Pass job data
        navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        
        setupScrollView()
        setupLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
        
        // Rebuild content when view appears to ensure job data is available
        buildContentCards()
    }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            // Restore tab bar only
            tabBarController?.tabBar.isHidden = false

            // Restore floating button if you hid it above:
            // if let tb = tabBarController as? CineMystTabBarController {
            //     tb.setFloatingButton(hidden: false)
            // }
        }

}

extension JobDetailsViewController {
    
    // ScrollView Setup
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
    
    // Main Layout
    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(applyButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            applyButton.topAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -100)
        ])
    }
    
    // Build the Cards Section
    private func buildContentCards() {
        // Debug: Check if job data is available
        if let job = job {
            print("📋 JobDetailsViewController - Job data available:")
            print("   Title: \(job.title)")
            print("   Description: \(job.description ?? "nil")")
            print("   Requirements: \(job.requirements ?? "nil")")
            print("   Rate: ₹\(job.ratePerDay)/day")
        } else {
            print("⚠️ JobDetailsViewController - No job data available, using fallback")
        }
        
        // Remove existing card stack if it exists
        contentView.subviews.forEach { subview in
            if subview is UIStackView && subview != titleLabel && subview != applyButton {
                subview.removeFromSuperview()
            }
        }
        
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
        
        // Display job data if available
        if let job = job {
            // Job Title and Description
            cardStack.addArrangedSubview(makeCard(
                title: job.title,
                body: job.description ?? "No description available."
            ))
            
            // Requirements
            if let requirements = job.requirements, !requirements.isEmpty {
                cardStack.addArrangedSubview(makeRequirementsCard(requirements: requirements))
            }
            
            // Compensation
            cardStack.addArrangedSubview(makeCard(
                title: "Compensation",
                body: "₹\(job.ratePerDay)/day"
            ))
            
            // Deadline
            let deadlineText: String
            if let deadline = job.applicationDeadline {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                deadlineText = "Applications must be received by \(formatter.string(from: deadline))."
            } else {
                deadlineText = "No deadline specified."
            }
            cardStack.addArrangedSubview(makeCard(
                title: "Deadline",
                body: deadlineText
            ))
        } else {
            // Fallback to placeholder data
            cardStack.addArrangedSubview(makeCard(
                title: "Lead Role in Indie Film",
                body: """
Seeking a versatile actor for the lead role in an upcoming independent film. The project explores themes of identity and belonging, set against the backdrop of a bustling city. The role requires a nuanced performance, capable of conveying a wide range of emotions.
"""
            ))
            
            cardStack.addArrangedSubview(makeRequirementsCard(requirements: ""))
            
            cardStack.addArrangedSubview(makeCard(
                title: "Compensation",
                body: "Paid role; compensation details will be discussed upon application."
            ))
            
            cardStack.addArrangedSubview(makeCard(
                title: "Deadline",
                body: "Applications must be received by July 15, 2024."
            ))
        }
        
        // Bottom apply button constraints
        NSLayoutConstraint.activate([
            applyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 54),
            applyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // Card Builder
    private func makeCard(title: String, body: String) -> UIView {
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        card.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.44)
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.84).cgColor
        card.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.14).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        card.layer.shadowRadius = 18
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 19) ?? UIFont.boldSystemFont(ofSize: 19)
        titleLabel.textColor = CineMystTheme.ink
        
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.numberOfLines = 0
        bodyLabel.font = UIFont.systemFont(ofSize: 15)
        bodyLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.7)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 8
        
        card.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -18)
        ])
        
        return card
    }
    
    // Requirements Card (Custom Layout)
    private func makeRequirementsCard(requirements: String) -> UIView {
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        card.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.44)
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.84).cgColor
        card.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.14).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        card.layer.shadowRadius = 18

        let title = UILabel()
        title.text = "Requirements"
        title.font = UIFont(name: "Georgia-Bold", size: 19) ?? UIFont.boldSystemFont(ofSize: 19)
        title.textColor = CineMystTheme.ink
        
        let skillsTitle = makeSmallSectionTitle("SKILLS")
        
        let skill1 = makeTag("Acting")
        let skill2 = makeTag("Dancing")
        
        let skillsRow = UIStackView(arrangedSubviews: [skill1, skill2])
        skillsRow.axis = .horizontal
        skillsRow.spacing = 8
        skillsRow.alignment = .leading          // prevents stretching vertically
        skillsRow.distribution = .fillEqually // prevents full-width stretching
        
        let expTitle = makeSmallSectionTitle("EXPERIENCE")
        
        let expBody = UILabel()
        if !requirements.isEmpty {
            // Parse requirements if they contain structured data
            // For now, display as-is
            expBody.text = requirements
        } else {
            expBody.text = "3+ years in film or theatre\nOpen to all types"
        }
        expBody.numberOfLines = 0
        expBody.font = UIFont.systemFont(ofSize: 15)
        expBody.textColor = CineMystTheme.ink.withAlphaComponent(0.7)
        
        let stack = UIStackView(arrangedSubviews: [title, skillsTitle, skillsRow, expTitle, expBody])
        stack.axis = .vertical
        stack.spacing = 10
        
        card.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -18)
        ])
        
        return card
    }
    
    // Helpers
    private func makeSmallSectionTitle(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.boldSystemFont(ofSize: 13)
        lbl.textColor = CineMystTheme.brandPlum
        return lbl
    }
    
    private func makeTag(_ text: String) -> UIView {
            let container = UIView()
            
            let lbl = UILabel()
            lbl.text = "  \(text)  "
            lbl.font = UIFont.systemFont(ofSize: 14)
            lbl.textColor = CineMystTheme.ink.withAlphaComponent(0.75)
            lbl.textAlignment = .center
            lbl.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
            lbl.layer.cornerRadius = 12
            lbl.clipsToBounds = true
            
            container.addSubview(lbl)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: container.topAnchor),
                lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                lbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                lbl.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                lbl.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            return container
        }
}
