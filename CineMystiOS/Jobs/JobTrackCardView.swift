import UIKit

class JobTrackCardView: UIView {
    
    // MARK: - UI Elements
    private let profileImageView = UIImageView()
    private let titleLabel = UILabel()
    private let companyLabel = UILabel()
    
    private let locationIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
    private let locationLabel = UILabel()
    
    private let rateIcon = UIImageView(image: UIImage(systemName: "indianrupeesign.circle"))
    private let rateLabel = UILabel()
    
    private let jobTypeTag = TagLabel()
    private let statusTag = TagLabel()
    
    private let viewApplicationsBtn = UIButton(type: .system)

    private let purple = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
    
    var onViewApplicationsTapped: (() -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        // Profile image setup
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 24
        profileImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fonts & Colors
        titleLabel.font = .boldSystemFont(ofSize: 16)
        companyLabel.font = .systemFont(ofSize: 14)
        companyLabel.textColor = .systemPurple
        
        locationLabel.font = .systemFont(ofSize: 13)
        rateLabel.font = .systemFont(ofSize: 13)
        
        jobTypeTag.font = .systemFont(ofSize: 12)
        jobTypeTag.textColor = .black
        jobTypeTag.backgroundColor = UIColor(white: 0.97, alpha: 1)
        jobTypeTag.layer.cornerRadius = 12
        jobTypeTag.clipsToBounds = true

        statusTag.font = .systemFont(ofSize: 12)
        statusTag.textColor = purple
        statusTag.backgroundColor = purple.withAlphaComponent(0.08)
        statusTag.layer.cornerRadius = 12
        statusTag.clipsToBounds = true

        locationIcon.tintColor = .darkGray
        rateIcon.tintColor = .darkGray
        
        // Buttons
        styleButton(viewApplicationsBtn, title: "View Applications")
        viewApplicationsBtn.addTarget(self, action: #selector(viewApplicationsPressed), for: .touchUpInside)

        // Horizontal row stacks
        let locationStack = horizontal(icon: locationIcon, label: locationLabel)
        let rateStack = horizontal(icon: rateIcon, label: rateLabel)
        
        let tagsStack = UIStackView(arrangedSubviews: [jobTypeTag, statusTag])
        tagsStack.axis = .horizontal
        tagsStack.spacing = 12
        tagsStack.alignment = .leading
        tagsStack.distribution = .equalSpacing
        
        jobTypeTag.setContentHuggingPriority(.required, for: .horizontal)
        jobTypeTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusTag.setContentHuggingPriority(.required, for: .horizontal)
        statusTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let infoStack = UIStackView(arrangedSubviews: [
            locationStack,
            rateStack,
            tagsStack
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        
        let buttonsStack = UIStackView(arrangedSubviews: [
            viewApplicationsBtn
        ])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        
        // Header with profile image, title and company
        let headerStack = UIStackView(arrangedSubviews: [
            titleLabel,
            companyLabel
        ])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        
        let topStack = UIStackView(arrangedSubviews: [
            profileImageView,
            headerStack
        ])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .center
        
        let container = UIStackView(arrangedSubviews: [
            topStack,
            infoStack,
            buttonsStack
        ])
        
        container.axis = .vertical
        container.spacing = 12
        
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 48),
            profileImageView.heightAnchor.constraint(equalToConstant: 48),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func viewApplicationsPressed() {
        onViewApplicationsTapped?()
    }

    // MARK: - Configure
    func configure(with job: JobCardModel, buttonTitle: String? = nil) {
        titleLabel.text = job.title
        companyLabel.text = job.company
        locationLabel.text = job.location
        rateLabel.text = job.rate
        jobTypeTag.text = job.type
        
        statusTag.text = job.statusText
        statusTag.textColor = job.statusColor
        statusTag.backgroundColor = job.statusColor.withAlphaComponent(0.15)
        
        if let title = buttonTitle {
            viewApplicationsBtn.setTitle(title, for: .normal)
        } else {
            viewApplicationsBtn.setTitle("View Applications", for: .normal)
        }
        
        // Load profile picture
        if let urlString = job.profilePictureUrl, let url = URL(string: urlString) {
            loadImage(url: url)
        } else {
            profileImageView.image = UIImage(systemName: "person.fill")
            profileImageView.tintColor = .systemGray
        }
    }
    
    private func loadImage(url: URL) {
        // Load image from URL asynchronously
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let image = UIImage(data: data)
                await MainActor.run {
                    self.profileImageView.image = image
                }
            } catch {
                await MainActor.run {
                    self.profileImageView.image = UIImage(systemName: "person.fill")
                    self.profileImageView.tintColor = .systemGray
                }
            }
        }
    }
    
    
    // MARK: - Helpers
    private func horizontal(icon: UIImageView, label: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 6
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        return stack
    }
    
    private func styleButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = purple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }
}

class TagLabel: UILabel {
    var inset = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: inset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + inset.left + inset.right,
            height: size.height + inset.top + inset.bottom
        )
    }
}

