import UIKit
//main first job screen
class JobCardView: UIView {
    
    private let profileImageView = UIImageView()
    private let titleLabel = UILabel()
    private let companyTagContainer = UIView()
    private let companyTagLabel = UILabel()
    private let bookmarkButton = UIButton(type: .system)
    private let locationIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
    private let locationLabel = UILabel()
    private let salaryLabel = UILabel()
    private let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
    private let daysLeftLabel = UILabel()
    private let tagLabel = UILabel()
    private let appliedLabel = UILabel()
    private let applyButton = UIButton(type: .system)
    
    
    var onTap: (() -> Void)?
    var onApplyTap: (() -> Void)?
    var onBookmarkTap: (() -> Void)?


    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(
        image: UIImage?,
        title: String,
        company: String,
        location: String,
        salary: String,
        daysLeft: String,
        tag: String,
        appliedCount: String = "0 applied",
        hasTask: Bool = false
    ) {
        profileImageView.image = image
        titleLabel.text = title
        companyTagLabel.text = "  \(company)  "
        locationLabel.text = location
        salaryLabel.text = salary
        daysLeftLabel.text = daysLeft
        tagLabel.text = "  \(tag)  "
        appliedLabel.text = appliedCount
        
        if hasTask {
            applyButton.setTitle("Go to Task", for: .normal)
            applyButton.backgroundColor = CineMystTheme.accent
        } else {
            applyButton.setTitle("Apply Now", for: .normal)
            applyButton.backgroundColor = CineMystTheme.brandPlum
        }
    }

    
    // MARK: - Add Tap Gesture
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func cardTapped() {
        onTap?()    // 👈 triggers navigation
    }
    @objc private func applyTapped() {
        onApplyTap?()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.82)
        layer.cornerRadius = CineMystTheme.cardRadius
        layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.16).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 22
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.86).cgColor
        
        // Image
        profileImageView.layer.cornerRadius = 32
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = CineMystTheme.plumMist
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        
        // Title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = CineMystTheme.ink
        
        // Company label with subtle background
        companyTagLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        companyTagLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.82)
        companyTagLabel.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        companyTagLabel.layer.cornerRadius = 12
        companyTagLabel.clipsToBounds = true
        companyTagLabel.textAlignment = .center
        companyTagLabel.numberOfLines = 1
        companyTagLabel.baselineAdjustment = .alignCenters
        companyTagLabel.translatesAutoresizingMaskIntoConstraints = false
        companyTagLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        companyTagLabel.adjustsFontSizeToFitWidth = false
        
        // Bookmark button - top right floating
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = CineMystTheme.brandPlum
        bookmarkButton.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        bookmarkButton.layer.cornerRadius = 13
        bookmarkButton.layer.borderWidth = 1
        bookmarkButton.layer.borderColor = UIColor.white.withAlphaComponent(0.84).cgColor
        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bookmarkButton)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        
        // Location + Salary row (clean, compact)
        locationIcon.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.42)
        clockIcon.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.42)
        
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        locationLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.62)
        locationIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        
        salaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        salaryLabel.textColor = CineMystTheme.brandPlum
        
        daysLeftLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        daysLeftLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.58)
        
        tagLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        tagLabel.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.9)
        tagLabel.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.08)
        tagLabel.layer.cornerRadius = 13
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.heightAnchor.constraint(equalToConstant: 26).isActive = true
        
        appliedLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        appliedLabel.textColor = CineMystTheme.ink.withAlphaComponent(0.42)
        
        // Apply button — enhanced style
        applyButton.setTitle("Apply Now", for: .normal)
        applyButton.backgroundColor = CineMystTheme.brandPlum
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        applyButton.layer.cornerRadius = 14
        applyButton.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        applyButton.layer.shadowOpacity = 0.3
        applyButton.layer.shadowRadius = 10
        applyButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        applyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        
        // ---------- STACK LAYOUT ----------
        
        // Company label container to control width
        let companyContainer = UIView()
        companyContainer.translatesAutoresizingMaskIntoConstraints = false
        companyContainer.addSubview(companyTagLabel)
        
        NSLayoutConstraint.activate([
            companyTagLabel.leadingAnchor.constraint(equalTo: companyContainer.leadingAnchor),
            companyTagLabel.topAnchor.constraint(equalTo: companyContainer.topAnchor),
            companyTagLabel.bottomAnchor.constraint(equalTo: companyContainer.bottomAnchor),
            companyTagLabel.trailingAnchor.constraint(lessThanOrEqualTo: companyContainer.trailingAnchor),
            companyTagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, companyContainer])
        titleStack.axis = .vertical
        titleStack.spacing = 4
        titleStack.alignment = .leading
        
        let salaryLocationRow = UIStackView(arrangedSubviews: [
            iconLabelStack(icon: locationIcon, label: locationLabel),
            salaryLabel
        ])
        salaryLocationRow.axis = .horizontal
        salaryLocationRow.spacing = 10
        salaryLocationRow.alignment = .center
        
        let tagAppliedRow = UIStackView(arrangedSubviews: [
            tagLabel,
            appliedLabel
        ])
        tagAppliedRow.axis = .horizontal
        tagAppliedRow.distribution = .equalSpacing
        
        let topRow = UIStackView(arrangedSubviews: [profileImageView, titleStack])
        topRow.axis = .horizontal
        topRow.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [
            topRow,
            salaryLocationRow,
            tagAppliedRow,
            applyButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
                locationIcon.widthAnchor.constraint(equalToConstant: 14),
                locationIcon.heightAnchor.constraint(equalToConstant: 14),
                clockIcon.widthAnchor.constraint(equalToConstant: 14),
                clockIcon.heightAnchor.constraint(equalToConstant: 14),
                
            profileImageView.widthAnchor.constraint(equalToConstant: 64),
            profileImageView.heightAnchor.constraint(equalToConstant: 64),
            
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            bookmarkButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            bookmarkButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 26),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    
    private func iconLabelStack(icon: UIImageView, label: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }
    @objc private func bookmarkTapped() {
        onBookmarkTap?()
    }
    func updateBookmark(isBookmarked: Bool) {
        let icon = isBookmarked ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: icon), for: .normal)
    }

}
