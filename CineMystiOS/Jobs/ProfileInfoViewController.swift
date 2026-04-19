//
//  ProfileInfoViewController.swift
//  CineMystApp
//

import UIKit
import Supabase

class ProfileInfoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var openedFromProfile: Bool {
        navigationController?.viewControllers.contains(where: { $0 is ActorProfileViewController }) == true
    }
    private var hasExistingCastingProfile = false

    // Selection data sources
    private let castingRoles = ["Director", "Assistant Director", "Casting Professional"]
    private let companyTypes = ["Production Company", "Post-Production", "Studio", "Network", "Independent", "Freelance"]
    private let experienceYears = ["0-2 years", "3-5 years", "6-10 years", "11-15 years", "16-20 years", "20+ years"]
    
    // Store selected values
    private var selectedRole: String?
    private var selectedCompanyType: String?
    private var selectedExperience: String?
    private var selectedMembershipExpiry: Date?
    
    // Document URLs (from storage)
    private var governmentIdUrl: String?
    private var selfieUrl: String?
    private var guildIdCardUrl: String?
    
    // Store text field references
    private var fullNameTextField: UITextField?
    private var phoneNumberTextField: UITextField?
    private var emailTextField: UITextField?
    private var locationTextField: UITextField?
    
    private var pastProjectDetailsTextView: UITextView?
    private var projectRoleTextField: UITextField?
    private var productionHouseTextField: UITextField?
    private var imdbLinkTextField: UITextField?
    
    private var companyNameTextField: UITextField?
    private var officialEmailTextField: UITextField?
    private var linkedinTextField: UITextField?
    private var instagramTextField: UITextField?
    private var portfolioWebsiteTextField: UITextField?
    
    private var guildNameTextField: UITextField?
    private var membershipNumberTextField: UITextField?
    private var industryReferencesTextView: UITextView?

    // MARK: - Helpers (UI builders)
    private func sectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.darkGray.withAlphaComponent(0.85)
        return label
    }

    private func inputField(title: String, placeholder: String) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray

        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor.systemGray6
        tf.layer.cornerRadius = 8
        tf.setPaddingLeft(12)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Store reference based on title
        switch title {
        case "Full Name *": fullNameTextField = tf
        case "Phone Number *": phoneNumberTextField = tf
        case "Email ID *": emailTextField = tf
        case "Location *": locationTextField = tf
        case "Role in Projects": projectRoleTextField = tf
        case "Production House / Studio Name": productionHouseTextField = tf
        case "IMDb / YouTube / OTT Links": imdbLinkTextField = tf
        case "Company / Organization Name": companyNameTextField = tf
        case "Official Work Email": officialEmailTextField = tf
        case "LinkedIn Profile": linkedinTextField = tf
        case "Instagram / Professional Social Media": instagramTextField = tf
        case "Portfolio Website": portfolioWebsiteTextField = tf
        case "Guild Name": guildNameTextField = tf
        case "Membership Number": membershipNumberTextField = tf
        default: break
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, tf])
        stack.axis = .vertical
        stack.spacing = 6

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func textViewField(title: String, placeholder: String) -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray

        let tv = UITextView()
        tv.backgroundColor = UIColor.systemGray6
        tv.layer.cornerRadius = 8
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        if title == "Past Project Details" {
            pastProjectDetailsTextView = tv
        } else if title == "Industry References" {
            industryReferencesTextView = tv
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, tv])
        stack.axis = .vertical
        stack.spacing = 6
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func documentUploadRow(title: String, icon: String, identifier: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 8
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true
        container.accessibilityIdentifier = identifier

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = .darkGray
        img.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black

        let statusLabel = UILabel()
        statusLabel.text = "Tap to upload"
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textColor = .gray
        statusLabel.tag = 500

        let vStack = UIStackView(arrangedSubviews: [label, statusLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [img, vStack, UIView(), UIImageView(image: UIImage(systemName: "plus.circle"))])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center

        container.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            hStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        img.widthAnchor.constraint(equalToConstant: 24).isActive = true
        img.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(uploadRowTapped(_:)))
        container.addGestureRecognizer(tap)
        return container
    }
    
    @objc private func uploadRowTapped(_ sender: UITapGestureRecognizer) {
        guard let id = sender.view?.accessibilityIdentifier else { return }
        presentImagePicker(for: id)
    }

    private func selectionCell(title: String, value: String, tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 8
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        container.tag = tag

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = .gray
        valueLabel.tag = 1000 + tag

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .gray

        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel, chevron])
        row.axis = .horizontal
        row.alignment = .center

        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectionCellTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        return container
    }

    private func presentImagePicker(for identifier: String) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.accessibilityHint = identifier
        
        let ac = UIAlertController(title: "Upload", message: "Choose source", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }
        })
        ac.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    // MARK: - Actions for selection cells
    @objc private func selectionCellTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        
        var title = ""
        var options: [String] = []
        
        switch tag {
        case 10:
            title = "Primary Role"
            options = castingRoles
        case 20: 
            let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
            let picker = UIDatePicker()
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .wheels
            picker.frame = CGRect(x: 0, y: 0, width: alert.view.bounds.width - 20, height: 200)
            alert.view.addSubview(picker)
            alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                self.selectedMembershipExpiry = picker.date
                self.updateSelection(tag: tag, value: formatter.string(from: picker.date))
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        default: break
        }
        
        showBottomPicker(title: title, options: options, tag: tag)
    }

    private func showBottomPicker(title: String, options: [String], tag: Int) {
        let pickerVC = BottomPickerViewController(title: title, options: options) { [weak self] selectedOption in
            self?.updateSelection(tag: tag, value: selectedOption)
        }
        
        pickerVC.modalPresentationStyle = .pageSheet
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(pickerVC, animated: true)
    }

    private func updateSelection(tag: Int, value: String) {
        let valueTag = 1000 + tag
        if let valueLabel = view.viewWithTag(valueTag) as? UILabel {
            valueLabel.text = value
            valueLabel.textColor = .black
        }
        
        switch tag {
        case 10: selectedRole = value
        case 20: break // Date already stored
        default: break
        }
    }

    // MARK: - Verification card + action buttons
    private let verificationCard: UIView = {
        let card = UIView()
        card.backgroundColor = UIColor.systemGray6
        card.layer.cornerRadius = 14
        card.clipsToBounds = true

        let icon = UIImageView(image: UIImage(systemName: "shield.fill"))
        icon.tintColor = .darkGray

        let title = UILabel()
        title.text = "Professional Verification"
        title.font = UIFont.boldSystemFont(ofSize: 15)

        let desc = UILabel()
        desc.text = "Your profile will be reviewed for verification. Verified profiles get priority visibility and build trust with talent. This helps maintain our community's professional standards."
        desc.font = UIFont.systemFont(ofSize: 13)
        desc.numberOfLines = 0
        desc.textColor = .gray

        let bullet = UILabel()
        bullet.text = "• Review typically takes 24–48 hours"
        bullet.font = UIFont.systemFont(ofSize: 13)
        bullet.textColor = .gray

        let textStack = UIStackView(arrangedSubviews: [title, desc, bullet])
        textStack.axis = .vertical
        textStack.spacing = 4

        card.addSubview(icon)
        card.addSubview(textStack)

        icon.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),

            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Submit Profile", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        b.backgroundColor = UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1)
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    private let trackButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Track Verification Status", for: .normal)
        b.setTitleColor(UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1), for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        b.backgroundColor = .white
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 2
        b.layer.borderColor = UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1).cgColor
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        b.isHidden = true
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Setup navigation bar
        title = openedFromProfile ? "Create Portfolio" : "Profile Information"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1),
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        setupScroll()
        buildLayout()
        
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        trackButton.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)
        
        if openedFromProfile {
            submitButton.setTitle("Update Profile", for: .normal)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide tab bar only
        tabBarController?.tabBar.isHidden = true
        
        // Load existing profile data if available
        Task {
            await loadExistingProfile()
        }
    }
    private func loadExistingProfile() async {
        do {
            guard let userId = supabase.auth.currentUser?.id else { return }
            
            // Fetch casting profile
            let castingProfile: CastingProfileRecord = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Fetch main profile for location
            let profile: ProfileRecord = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                hasExistingCastingProfile = true
                if openedFromProfile {
                    title = "Edit Portfolio"
                }
                
                // Map values to local state
                self.selectedRole = castingProfile.role
                self.governmentIdUrl = castingProfile.governmentIdUrl
                self.selfieUrl = castingProfile.selfieUrl
                self.guildIdCardUrl = castingProfile.guildIdCardUrl
                
                if let expiryStr = castingProfile.membershipExpiry {
                    let formatter = ISO8601DateFormatter()
                    self.selectedMembershipExpiry = formatter.date(from: expiryStr)
                }

                print("✅ Loaded existing profile data")
                
                // Rebuild the UI to reflect loaded data (if needed)
                // In some cases we might want to just apply values if buildLayout was already called
                applyLoadedValuesToForm(profile: profile, casting: castingProfile)
            }
        } catch {
            print("ℹ️ No existing profile found (creating new): \(error)")
        }
    }

    private func applyLoadedValuesToForm(profile: ProfileRecord, casting: CastingProfileRecord) {
        fullNameTextField?.text = casting.fullName ?? profile.fullName
        phoneNumberTextField?.text = casting.phoneNumber ?? profile.phoneNumber
        emailTextField?.text = casting.emailId ?? profile.email
        locationTextField?.text = casting.location ?? profile.locationCity
        
        pastProjectDetailsTextView?.text = casting.pastProjectDetails
        projectRoleTextField?.text = casting.projectRole
        productionHouseTextField?.text = casting.productionHouse
        imdbLinkTextField?.text = casting.imdbLink
        
        companyNameTextField?.text = casting.companyName
        officialEmailTextField?.text = casting.officialWorkEmail
        linkedinTextField?.text = casting.linkedinProfile
        instagramTextField?.text = casting.instagramProfile
        portfolioWebsiteTextField?.text = casting.portfolioWebsite
        
        guildNameTextField?.text = casting.guildName
        membershipNumberTextField?.text = casting.membershipNumber
        industryReferencesTextView?.text = casting.industryReferences
        
        // Update selection UI
        if let role = casting.role {
            updateSelection(tag: 10, value: role)
        }
        
        if let expiry = selectedMembershipExpiry {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            updateSelection(tag: 20, value: formatter.string(from: expiry))
        }
        
        // Update upload indicators
        if governmentIdUrl != nil { updateUIForUpload(identifier: "gov_id") }
        if selfieUrl != nil { updateUIForUpload(identifier: "selfie") }
        if guildIdCardUrl != nil { updateUIForUpload(identifier: "guild_card") }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore tab bar only
        tabBarController?.tabBar.isHidden = false
    }

    @objc private func submitTapped() {
        // Validation for mandatory fields
        if governmentIdUrl == nil {
            showAlert(title: "Missing Information", message: "Please upload your Government ID to proceed. This is mandatory for verification.")
            return
        }
        
        Task {
            do {
                try await saveDirectorProfile()
                await MainActor.run {
                    self.showAlert(title: "Submitted", message: "Your profile has been submitted for verification. You can track the status in your dashboard.") {
                        if self.openedFromProfile {
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            let vc = PostJobViewController()
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            } catch {
                print("❌ Error saving director profile: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func trackTapped() {
        // Feature to track application
        self.showAlert(title: "Application Status", message: "Your verification is currently under review. This usually takes 24-48 hours.")
    }
    
    private func saveDirectorProfile() async throws {
        // Get current user ID
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())

        let castingProfile = CastingProfileRecordForSave(
            id: userId.uuidString,
            fullName: fullNameTextField?.text,
            role: selectedRole,
            phoneNumber: phoneNumberTextField?.text,
            emailId: emailTextField?.text,
            location: locationTextField?.text,
            governmentIdUrl: governmentIdUrl,
            selfieUrl: selfieUrl,
            pastProjectDetails: pastProjectDetailsTextView?.text,
            projectRole: projectRoleTextField?.text,
            productionHouse: productionHouseTextField?.text,
            imdbLink: imdbLinkTextField?.text,
            companyName: companyNameTextField?.text,
            officialWorkEmail: officialEmailTextField?.text,
            linkedinProfile: linkedinTextField?.text,
            instagramProfile: instagramTextField?.text,
            portfolioWebsite: portfolioWebsiteTextField?.text,
            guildIdCardUrl: guildIdCardUrl,
            guildName: guildNameTextField?.text,
            membershipNumber: membershipNumberTextField?.text,
            membershipExpiry: selectedMembershipExpiry.map { dateFormatter.string(from: $0) },
            industryReferences: industryReferencesTextView?.text,
            castingTypes: nil,
            castingRadius: nil,
            contactPreference: nil,
            status: "pending"
        )
        
        try await supabase
            .from("casting_profiles")
            .upsert(castingProfile)
            .execute()
        
        // Also update profiles table
        let profile = ProfileRecordForSave(
            id: userId.uuidString,
            username: nil,
            fullName: fullNameTextField?.text,
            dateOfBirth: nil,
            profilePictureUrl: nil,
            avatarUrl: nil,
            role: "casting_professional",
            employmentStatus: nil,
            locationState: nil,
            postalCode: nil,
            locationCity: locationTextField?.text,
            bio: nil,
            phoneNumber: phoneNumberTextField?.text,
            websiteUrl: portfolioWebsiteTextField?.text,
            isVerified: false,
            connectionCount: 0,
            onboardingCompleted: true,
            lastActiveAt: now,
            bannerUrl: nil
        )
        
        try await supabase
            .from("profiles")
            .upsert(profile)
            .execute()
        
        print("✅ Comprehensive director profile saved successfully")
    }
    
    private func uploadImage(_ image: UIImage, for identifier: String) async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let path = "verifications/\(userId.uuidString)/\(identifier).jpg"
        
        do {
            try await supabase.storage
                .from("profile-pictures")
                .upload(path: path, file: imageData, options: FileOptions(upsert: true))
            
            let url = try supabase.storage
                .from("profile-pictures")
                .getPublicURL(path: path)
            
            await MainActor.run {
                switch identifier {
                case "gov_id": self.governmentIdUrl = url.absoluteString
                case "selfie": self.selfieUrl = url.absoluteString
                case "guild_card": self.guildIdCardUrl = url.absoluteString
                default: break
                }
                
                // Update UI status
                self.updateUIForUpload(identifier: identifier)
            }
        } catch {
            print("❌ Upload failed: \(error)")
        }
    }
    
    private func updateUIForUpload(identifier: String) {
        // Find the row with this identifier and update statusLabel (tag 500)
        let rows = contentView.subviews.compactMap { $0 as? UIStackView }.flatMap { $0.arrangedSubviews }
        for row in rows {
            if row.accessibilityIdentifier == identifier {
                if let statusLbl = row.viewWithTag(500) as? UILabel {
                    statusLbl.text = "✅ Uploaded"
                    statusLbl.textColor = .systemGreen
                }
            }
        }
    }
    
    
    

    
    // MARK: - Layout / Scroll
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func buildLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        // 1. Personal Details
        stack.addArrangedSubview(sectionHeader("Personal Details"))
        stack.addArrangedSubview(inputField(title: "Full Name *", placeholder: "As per ID"))
        stack.addArrangedSubview(selectionCell(title: "Primary Role", value: "Select role", tag: 10))
        stack.addArrangedSubview(inputField(title: "Phone Number *", placeholder: "+91 ..."))
        stack.addArrangedSubview(inputField(title: "Email ID *", placeholder: "your@email.com"))
        stack.addArrangedSubview(inputField(title: "Location *", placeholder: "City, Country"))

        // 2. Identity Verification
        stack.addArrangedSubview(sectionHeader("Identity Verification"))
        stack.addArrangedSubview(documentUploadRow(title: "Government ID *", icon: "doc.text.viewfinder", identifier: "gov_id"))
        stack.addArrangedSubview(documentUploadRow(title: "Live Selfie", icon: "person.badge.shield.fill", identifier: "selfie"))
        
        // 3. Guild & Affiliations (Moved up as requested)
        stack.addArrangedSubview(sectionHeader("Guild & Affiliations"))
        stack.addArrangedSubview(documentUploadRow(title: "Guild ID Card", icon: "card.fill", identifier: "guild_card"))
        stack.addArrangedSubview(inputField(title: "Guild Name", placeholder: "e.g. DGA, WGA"))
        stack.addArrangedSubview(inputField(title: "Membership Number", placeholder: "ID number"))
        stack.addArrangedSubview(selectionCell(title: "Membership Expiry", value: "Select date", tag: 20))

        // 4. Experience & Projects
        stack.addArrangedSubview(sectionHeader("Experience & Projects"))
        stack.addArrangedSubview(textViewField(title: "Past Project Details", placeholder: "List your major projects..."))
        stack.addArrangedSubview(inputField(title: "Role in Projects", placeholder: "e.g. Lead Director"))
        stack.addArrangedSubview(inputField(title: "Production House / Studio Name", placeholder: "e.g. Dharma Productions"))
        stack.addArrangedSubview(inputField(title: "IMDb / YouTube / OTT Links", placeholder: "Links to your work"))

        // 5. Professional Links
        stack.addArrangedSubview(sectionHeader("Professional Links"))
        stack.addArrangedSubview(inputField(title: "Company / Organization Name", placeholder: "Your current company"))
        stack.addArrangedSubview(inputField(title: "Official Work Email", placeholder: "work@company.com"))
        stack.addArrangedSubview(inputField(title: "LinkedIn Profile", placeholder: "linkedin.com/in/..."))
        stack.addArrangedSubview(inputField(title: "Instagram / Professional Social Media", placeholder: "@handle"))
        stack.addArrangedSubview(inputField(title: "Portfolio Website", placeholder: "https://..."))


        // 6. References
        stack.addArrangedSubview(sectionHeader("Industry References"))
        stack.addArrangedSubview(textViewField(title: "Industry References", placeholder: "Name + Role + Contact"))

        stack.addArrangedSubview(verificationCard)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(submitButton)
        stack.addArrangedSubview(trackButton)
        
        if hasExistingCastingProfile {
            trackButton.isHidden = false
            submitButton.setTitle("Update & Re-submit", for: .normal)
        }
    }
    
    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textAlignment = .center
        lbl.textColor = .systemOrange
        lbl.isHidden = true
        return lbl
    }()
}

// MARK: - Bottom Picker View Controller
class BottomPickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let pickerTitle: String
    private let options: [String]
    private let onSelection: (String) -> Void
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.rowHeight = 50
        return table
    }()
    
    private var selectedIndex: Int?
    
    init(title: String, options: [String], onSelection: @escaping (String) -> Void) {
        self.pickerTitle = title
        self.options = options
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        titleLabel.text = pickerTitle
        
        setupViews()
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupViews() {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        headerView.addSubview(cancelButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(doneButton)
        
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add separator line
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        headerView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        if let index = selectedIndex {
            onSelection(options[index])
        }
        dismiss(animated: true)
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.selectionStyle = .none
        
        if indexPath.row == selectedIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

// MARK: - Delegates
extension ProfileInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage,
              let id = picker.accessibilityHint else { return }
        Task {
            await uploadImage(image, for: id)
        }
    }
}

// MARK: - Onboarding Coordinator
extension UITextField {
    func setPaddingLeft(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 44))
        leftView = padding
        leftViewMode = .always
    }
}

// MARK: - Director Profile Record
struct DirectorProfileRecord: Codable {
    let id: String
    let professionalTitle: String?
    let productionHouse: String?
    let companyType: String?
    let experienceYears: String?
    let primaryLocation: String?
    let additionalLocations: String?
    let specializations: [String]
    let unionAffiliations: [String]
    let website: String?
    let imdbProfile: String?
    let preferredContract: String?
    let budgetRange: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case professionalTitle = "professional_title"
        case productionHouse = "production_house"
        case companyType = "company_type"
        case experienceYears = "experience_years"
        case primaryLocation = "primary_location"
        case additionalLocations = "additional_locations"
        case specializations
        case unionAffiliations = "union_affiliations"
        case website
        case imdbProfile = "imdb_profile"
        case preferredContract = "preferred_contract"
        case budgetRange = "budget_range"
    }
}
