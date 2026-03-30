import UIKit
import AVFoundation
import Supabase

final class TaskDetailsViewController: UIViewController {
    
    // MARK: - Properties
    var job: Job?
    private var castingProfile: CastingProfileRecord?
    // Use shared authenticated Supabase client defined in auth/Supabase.swift to avoid session mismatch
    // Removed local SupabaseClient
    
    // MARK: - Colors (matched from screenshot)
    private let plum = UIColor(hex: "#5A4459")
    private let deepPlum = UIColor(hex: "#2E0321")
    private let tagPurple = UIColor(hex: "#5A4459")
    private let lightBg = UIColor(hex: "#F5F5F5")
    private let cardGray = UIColor(hex: "#F0F0F0")
    private let textGray = UIColor(hex: "#8E8E93")
    
    // MARK: - Views
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()
    
    // MARK: - Upload Storage
    private var selectedMediaThumbnail: UIImage?
    private var selectedMediaURL: URL?
    private var uploadContainer: UIStackView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = lightBg
        navigationItem.title = "Task Details"
        setupScrollView()
        setupStack()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
        
        // Fetch profile data and rebuild content when view appears
        Task {
            await fetchSavedCastingProfile()
            await MainActor.run {
                buildContent()
            }
        }
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

    private func showSubmissionSuccess() {
        let dim = UIView(frame: view.bounds)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dim.alpha = 0
        dim.tag = 5001
        view.addSubview(dim)
        
        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 18
        popup.clipsToBounds = true
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        popup.tag = 5002
        
        view.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 250),
            popup.heightAnchor.constraint(equalToConstant: 210)
        ])
        
        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = plum
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = "Task Submitted!"
        title.font = .boldSystemFont(ofSize: 18)
        title.textColor = .black
        title.textAlignment = .center
        
        let msg = UILabel()
        msg.text = "Your audition has been successfully submitted."
        msg.font = .systemFont(ofSize: 14)
        msg.textColor = .darkGray
        msg.textAlignment = .center
        msg.numberOfLines = 2
        
        let stack = UIStackView(arrangedSubviews: [check, title, msg])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(stack)
        
        NSLayoutConstraint.activate([
            check.heightAnchor.constraint(equalToConstant: 52),
            check.widthAnchor.constraint(equalToConstant: 52),
            
            stack.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: popup.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -16)
        ])
        
        UIView.animate(withDuration: 0.25) {
            dim.alpha = 1
            popup.alpha = 1
            popup.transform = .identity
        }
        
        check.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.1,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut
        ) {
            check.transform = .identity
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.25, animations: {
                dim.alpha = 0
                popup.alpha = 0
            }) { _ in
                dim.removeFromSuperview()
                popup.removeFromSuperview()
            }
        }
    }

    // MARK: - Scroll Setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        
        scrollView.addSubview(contentView)
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
    
    private func setupStack() {
        contentView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Fetch Profile
    private func fetchSavedCastingProfile() async {
        do {
            guard let userId = supabase.auth.currentUser?.id else {
                print("⚠️ No authenticated user")
                return
            }
            
            let profile: CastingProfileRecord = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            self.castingProfile = profile
            print("✅ Fetched casting profile: \(profile.companyName ?? "N/A")")
        } catch {
            print("⚠️ No saved casting profile found: \(error)")
            self.castingProfile = nil
        }
    }
    
    // MARK: - Build UI
    private func buildContent() {
        // Clear existing content
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Debug: Check if job data is available
        if let job = job {
            print("📋 TaskDetailsViewController - Job data available:")
            print("   Title: \(job.title)")
            print("   Company: \(job.companyName)")
            print("   Description: \(job.description ?? "nil")")
            print("   Requirements: \(job.requirements ?? "nil")")
            print("   Reference Material URL: \(job.referenceMaterialUrl ?? "nil")")
        } else {
            print("⚠️ TaskDetailsViewController - No job data available, using fallback")
        }
        
        // Rebuild with job data
        // Add profile info card if profile exists
        if let profile = castingProfile {
            stack.addArrangedSubview(createProfileSummaryCard(profile))
        }
        stack.addArrangedSubview(makeTopTaskCard())
        stack.addArrangedSubview(makeSceneCard())
        stack.addArrangedSubview(makeCharacterCard())
        stack.addArrangedSubview(makeReferenceCard())
        stack.addArrangedSubview(makeUploadCard())
        stack.addArrangedSubview(makeSubmitButton())
    }
    
    // MARK: - Profile Summary Card
    private func createProfileSummaryCard(_ profile: CastingProfileRecord) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 90/255, green: 68/255, blue: 89/255, alpha: 0.08)
        card.layer.cornerRadius = 16
        card.layer.borderColor = plum.withAlphaComponent(0.2).cgColor
        card.layer.borderWidth = 1
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Header with icon and title
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkIcon.tintColor = plum
        checkIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        checkIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Profile Information"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = plum
        
        headerStack.addArrangedSubview(checkIcon)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView()) // Spacer
        
        // Edit button
        let editButton = UIButton(type: .system)
        editButton.setTitle("Change", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        editButton.setTitleColor(plum, for: .normal)
        editButton.addTarget(self, action: #selector(changeProfileTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(editButton)
        
        stack.addArrangedSubview(headerStack)
        
        // Profile details
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 4
        
        // Company name
        if let companyName = profile.companyName, !companyName.isEmpty {
            let companyLabel = UILabel()
            companyLabel.text = "Company: \(companyName)"
            companyLabel.font = UIFont.systemFont(ofSize: 13)
            companyLabel.textColor = .darkGray
            detailsStack.addArrangedSubview(companyLabel)
        }
        
        // Specific role / Professional title
        if let role = profile.specificRole, !role.isEmpty {
            let roleLabel = UILabel()
            roleLabel.text = "Role: \(role)"
            roleLabel.font = UIFont.systemFont(ofSize: 13)
            roleLabel.textColor = .darkGray
            detailsStack.addArrangedSubview(roleLabel)
        }
        
        stack.addArrangedSubview(detailsStack)
        
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
        
        return card
    }
    
    // MARK: - Change Profile Action
    @objc private func changeProfileTapped() {
        let profileVC = ProfileInfoViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // MARK: - View Reference Action
    @objc private func viewReferenceTapped() {
        guard let urlString = job?.referenceMaterialUrl,
              let url = URL(string: urlString) else {
            print("⚠️ Invalid reference material URL")
            return
        }
        
        // Open in Safari or media player
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Card Factory
    private func createCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }
    
    private func makeTopTaskCard() -> UIView {
        let card = createCard()
        
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: - Top Row (Icon + Title)
        let iconBG = UIView()
        iconBG.backgroundColor = plum
        iconBG.layer.cornerRadius = 10
        iconBG.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "video.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        iconBG.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBG.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBG.centerYAnchor),
            iconBG.widthAnchor.constraint(equalToConstant: 46),
            iconBG.heightAnchor.constraint(equalToConstant: 46)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = job?.title ?? "Lead Actor – City of Dreams"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        
        let subtitle = UILabel()
        subtitle.text = job?.companyName ?? "YRF Casting"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = textGray
        
        // Title + Subtitle stacked vertically
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitle])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        
        let topRow = UIStackView(arrangedSubviews: [iconBG, titleStack])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.alignment = .center
        
        // MARK: - Tag Row (Tag + Due Date)
        let tag = smallTag(text: "New Task")
        
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = textGray
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        
       
        NSLayoutConstraint.activate([
            calendarIcon.widthAnchor.constraint(equalToConstant: 16),
            calendarIcon.heightAnchor.constraint(equalToConstant: 16)
        ])

        
        let dueLabel = UILabel()
        if let deadline = job?.applicationDeadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            dueLabel.text = "Due: \(formatter.string(from: deadline))"
        } else {
            dueLabel.text = "Due: No deadline"
        }
        dueLabel.font = .systemFont(ofSize: 13)
        dueLabel.textColor = textGray
        
        let dueRow = UIStackView(arrangedSubviews: [calendarIcon, dueLabel])
        dueRow.axis = .horizontal
        dueRow.spacing = 8
        dueRow.alignment = .center
        dueRow.distribution = .fill

        
        let bottomRow = UIStackView(arrangedSubviews: [tag, dueRow])
        bottomRow.spacing = 12   // adjust this number

        
        // MARK: - Assemble
        container.addArrangedSubview(topRow)
        container.addArrangedSubview(bottomRow)
        
        card.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }

    
    private func makeSceneCard() -> UIView {
        let card = createCard()
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        
        // Extract task title and description from job
        // The job title is the overall job title, but we want the task description title
        // For now, use the first part of the description or the job title
        let taskDescriptionText = extractTaskDescription(from: job?.description ?? "")
        let taskTitle = taskDescriptionText?.components(separatedBy: "\n").first ?? job?.title ?? "Task Details"
        let taskDescription = taskDescriptionText ?? job?.description ?? "No task description available."
        
        v.addArrangedSubview(sectionTitle(taskTitle))
        v.addArrangedSubview(paragraph(taskDescription))
        v.addArrangedSubview(sectionTitle("Requirements"))
        
        // Parse requirements from job requirements field
        let reqs = parseRequirements(from: job?.requirements)
        
        let reqStack = UIStackView()
        reqStack.axis = .vertical
        reqStack.spacing = 8
        
        for r in reqs {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.alignment = .top
            
            let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            check.tintColor = .systemGreen
            check.widthAnchor.constraint(equalToConstant: 20).isActive = true
            check.heightAnchor.constraint(equalToConstant: 20).isActive = true
            check.translatesAutoresizingMaskIntoConstraints = false
            
            let label = paragraph(r)
            
            row.addArrangedSubview(check)
            row.addArrangedSubview(label)
            reqStack.addArrangedSubview(row)
        }
        
        v.addArrangedSubview(reqStack)
        
        card.addSubview(v)
        
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    private func makeCharacterCard() -> UIView {
        let card = createCard()
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        
        // Extract character info from job description
        let charInfo = extractCharacterInfo(from: job?.description ?? "")
        let charName = charInfo.name ?? "Character"
        let charDesc = charInfo.description ?? "No character description available."
        let personality = charInfo.personality ?? "No personality traits specified."
        let ageRange = charInfo.ageRange ?? "Not specified"
        let genre = job?.jobType ?? "Drama"
        
        v.addArrangedSubview(sectionTitle("Character: \(charName)"))
        v.addArrangedSubview(boldLabel("Description"))
        v.addArrangedSubview(paragraph(charDesc))
        
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 16
        
        row.addArrangedSubview(verticalSmall(title: "Age range", value: ageRange))
        row.addArrangedSubview(verticalSmall(title: "Genre", value: genre))
        
        v.addArrangedSubview(row)
        v.addArrangedSubview(boldLabel("Personality"))
        v.addArrangedSubview(paragraph(personality))
        
        card.addSubview(v)
        
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    private func makeReferenceCard() -> UIView {
        let card = createCard()
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        
        // Extract scene info from requirements
        let sceneInfo = extractSceneInfo(from: job?.requirements ?? "")
        let sceneTitle = sceneInfo.title ?? "Scene"
        let setting = sceneInfo.setting ?? "No setting description available."
        let duration = sceneInfo.duration ?? "Not specified"
        let genre = job?.jobType ?? "Drama"
        
        v.addArrangedSubview(sectionTitle("Scene: \(sceneTitle)"))
        v.addArrangedSubview(boldLabel("Setting"))
        v.addArrangedSubview(paragraph(setting))
        
        let durationRow = UIStackView()
        durationRow.axis = .horizontal
        durationRow.distribution = .fillEqually
        durationRow.spacing = 16
        
        durationRow.addArrangedSubview(verticalSmall(title: "Duration", value: duration))
        durationRow.addArrangedSubview(verticalSmall(title: "Genre", value: genre))
        
        v.addArrangedSubview(durationRow)
        v.addArrangedSubview(boldLabel("Reference Scene"))
        
        // Check if reference material exists
        if let referenceMaterialUrl = job?.referenceMaterialUrl, !referenceMaterialUrl.isEmpty {
            let ref = UIView()
            ref.backgroundColor = cardGray
            ref.layer.cornerRadius = 12
            ref.heightAnchor.constraint(equalToConstant: 140).isActive = true
            
            let refStack = UIStackView()
            refStack.axis = .vertical
            refStack.spacing = 10
            refStack.alignment = .center
            refStack.translatesAutoresizingMaskIntoConstraints = false
            
            // Show video icon for videos, doc icon for other files
            let iconName = referenceMaterialUrl.contains("mp4") || referenceMaterialUrl.contains("mov") ? "play.circle.fill" : "doc.fill"
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = plum
            icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            refStack.addArrangedSubview(icon)
            refStack.addArrangedSubview(smallLabel("Reference material uploaded"))
            
            ref.addSubview(refStack)
            
            NSLayoutConstraint.activate([
                refStack.centerXAnchor.constraint(equalTo: ref.centerXAnchor),
                refStack.centerYAnchor.constraint(equalTo: ref.centerYAnchor)
            ])
            
            v.addArrangedSubview(ref)
            
            let watch = UIButton(type: .system)
            watch.setTitle("View Reference", for: .normal)
            watch.backgroundColor = .white
            watch.setTitleColor(.label, for: .normal)
            watch.layer.cornerRadius = 10
            watch.layer.borderColor = UIColor.systemGray4.cgColor
            watch.layer.borderWidth = 1
            watch.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            watch.heightAnchor.constraint(equalToConstant: 44).isActive = true
            watch.addTarget(self, action: #selector(viewReferenceTapped), for: .touchUpInside)
            
            v.addArrangedSubview(watch)
        } else {
            // No reference material
            let noRefLabel = UILabel()
            noRefLabel.text = "No reference material provided"
            noRefLabel.font = .systemFont(ofSize: 14)
            noRefLabel.textColor = textGray
            noRefLabel.textAlignment = .center
            v.addArrangedSubview(noRefLabel)
        }
        
        card.addSubview(v)
        
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    // MARK: - Upload Card
    private func makeUploadCard() -> UIView {
        let card = createCard()
        
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        uploadContainer = v
        
        v.addArrangedSubview(sectionTitle("Submit Your Performance"))
        
        let uploadBtn = UIButton(type: .system)
        uploadBtn.setTitle("  Upload Your Audition", for: .normal)
        uploadBtn.setTitleColor(.white, for: .normal)
        uploadBtn.backgroundColor = plum
        uploadBtn.layer.cornerRadius = 10
        uploadBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        uploadBtn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        uploadBtn.tintColor = .white
        uploadBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        uploadBtn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        uploadBtn.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        
        v.addArrangedSubview(uploadBtn)
        v.addArrangedSubview(smallLabel("Upload your video, audio, or document files for review"))
        
        card.addSubview(v)
        
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    @objc private func uploadTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = ["public.movie", "public.image"]
        picker.videoQuality = .typeMedium
        present(picker, animated: true)
    }
    
    private func updateUploadPreview() {
        guard let stack = uploadContainer else { return }
        
        if let old = stack.arrangedSubviews.first(where: { $0.tag == 999 }) {
            stack.removeArrangedSubview(old)
            old.removeFromSuperview()
        }
        
        let preview = UIStackView()
        preview.axis = .horizontal
        preview.spacing = 12
        preview.alignment = .center
        preview.tag = 999
        preview.backgroundColor = cardGray
        preview.layer.cornerRadius = 10
        preview.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        preview.isLayoutMarginsRelativeArrangement = true
        
        let thumb = UIImageView(image: selectedMediaThumbnail ?? UIImage(systemName: "photo"))
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.widthAnchor.constraint(equalToConstant: 80).isActive = true
        thumb.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.text = selectedMediaURL?.lastPathComponent ?? "Image Selected"
        
        preview.addArrangedSubview(thumb)
        preview.addArrangedSubview(label)
        
        stack.addArrangedSubview(preview)
    }
    
    private func generateVideoThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            
            if let cgImage = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                completion(UIImage(cgImage: cgImage))
            } else {
                completion(nil)
            }
        }
    }
    
    private func makeSubmitButton() -> UIView {
        let container = UIView()
        let btn = UIButton(type: .system)
        btn.setTitle("Submit Application", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = deepPlum
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(btn)
        btn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            btn.heightAnchor.constraint(equalToConstant: 52),
            btn.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func submitTapped() {
        Task {
            await submitTaskAndApplication()
        }
    }
    
    private func submitTaskAndApplication() async {
        guard let job = job,
              let videoURL = selectedMediaURL,
              let currentUser = supabase.auth.currentUser else {
            showAlert(title: "Error", message: "Please select a video and try again")
            return
        }
        
        do {
            let actorId = UUID(uuidString: currentUser.id.uuidString) ?? UUID()
            
            // Step 0: Upload video to storage (with retry)
            let fileName = "auditions/\(job.id)/\(actorId)/\(UUID().uuidString).mp4"
            var publicURL: String = ""
            
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? NSNumber {
                let sizeMB = fileSize.doubleValue / (1024.0 * 1024.0)
                if sizeMB > 200 {
                    showAlert(title: "File too large", message: "Please upload a smaller video (<= 200MB) or compress it and try again.")
                    return
                }
            }
            
            func attemptUpload() async throws {
                let videoData = try Data(contentsOf: videoURL, options: [.mappedIfSafe])
                _ = try await supabase.storage
                    .from("videos")
                    .upload(fileName, data: videoData, options: FileOptions(cacheControl: "3600", contentType: "video/mp4"))
            }
            
            var uploadSucceeded = false
            var lastError: Error?
            for attempt in 1...3 {
                do {
                    try await attemptUpload()
                    uploadSucceeded = true
                    break
                } catch {
                    lastError = error
                    try? await Task.sleep(nanoseconds: UInt64(0.8 * Double(attempt) * 1_000_000_000))
                }
            }
            
            if !uploadSucceeded {
                let message = lastError?.localizedDescription ?? "Unknown upload error"
                showAlert(title: "Upload failed", message: "Could not upload your video: \(message). Please check your internet connection and try again.")
                return
            }
            
            publicURL = try supabase.storage
                .from("videos")
                .getPublicURL(path: fileName).absoluteString
            print("✅ Video uploaded to: \(publicURL)")
            
            // Step 1: Find existing application (portfolio_submitted status)
            let applications: [Application] = try await supabase
                .from("applications")
                .select()
                .eq("job_id", value: job.id.uuidString)
                .eq("actor_id", value: actorId.uuidString)
                .execute()
                .value
            
            guard let application = applications.first else {
                showAlert(title: "Error", message: "No application found. Please submit portfolio first.")
                return
            }
            
            // Step 2: Create updated application with new status
            let updatedApplication = Application(
                id: application.id,
                jobId: application.jobId,
                actorId: application.actorId,
                status: .taskSubmitted,
                portfolioUrl: application.portfolioUrl,
                portfolioSubmittedAt: application.portfolioSubmittedAt,
                appliedAt: application.appliedAt,
                updatedAt: Date()
            )
            
            let _: Application = try await supabase
                .from("applications")
                .update(updatedApplication)
                .eq("id", value: application.id.uuidString)
                .single()
                .execute()
                .value
            
            // Step 3: Get task for this job (from 'tasks' table)
            var jobTaskId: UUID? = nil
            do {
                struct TaskRow: Decodable { let id: UUID }
                print("🔍 Fetching tasks for job ID: \(job.id.uuidString)")
                let tasks: [TaskRow] = try await supabase
                    .from("tasks")
                    .select("id")
                    .eq("job_id", value: job.id.uuidString)
                    .execute()
                    .value
                
                print("   Found \(tasks.count) task(s)")
                if let task = tasks.first {
                    jobTaskId = task.id
                    print("   ✅ Using existing task ID: \(task.id.uuidString)")
                } else {
                    // No task exists, we need to create one
                    print("   ⚠️ No tasks found, creating one...")
                    let newTaskId = UUID()
                    
                    // Create a minimal task record for this job
                    struct TaskInput: Encodable {
                        let id: UUID
                        let job_id: UUID
                        let task_title: String
                        let task_description: String
                        let created_at: Date
                    }
                    
                    let newTask = TaskInput(
                        id: newTaskId,
                        job_id: job.id,
                        task_title: "Task Submission",
                        task_description: "Task for actor submission",
                        created_at: Date()
                    )
                    
                    do {
                        let _: TaskRow = try await supabase
                            .from("tasks")
                            .insert(newTask)
                            .select()
                            .single()
                            .execute()
                            .value
                        jobTaskId = newTaskId
                        print("   ✅ Created new task ID: \(newTaskId.uuidString)")
                    } catch {
                        print("   ❌ Failed to create task: \(error)")
                        // Continue anyway, we'll use the ID but it may fail on submission
                        jobTaskId = newTaskId
                    }
                }
            } catch {
                print("⚠️ Warning: Could not fetch tasks for job: \(error)")
            }
            
            // Step 4: Create task submission record only if taskId exists
            if let taskId = jobTaskId {
                print("📤 Creating task submission with:")
                print("   - Task ID: \(taskId.uuidString)")
                print("   - Application ID: \(application.id.uuidString)")
                print("   - Actor ID: \(actorId.uuidString)")
                print("   - Video URL: \(publicURL)")
                
                let taskSubmission = TaskSubmission(
                    id: UUID(),
                    applicationId: application.id,
                    taskId: taskId,
                    actorId: actorId,
                    submissionUrl: publicURL,
                    submissionType: .video,
                    thumbnailUrl: nil,
                    actorNotes: nil,
                    status: .submitted,
                    submittedAt: Date(),
                    reviewedAt: nil
                )
                
                do {
                    let _: TaskSubmission = try await supabase
                        .from("task_submissions")
                        .insert(taskSubmission)
                        .single()
                        .execute()
                        .value
                    print("✅ Task submission created successfully!")
                } catch {
                    print("❌ Error creating task submission: \(error)")
                }
            } else {
                print("❌ Cannot create task submission - no valid task ID available")
            }
            
            // Step 5: Show success and navigate
            showSubmissionSuccess()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            
        } catch {
            showAlert(title: "Error", message: "Failed to submit task: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
    }
    
    // MARK: - UI Helpers
    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        return l
    }
    
    private func boldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        return l
    }
    
    private func paragraph(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15)
        l.textColor = textGray
        l.numberOfLines = 0
        return l
    }
    
    private func smallLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13)
        l.textColor = textGray
        l.numberOfLines = 0
        return l
    }
    
    private func smallTag(text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = tagPurple
        l.textAlignment = .center
        l.layer.cornerRadius = 12
        l.clipsToBounds = true
        l.heightAnchor.constraint(equalToConstant: 26).isActive = true
        l.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        return l
    }

    private func verticalSmall(title: String, value: String) -> UIView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 4
        
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 14)
        t.textColor = textGray
        
        let val = UILabel()
        val.text = value
        val.font = .systemFont(ofSize: 15)
        
        v.addArrangedSubview(t)
        v.addArrangedSubview(val)
        
        return v
    }
    
    // MARK: - Data Extraction Helpers
    private func extractTaskDescription(from description: String) -> String? {
        // The description starts with the task description before any "Character:" marker
        if let charRange = description.range(of: "\n\nCharacter:") {
            let taskDesc = String(description[..<charRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return taskDesc.isEmpty ? nil : taskDesc
        }
        return description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description
    }
    
    private struct CharacterInfo {
        let name: String?
        let description: String?
        let personality: String?
        let ageRange: String?
    }
    
    private func extractCharacterInfo(from description: String) -> CharacterInfo {
        var name: String?
        var charDescription: String?
        var personality: String?
        var ageRange: String?
        
        // Look for "Character:" marker
        if let charRange = description.range(of: "\n\nCharacter:") {
            let charSection = String(description[charRange.upperBound...])
            let lines = charSection.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            // First line after "Character:" is the character name
            if let firstLine = lines.first, !firstLine.hasPrefix("Personality:") && !firstLine.hasPrefix("Age:") {
                name = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Find personality section
            if let personalityRange = charSection.range(of: "\n\nPersonality:") {
                // Everything between Character name and Personality is the character description
                let descPart = String(charSection[..<personalityRange.lowerBound])
                var descLines: [String] = []
                var foundAge = false
                
                for line in descPart.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.hasPrefix("Age:") {
                        ageRange = String(trimmed.dropFirst("Age:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                        foundAge = true
                    } else if !trimmed.isEmpty && trimmed != name {
                        descLines.append(trimmed)
                    }
                }
                charDescription = descLines.joined(separator: " ")
                
                // Personality is after "Personality:"
                personality = String(charSection[personalityRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // No personality section, parse lines for description and age
                var descLines: [String] = []
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.hasPrefix("Age:") {
                        ageRange = String(trimmed.dropFirst("Age:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if !trimmed.isEmpty && trimmed != name {
                        descLines.append(trimmed)
                    }
                }
                charDescription = descLines.joined(separator: " ")
            }
        }
        
        return CharacterInfo(name: name, description: charDescription, personality: personality, ageRange: ageRange)
    }
    
    private func parseRequirements(from requirements: String?) -> [String] {
        guard let requirements = requirements, !requirements.isEmpty else {
            return [
                "Memorize the provided monologue",
                "Record in landscape mode with good lighting",
                "No costume changes needed - business casual",
                "Submit by deadline for review"
            ]
        }
        
        // Split requirements by newlines
        let lines = requirements.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("Scene:") && !$0.hasPrefix("Setting:") && !$0.hasPrefix("Duration:") }
        
        return lines.isEmpty ? [
            "Memorize the provided monologue",
            "Record in landscape mode with good lighting",
            "No costume changes needed - business casual",
            "Submit by deadline for review"
        ] : lines
    }
    
    private struct SceneInfo {
        let title: String?
        let setting: String?
        let duration: String?
    }
    
    private func extractSceneInfo(from requirements: String) -> SceneInfo {
        var title: String?
        var setting: String?
        var duration: String?
        
        let lines = requirements.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("Scene:") {
                title = String(trimmed.dropFirst("Scene:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Setting:") {
                setting = String(trimmed.dropFirst("Setting:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Duration:") {
                duration = String(trimmed.dropFirst("Duration:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return SceneInfo(title: title, setting: setting, duration: duration)
    }
}

// MARK: - Picker Delegate
extension TaskDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        if let url = info[.mediaURL] as? URL {
            selectedMediaURL = url
            generateVideoThumbnail(from: url) { [weak self] img in
                DispatchQueue.main.async {
                    self?.selectedMediaThumbnail = img
                    self?.updateUploadPreview()
                }
            }
        }
        else if let img = info[.originalImage] as? UIImage {
            selectedMediaThumbnail = img
            selectedMediaURL = nil
            updateUploadPreview()
        }
    }
}

// MARK: - UIColor Hex Helper
fileprivate extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.remove(at: s.startIndex) }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: alpha
        )
    }
}
