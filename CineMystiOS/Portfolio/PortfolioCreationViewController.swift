//
//  PortfolioCreationViewController.swift
//  CineMystApp
//
//  Created by user@50 on 23/01/26.
//

import UIKit

class PortfolioCreationViewController: UIViewController {
    
    // MARK: - Properties
    private var currentStep = 0
    private let totalSteps = 5
    private var formData = PortfolioFormData()
    
    // MARK: - UI Components
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    private var currentStepView: UIView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Create Portfolio"
        
        setupNavigationBar()
        setupProgressBar()
        setupScrollView()
        setupButtons()
        setupLoadingIndicator()
        
        // Auto-fill email from profile
        fetchUserEmail()
        
        showStep(0)
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func setupProgressBar() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(named: "AccentColor") ?? .systemPurple
        progressView.trackTintColor = .systemGray5
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        view.addSubview(progressView)
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = .systemFont(ofSize: 14, weight: .medium)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        updateProgress()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupButtons() {
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        backButton.setTitleColor(.label, for: .normal)
        backButton.backgroundColor = .systemGray6
        backButton.layer.cornerRadius = 12
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor(named: "AccentColor") ?? .systemPurple
        nextButton.layer.cornerRadius = 12
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            backButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Fetch User Email
    // MARK: - Fetch User Email
    private func fetchUserEmail() {
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let email = session.user.email ?? ""
                
                await MainActor.run {
                    self.formData.contactEmail = email
                    
                    // ✅ Update the text field if it's already created (tag 101)
                    if let emailField = self.view.viewWithTag(101) as? UITextField {
                        emailField.text = email
                        print("✅ Email auto-filled: \(email)")
                    } else {
                        print("⚠️ Email field not created yet, but formData updated")
                    }
                }
            } catch {
                print("⚠️ Could not fetch user email: \(error)")
            }
        }
    }

    
    // MARK: - Step Management
    private func showStep(_ step: Int) {
        currentStep = step
        updateProgress()
        
        currentStepView?.removeFromSuperview()
        
        let stepView: UIView
        switch step {
        case 0: stepView = createBasicInfoStep()
        case 1: stepView = createProfilePhotoStep()
        case 2: stepView = createBioStep()
        case 3: stepView = createSocialLinksStep()
        case 4: stepView = createReviewStep()
        default: return
        }
        
        stepView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepView)
        
        NSLayoutConstraint.activate([
            stepView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stepView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stepView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stepView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        currentStepView = stepView
        
        backButton.isHidden = (step == 0)
        nextButton.setTitle(step == totalSteps - 1 ? "Create Portfolio" : "Next", for: .normal)
        
        scrollView.setContentOffset(.zero, animated: false)
    }
    
    private func updateProgress() {
        let progress = Float(currentStep + 1) / Float(totalSteps)
        progressView.setProgress(progress, animated: true)
        progressLabel.text = "Step \(currentStep + 1) of \(totalSteps)"
    }
    
    // MARK: - Step 1: Basic Info
    private func createBasicInfoStep() -> UIView {
        let container = UIView()
        
        let titleLabel = createSectionTitle("Basic Information")
        let subtitleLabel = createSubtitle("Tell us a bit about yourself")
        
        let stageNameField = createTextField(placeholder: "Stage Name (Optional)", tag: 100)
        stageNameField.text = formData.stageName
        
        let contactEmailField = createTextField(placeholder: "Contact Email *", tag: 101, keyboardType: .emailAddress)
        contactEmailField.text = formData.contactEmail
        contactEmailField.isEnabled = false // Auto-filled, read-only
        contactEmailField.backgroundColor = .systemGray6
        
        let alternateEmailField = createTextField(placeholder: "Alternate Email (Optional)", tag: 102, keyboardType: .emailAddress)
        alternateEmailField.text = formData.alternateEmail
        
        let helperLabel = UILabel()
        helperLabel.text = "💡 Contact email is auto-filled from your profile"
        helperLabel.font = .systemFont(ofSize: 12)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, stageNameField, contactEmailField, alternateEmailField, helperLabel].forEach {
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            stageNameField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            stageNameField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stageNameField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            contactEmailField.topAnchor.constraint(equalTo: stageNameField.bottomAnchor, constant: 16),
            contactEmailField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contactEmailField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            helperLabel.topAnchor.constraint(equalTo: contactEmailField.bottomAnchor, constant: 8),
            helperLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            helperLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            alternateEmailField.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 16),
            alternateEmailField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            alternateEmailField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            alternateEmailField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Step 2: Profile Photo
    private func createProfilePhotoStep() -> UIView {
        let container = UIView()
        
        let titleLabel = createSectionTitle("Profile Photo")
        let subtitleLabel = createSubtitle("Upload your professional headshot")
        
        let photoUploadView = createPhotoUploadView()
        photoUploadView.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, photoUploadView].forEach {
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            photoUploadView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            photoUploadView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            photoUploadView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            photoUploadView.heightAnchor.constraint(equalToConstant: 200),
            photoUploadView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Step 3: Bio
    private func createBioStep() -> UIView {
        let container = UIView()
        
        let titleLabel = createSectionTitle("About You")
        let subtitleLabel = createSubtitle("Write a brief introduction (2-3 sentences)")
        
        let bioTextView = UITextView()
        bioTextView.text = formData.bio ?? "Tell casting directors about your passion, experience, and what makes you unique..."
        bioTextView.textColor = formData.bio == nil ? .placeholderText : .label
        bioTextView.font = .systemFont(ofSize: 16)
        bioTextView.backgroundColor = .systemGray6
        bioTextView.layer.cornerRadius = 12
        bioTextView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        bioTextView.delegate = self
        bioTextView.tag = 300
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        
        let charCountLabel = UILabel()
        charCountLabel.text = "\(formData.bio?.count ?? 0) / 500"
        charCountLabel.font = .systemFont(ofSize: 12)
        charCountLabel.textColor = .secondaryLabel
        charCountLabel.textAlignment = .right
        charCountLabel.tag = 301
        charCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, bioTextView, charCountLabel].forEach {
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            bioTextView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            bioTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bioTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bioTextView.heightAnchor.constraint(equalToConstant: 200),
            
            charCountLabel.topAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 8),
            charCountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            charCountLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Step 4: Social Links
    // MARK: - Step 4: Social Links
    private func createSocialLinksStep() -> UIView {
        let container = UIView()
        
        let titleLabel = createSectionTitle("Social Links")
        let subtitleLabel = createSubtitle("Help others find and connect with you (all optional)")
        
        // ✅ Create Instagram field and set text correctly
        let instagramField = createSocialField(icon: "📱", platform: "Instagram", placeholder: "@username or profile URL", tag: 400)
        if let textField = instagramField.viewWithTag(400) as? UITextField {
            textField.text = formData.instagramUrl
        }
        
        // ✅ Create YouTube field and set text correctly
        let youtubeField = createSocialField(icon: "📺", platform: "YouTube", placeholder: "Channel URL or @handle", tag: 401)
        if let textField = youtubeField.viewWithTag(401) as? UITextField {
            textField.text = formData.youtubeUrl
        }
        
        // ✅ Create IMDb field and set text correctly
        let imdbField = createSocialField(icon: "🎬", platform: "IMDb", placeholder: "IMDb profile URL", tag: 402)
        if let textField = imdbField.viewWithTag(402) as? UITextField {
            textField.text = formData.imdbUrl
        }
        
        let skipLabel = UILabel()
        skipLabel.text = "You can add these later from your portfolio settings"
        skipLabel.font = .systemFont(ofSize: 12)
        skipLabel.textColor = .tertiaryLabel
        skipLabel.textAlignment = .center
        skipLabel.numberOfLines = 2
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, instagramField, youtubeField, imdbField, skipLabel].forEach {
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            instagramField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            instagramField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            instagramField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            youtubeField.topAnchor.constraint(equalTo: instagramField.bottomAnchor, constant: 16),
            youtubeField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            youtubeField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            imdbField.topAnchor.constraint(equalTo: youtubeField.bottomAnchor, constant: 16),
            imdbField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imdbField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            skipLabel.topAnchor.constraint(equalTo: imdbField.bottomAnchor, constant: 24),
            skipLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            skipLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            skipLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }

    // MARK: - Step 5: Review
    private func createReviewStep() -> UIView {
        let container = UIView()
        
        let titleLabel = createSectionTitle("Review Your Portfolio")
        let subtitleLabel = createSubtitle("Make sure everything looks good!")
        
        let reviewText = generateReviewText()
        let reviewTextView = UITextView()
        reviewTextView.text = reviewText
        reviewTextView.font = .systemFont(ofSize: 15)
        reviewTextView.isEditable = false
        reviewTextView.backgroundColor = .systemGray6
        reviewTextView.layer.cornerRadius = 12
        reviewTextView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        reviewTextView.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, reviewTextView].forEach {
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            reviewTextView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            reviewTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            reviewTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            reviewTextView.heightAnchor.constraint(equalToConstant: 400),
            reviewTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Helper UI Components
    private func createSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createSubtitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createTextField(placeholder: String, tag: Int, keyboardType: UIKeyboardType = .default) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.font = .systemFont(ofSize: 16)
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = keyboardType == .emailAddress ? .none : .sentences
        textField.tag = tag
        textField.delegate = self
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }
    
    private func createSocialField(icon: String, platform: String, placeholder: String, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 24)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let platformLabel = UILabel()
        platformLabel.text = platform
        platformLabel.font = .systemFont(ofSize: 14, weight: .medium)
        platformLabel.textColor = .secondaryLabel
        platformLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.font = .systemFont(ofSize: 15)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.tag = tag
        textField.delegate = self
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconLabel)
        container.addSubview(platformLabel)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 32),
            
            platformLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            platformLabel.topAnchor.constraint(equalTo: container.topAnchor),
            
            textField.topAnchor.constraint(equalTo: platformLabel.bottomAnchor, constant: 6),
            textField.leadingAnchor.constraint(equalTo: platformLabel.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func createPhotoUploadView() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.systemGray4.cgColor
        
        let imageView = UIImageView()
        imageView.image = formData.profileImage ?? UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tag = 200
        container.addSubview(imageView)
        
        let uploadButton = UIButton(type: .system)
        uploadButton.setTitle("Choose Photo", for: .normal)
        uploadButton.backgroundColor = UIColor(named: "AccentColor")
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        uploadButton.layer.cornerRadius = 8
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
        container.addSubview(uploadButton)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            uploadButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            uploadButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 150),
            uploadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func generateReviewText() -> String {
        var text = ""
        
        text += "📋 Basic Information\n"
        text += "Stage Name: \(formData.stageName?.isEmpty == false ? formData.stageName! : "Not provided")\n"
        text += "Contact Email: \(formData.contactEmail ?? "N/A")\n"
        text += "Alternate Email: \(formData.alternateEmail?.isEmpty == false ? formData.alternateEmail! : "Not provided")\n\n"
        
        text += "📸 Profile Photo\n"
        text += formData.profileImage != nil ? "✅ Photo uploaded\n\n" : "⚠️ No photo uploaded\n\n"
        
        text += "📝 Bio\n"
        text += "\(formData.bio ?? "Not provided")\n\n"
        
        text += "🌐 Social Links\n"
        if let instagram = formData.instagramUrl, !instagram.isEmpty {
            text += "Instagram: \(instagram)\n"
        }
        if let youtube = formData.youtubeUrl, !youtube.isEmpty {
            text += "YouTube: \(youtube)\n"
        }
        if let imdb = formData.imdbUrl, !imdb.isEmpty {
            text += "IMDb: \(imdb)\n"
        }
        
        if formData.instagramUrl?.isEmpty != false && formData.youtubeUrl?.isEmpty != false && formData.imdbUrl?.isEmpty != false {
            text += "No social links provided\n"
        }
        
        return text
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        let alert = UIAlertController(title: "Cancel Portfolio Creation?", message: "Your progress will be lost.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func backTapped() {
        saveCurrentStepData()
        showStep(currentStep - 1)
    }
    
    @objc private func nextTapped() {
        saveCurrentStepData()
        
        if currentStep == totalSteps - 1 {
            createPortfolio()
        } else {
            if validateCurrentStep() {
                showStep(currentStep + 1)
            }
        }
    }
    
    @objc private func choosePhotoTapped() {
        let alert = UIAlertController(title: "Choose Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.openImagePicker(sourceType: .camera)
        })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.openImagePicker(sourceType: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - Data Management
    private func saveCurrentStepData() {
        switch currentStep {
        case 0:
            formData.stageName = (view.viewWithTag(100) as? UITextField)?.text
            formData.contactEmail = (view.viewWithTag(101) as? UITextField)?.text
            formData.alternateEmail = (view.viewWithTag(102) as? UITextField)?.text
            
        case 2:
            if let textView = view.viewWithTag(300) as? UITextView, textView.textColor != .placeholderText {
                formData.bio = textView.text
            }
            
        case 3:
            formData.instagramUrl = (view.viewWithTag(400) as? UITextField)?.text
            formData.youtubeUrl = (view.viewWithTag(401) as? UITextField)?.text
            formData.imdbUrl = (view.viewWithTag(402) as? UITextField)?.text
            
        default:
            break
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0:
            guard let email = formData.contactEmail, !email.isEmpty else {
                showError(message: "Contact email is required")
                return false
            }
            return true
        case 1:
            if formData.profileImage == nil {
                let alert = UIAlertController(
                    title: "No Photo",
                    message: "Would you like to add a photo? It helps people recognize you!",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Add Photo", style: .default))
                alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel) { [weak self] _ in
                    self?.showStep((self?.currentStep ?? 0) + 1)
                })
                present(alert, animated: true)
                return false
            }
            return true
        case 2:
            if formData.bio == nil || formData.bio?.isEmpty == true {
                showError(message: "Please write a brief bio about yourself")
                return false
            }
            return true
        default:
            return true
        }
    }
    
    // MARK: - Create Portfolio
    private func createPortfolio() {
        guard let email = formData.contactEmail, !email.isEmpty else {
            showError(message: "Email is required")
            return
        }
        
        loadingIndicator.startAnimating()
        nextButton.isEnabled = false
        backButton.isEnabled = false
        
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else {
                    throw NSError(domain: "Auth", code: 401)
                }
                
                let userId = session.user.id.uuidString
                
                // TODO: Upload profile image to storage first if exists
                var profilePictureUrl: String? = nil
                if let image = formData.profileImage {
                    // Upload logic here
                    print("📸 Would upload image here")
                }
                
                struct PortfolioCreate: Encodable {
                    let user_id: String
                    let stage_name: String?
                    let contact_email: String
                    let alternate_email: String?
                    let bio: String?
                    let profile_picture_url: String?
                    let instagram_url: String?
                    let youtube_url: String?
                    let imdb_url: String?
                    let is_primary: Bool
                    let is_public: Bool
                }
                
                let portfolioData = PortfolioCreate(
                    user_id: userId,
                    stage_name: formData.stageName,
                    contact_email: email,
                    alternate_email: formData.alternateEmail,
                    bio: formData.bio,
                    profile_picture_url: profilePictureUrl,
                    instagram_url: formData.instagramUrl,
                    youtube_url: formData.youtubeUrl,
                    imdb_url: formData.imdbUrl,
                    is_primary: true,
                    is_public: false
                )
                
                let response = try await supabase
                    .from("portfolios")
                    .insert(portfolioData)
                    .select()
                    .execute()
                
                print("✅ Portfolio created successfully")
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.nextButton.isEnabled = true
                    self.backButton.isEnabled = true
                    self.showSuccessAndDismiss()
                }
                
            } catch {
                print("❌ Error creating portfolio: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.nextButton.isEnabled = true
                    self.backButton.isEnabled = true
                    self.showError(message: "Failed to create portfolio: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "🎉 Portfolio Created!",
            message: "Your portfolio is ready! You can now add your films, theatre work, and more.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true) {
                NotificationCenter.default.post(name: .portfolioCreated, object: nil)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension PortfolioCreationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension PortfolioCreationViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Tell casting directors about your passion, experience, and what makes you unique..."
            textView.textColor = .placeholderText
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let charCountLabel = view.viewWithTag(301) as? UILabel {
            let count = textView.text.count
            charCountLabel.text = "\(count) / 500"
            charCountLabel.textColor = count > 500 ? .systemRed : .secondaryLabel
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return newText.count <= 500
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PortfolioCreationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            formData.profileImage = editedImage
            if let imageView = view.viewWithTag(200) as? UIImageView {
                imageView.image = editedImage
                imageView.tintColor = nil
            }
        } else if let originalImage = info[.originalImage] as? UIImage {
            formData.profileImage = originalImage
            if let imageView = view.viewWithTag(200) as? UIImageView {
                imageView.image = originalImage
                imageView.tintColor = nil
            }
        }
    }
}

// MARK: - Form Data Model
struct PortfolioFormData {
    var stageName: String?
    var contactEmail: String?
    var alternateEmail: String?
    var profileImage: UIImage?
    var bio: String?
    var instagramUrl: String?
    var youtubeUrl: String?
    var imdbUrl: String?
}

// MARK: - Notification
extension Notification.Name {
    static let portfolioCreated = Notification.Name("portfolioCreated")
}
