import UIKit
import PhotosUI
import Supabase

// MARK: - Custom Color
extension UIColor {
    static let appPurple = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1) // #431631
}

class PostJobViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let assignTaskButton = UIButton.createFilledButton(title: "Assign Task")
    private let cancelButton = UIButton.createOutlineButton(title: "Cancel")
    
    // MARK: - Form Data Properties
    private var taskTitleTextField: UITextField?
    private var taskDescriptionTextView: UITextView?
    private var dueDateTextField: UITextField?
    private var characterNameTextField: UITextField?
    private var characterDescriptionTextView: UITextView?
    private var characterAgeTextField: UITextField?
    private var applicationDeadlineTextField: UITextField?
    private var genreLabel: UILabel?
    private var personalityTraitsTextView: UITextView?
    private var sceneTitleTextField: UITextField?
    private var settingDescriptionTextView: UITextView?
    private var expectedDurationTextField: UITextField?
    private var paymentAmountTextField: UITextField?
    private var uploadedFileName: UILabel?
    private var selectedDueDate: Date?
    private var selectedDeadlineDate: Date?
    private var selectedGenre: String?
    private var uploadedFileURL: URL?
    
    // MARK: - Date Pickers
    private let dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.minimumDate = Date()
        return picker
    }()
    
    private let deadlineDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.minimumDate = Date()
        return picker
    }()
    
    // MARK: - Animation Components
    private let successOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let successAnimationView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkmarkView: CheckmarkView = {
        let view = CheckmarkView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let successLabel: UILabel = {
        let label = UILabel()
        label.text = "Task Assigned Successfully!"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .appPurple
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let successSubLabel: UILabel = {
        let label = UILabel()
        label.text = "Actor will be notified"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Saved Profile Properties
    private var savedCastingProfile: CastingProfileRecord?
    private var profileSummaryCard: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavBar()
        setupScrollView()
        buildForm()
        setupBottomButtons()
        setupSuccessAnimation()
        setupDatePickers()
        setupKeyboardDismissal()
        
        // Fetch saved casting profile
        Task {
            await fetchSavedCastingProfile()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            // Hide tab bar only
            tabBarController?.tabBar.isHidden = true

            // If you also have a floating button on your custom TabBarController,
            // you'll need to hide/show it here as well. Example:
            // (Assuming your tabBar controller has a `floatingButton` property)
            //
            // if let tb = tabBarController as? CineMystTabBarController {
            //     tb.setFloatingButton(hidden: true)
            // }
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


    // MARK: - Navigation Bar
    private func setupNavBar() {
        title = "Post a job"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    // MARK: - ScrollView + Content
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemGroupedBackground
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100)
        ])
    }
    
    // MARK: - Date Picker Setup
    private func setupDatePickers() {
        dueDatePicker.addTarget(self, action: #selector(dueDateChanged), for: .valueChanged)
        deadlineDatePicker.addTarget(self, action: #selector(deadlineDateChanged), for: .valueChanged)
    }
    
    // MARK: - Keyboard Dismissal
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Date Picker Actions
    @objc private func dueDateChanged() {
        selectedDueDate = dueDatePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dueDateTextField?.text = formatter.string(from: dueDatePicker.date)
    }
    
    @objc private func deadlineDateChanged() {
        selectedDeadlineDate = deadlineDatePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        applicationDeadlineTextField?.text = formatter.string(from: deadlineDatePicker.date)
    }
    
    // MARK: - Genre Selection
    @objc private func genreDropdownTapped() {
        let genres = ["Drama", "Comedy", "Action", "Horror", "Sci-Fi", "Romance"]
        
        let alert = UIAlertController(title: "Select Genre", message: nil, preferredStyle: .actionSheet)
        
        for genre in genres {
            alert.addAction(UIAlertAction(title: genre, style: .default, handler: { [weak self] _ in
                self?.selectedGenre = genre
                self?.genreLabel?.text = genre
                self?.genreLabel?.textColor = .label
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - File Upload
    @objc private func uploadFileTapped() {
        let alert = UIAlertController(title: "Upload Reference Material", message: "Choose source", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { [weak self] _ in
            self?.presentDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    // MARK: - Success Animation Setup
    private func setupSuccessAnimation() {
        view.addSubview(successOverlay)
        view.addSubview(successAnimationView)
        successAnimationView.addSubview(checkmarkView)
        successAnimationView.addSubview(successLabel)
        successAnimationView.addSubview(successSubLabel)
        
        NSLayoutConstraint.activate([
            successOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            successOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            successOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            successOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            successAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            successAnimationView.widthAnchor.constraint(equalToConstant: 240),
            successAnimationView.heightAnchor.constraint(equalToConstant: 260),
            
            checkmarkView.centerXAnchor.constraint(equalTo: successAnimationView.centerXAnchor),
            checkmarkView.topAnchor.constraint(equalTo: successAnimationView.topAnchor, constant: 50),
            checkmarkView.widthAnchor.constraint(equalToConstant: 80),
            checkmarkView.heightAnchor.constraint(equalToConstant: 80),
            
            successLabel.topAnchor.constraint(equalTo: checkmarkView.bottomAnchor, constant: 30),
            successLabel.leadingAnchor.constraint(equalTo: successAnimationView.leadingAnchor, constant: 24),
            successLabel.trailingAnchor.constraint(equalTo: successAnimationView.trailingAnchor, constant: -24),
            
            successSubLabel.topAnchor.constraint(equalTo: successLabel.bottomAnchor, constant: 8),
            successSubLabel.leadingAnchor.constraint(equalTo: successAnimationView.leadingAnchor, constant: 24),
            successSubLabel.trailingAnchor.constraint(equalTo: successAnimationView.trailingAnchor, constant: -24)
        ])
        
        // Add tap gesture to dismiss animation
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSuccessAnimation))
        successOverlay.addGestureRecognizer(tapGesture)
        
        // Add button actions
        assignTaskButton.addTarget(self, action: #selector(assignTaskTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    // MARK: - Assign Task Action
    @objc private func assignTaskTapped() {
        // Disable button during animation
        assignTaskButton.isEnabled = false
        cancelButton.isEnabled = false
        
        // Validate required fields
        guard let taskTitle = taskTitleTextField?.text, !taskTitle.isEmpty else {
            showAlert(title: "Missing Field", message: "Task Title is required")
            assignTaskButton.isEnabled = true
            cancelButton.isEnabled = true
            return
        }
        
        guard let taskDescription = taskDescriptionTextView?.text, 
              taskDescription != "Describe what the actor needs...",
              !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Field", message: "Description is required")
            assignTaskButton.isEnabled = true
            cancelButton.isEnabled = true
            return
        }
        
        guard let applicationDeadline = selectedDeadlineDate else {
            showAlert(title: "Missing Field", message: "Application Deadline is required")
            assignTaskButton.isEnabled = true
            cancelButton.isEnabled = true
            return
        }
        
        // Extract payment amount
        let paymentText = paymentAmountTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "5000"
        let paymentValue = Int(paymentText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 5000
        
        // Extract other form values
        let characterName = characterNameTextField?.text ?? ""
        let characterDescription = characterDescriptionTextView?.text ?? ""
        let sceneTitle = sceneTitleTextField?.text ?? ""
        let genre = selectedGenre ?? "Drama"
        
        // Create description combining task and character info
        var combinedDescription = taskDescription
        if !characterName.isEmpty || !characterDescription.isEmpty {
            combinedDescription += "\n\nCharacter: \(characterName)"
            if !characterDescription.isEmpty {
                combinedDescription += "\n\(characterDescription)"
            }
            // Add age range if available
            if let age = characterAgeTextField?.text, !age.isEmpty {
                combinedDescription += "\nAge: \(age)"
            }
        }
        if let personality = personalityTraitsTextView?.text, 
           personality != "e.g., confident, emotional",
           !personality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            combinedDescription += "\n\nPersonality: \(personality)"
        }
        
        // Create requirements from scene info
        var requirements = ""
        if !sceneTitle.isEmpty {
            requirements += "Scene: \(sceneTitle)\n"
        }
        if let setting = settingDescriptionTextView?.text,
           setting != "Describe the setting",
           !setting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            requirements += "Setting: \(setting)\n"
        }
        if let duration = expectedDurationTextField?.text, !duration.isEmpty {
            requirements += "Duration: \(duration)"
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Save job to database
        Task {
            do {
                // Get current user ID (director ID)
                guard let userId = try await getCurrentUserId() else {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: "User not authenticated")
                        self.assignTaskButton.isEnabled = true
                        self.cancelButton.isEnabled = true
                    }
                    return
                }
                
                // For now, use placeholder values for company and location
                // These should ideally come from ProfileInfoViewController
                let companyName = "Production Company" // TODO: Get from profile
                let location = "Mumbai, India" // TODO: Get from profile
                
                // Upload reference material if selected
                var referenceMaterialUrl: String? = nil
                if let fileURL = uploadedFileURL {
                    print("📤 Starting file upload: \(fileURL.lastPathComponent)")
                    do {
                        referenceMaterialUrl = try await uploadReferenceFile(fileURL)
                        print("✅ Uploaded reference material successfully")
                        print("   URL: \(referenceMaterialUrl ?? "nil")")
                    } catch {
                        print("❌ Failed to upload reference material: \(error)")
                        print("   Error details: \(error.localizedDescription)")
                        // Show alert but continue without reference material
                        await MainActor.run {
                            let alert = UIAlertController(
                                title: "Upload Failed",
                                message: "Reference material could not be uploaded. Job will be created without it. Error: \(error.localizedDescription)",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "Continue", style: .default))
                            self.present(alert, animated: true)
                        }
                        // Give user time to see the alert
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                } else {
                    print("ℹ️ No reference material file selected")
                }
                
                // Create Job object
                let job = Job(
                    id: UUID(),
                    directorId: userId,
                    title: taskTitle,
                    companyName: companyName,
                    location: location,
                    ratePerDay: paymentValue,
                    jobType: genre,
                    description: combinedDescription.isEmpty ? nil : combinedDescription,
                    requirements: requirements.isEmpty ? nil : requirements,
                    referenceMaterialUrl: referenceMaterialUrl,
                    status: .active,
                    applicationDeadline: applicationDeadline,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Save to database
                let savedJob = try await JobsService.shared.createJob(job)
                print("✅ Job saved successfully: \(savedJob.id)")
                print("   Reference Material URL in saved job: \(savedJob.referenceMaterialUrl ?? "nil")")
                
                // Show success animation
                await MainActor.run {
                    self.showSuccessAnimation()
                }
            } catch {
                print("❌ Error saving job: \(error)")
                print("   Error details: \(error)")
                if let decodingError = error as? DecodingError {
                    print("   Decoding error: \(decodingError)")
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type), context: \(context)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type), context: \(context)")
                    case .keyNotFound(let key, let context):
                        print("   Key not found: \(key), context: \(context)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
                await MainActor.run {
                    let errorMessage = (error as? DecodingError) != nil 
                        ? "Failed to save job: Invalid data format. Please check all fields."
                        : "Failed to save job: \(error.localizedDescription)"
                    self.showAlert(title: "Error", message: errorMessage)
                    self.assignTaskButton.isEnabled = true
                    self.cancelButton.isEnabled = true
                }
            }
        }
    }
    
    private func uploadReferenceFile(_ fileURL: URL) async throws -> String {
        print("📤 uploadReferenceFile called")
        print("   File URL: \(fileURL)")
        
        // Get the file name and data
        let fileName = fileURL.lastPathComponent
        print("   File name: \(fileName)")
        
        // Start accessing security-scoped resource
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileData = try Data(contentsOf: fileURL)
        print("   File size: \(fileData.count) bytes")
        
        // Generate unique file name
        let uniqueFileName = "\(UUID().uuidString)_\(fileName)"
        let filePath = "reference_materials/\(uniqueFileName)"
        print("   Upload path: \(filePath)")
        
        let mimeType = getMimeType(for: fileURL)
        print("   MIME type: \(mimeType)")
        
        // Upload to Supabase Storage
        do {
            let uploadResult = try await supabase.storage
                .from("job-files")
                .upload(
                    path: filePath,
                    file: fileData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: mimeType,
                        upsert: false
                    )
                )
            print("✅ Upload successful: \(uploadResult)")
        } catch {
            print("❌ Upload failed: \(error)")
            throw error
        }
        
        // Get public URL
        let publicURL = try supabase.storage
            .from("job-files")
            .getPublicURL(path: filePath)
        
        print("🔗 Public URL: \(publicURL.absoluteString)")
        return publicURL.absoluteString
    }
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
    
    private func getCurrentUserId() async throws -> UUID? {
        // Get user ID from Supabase auth
        return supabase.auth.currentUser?.id
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Success Animation
    private func showSuccessAnimation() {
        // Show overlay
        UIView.animate(withDuration: 0.3, animations: {
            self.successOverlay.alpha = 1
        })
        
        // Animate card appearance with spring effect
        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.successAnimationView.alpha = 1
            self.successAnimationView.transform = .identity
        }) { _ in
            // Animate checkmark
            self.checkmarkView.animateCheckmark()
            
            // Add success haptic
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
            
            // Animate labels
            UIView.animate(withDuration: 0.4, delay: 0.3, options: .curveEaseIn, animations: {
                self.successLabel.alpha = 1
            })
            
            UIView.animate(withDuration: 0.4, delay: 0.4, options: .curveEaseIn, animations: {
                self.successSubLabel.alpha = 1
            }) { _ in
                // Auto dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismissSuccessAnimation()
                }
            }
        }
    }
    
    @objc private func dismissSuccessAnimation() {
        // Animate card disappearance
        UIView.animate(withDuration: 0.3, animations: {
            self.successAnimationView.alpha = 0
            self.successAnimationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.successOverlay.alpha = 0
        }) { _ in
            // Reset animation views
            self.successAnimationView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.successLabel.alpha = 0
            self.successSubLabel.alpha = 0
            self.checkmarkView.reset()
            
            // Reset buttons
            self.assignTaskButton.isEnabled = true
            self.cancelButton.isEnabled = true
            
            // Navigate to JobsViewController
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.navigateToJobsViewController()
            }
        }
    }
    
    private func navigateToJobsViewController() {
        // Find JobsViewController in navigation stack
        if let navController = self.navigationController {
            // Look for JobsViewController in the navigation stack
            for viewController in navController.viewControllers {
                if viewController is jobsViewController {
                    navController.popToViewController(viewController, animated: true)
                    return
                }
            }
            // If JobsViewController not found in stack, pop to root
            navController.popToRootViewController(animated: true)
        }
        // If presented modally, dismiss
        else if self.presentingViewController != nil {
            self.dismiss(animated: true) {
                // Post notification or use delegate to navigate to JobsViewController
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToJobsViewController"), object: nil)
            }
        }
    }

    // MARK: - Build Form
    private func buildForm() {
        formStack.addArrangedSubview(createSectionHeader("TASK INFORMATION"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Task Title", placeholder: "e.g., Dramatic Monologue"))
                $0.addArrangedSubview(createTextView(title: "Description", placeholder: "Describe what the actor needs..."))
                $0.addArrangedSubview(createDateField(title: "Due Date", placeholder: "dd/mm/yyyy", datePicker: dueDatePicker, textField: &dueDateTextField))
            }
        )

        formStack.addArrangedSubview(createSectionHeader("CHARACTER INFORMATION"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Character Name", placeholder: "e.g., Alex Carter"))
                $0.addArrangedSubview(createTextView(title: "Character Description", placeholder: "Describe the character..."))

                let horizontal = UIStackView()
                horizontal.axis = .horizontal
                horizontal.distribution = .fillEqually
                horizontal.spacing = 12

                horizontal.addArrangedSubview(createTextField(title: "Age", placeholder: "e.g., 28–35"))
                horizontal.addArrangedSubview(createDropdown(title: "Genre", placeholder: "Select", label: &genreLabel))

                $0.addArrangedSubview(horizontal)
                $0.addArrangedSubview(createTextView(title: "Personality Traits", placeholder: "e.g., confident, emotional"))
            }
        )

        formStack.addArrangedSubview(createSectionHeader("SCENE INFORMATION"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Scene Title", placeholder: "e.g., Opening Sequence"))
                $0.addArrangedSubview(createTextView(title: "Setting Description", placeholder: "Describe the setting"))
                $0.addArrangedSubview(createTextField(title: "Expected Duration", placeholder: "e.g., 3–5 minutes"))
                $0.addArrangedSubview(createUploadField(title: "Upload Reference Material", subtitle: "Video or script", fileNameLabel: &uploadedFileName))
                $0.addArrangedSubview(createDateField(title: "Application Deadline", placeholder: "dd/mm/yyyy", datePicker: deadlineDatePicker, textField: &applicationDeadlineTextField))
                $0.addArrangedSubview(createPaymentField(title: "Payment Amount/Day", placeholder: "5000/day"))
            }
        )
    }

    // MARK: Bottom Buttons
    private func setupBottomButtons() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemGroupedBackground
        
        // Add top border
        let topBorder = UIView()
        topBorder.backgroundColor = .separator
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(topBorder)

        let stack = UIStackView(arrangedSubviews: [cancelButton, assignTaskButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: container.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 0.5),
            
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 85),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Fetch Saved Casting Profile
    private func fetchSavedCastingProfile() async {
        guard let userId = supabase.auth.currentUser?.id else {
            print("❌ User not authenticated")
            return
        }
        
        do {
            let response = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            let castingProfile = try JSONDecoder().decode(CastingProfileRecord.self, from: response.data)
            await MainActor.run {
                self.savedCastingProfile = castingProfile
                self.updateFormWithSavedProfile(castingProfile)
            }
            print("✅ Loaded saved casting profile: \(castingProfile.companyName ?? "N/A")")
        } catch {
            print("ℹ️ No saved casting profile found or error loading: \(error)")
        }
    }
    
    // MARK: - Update Form with Saved Profile
    private func updateFormWithSavedProfile(_ profile: CastingProfileRecord) {
        // Add a profile summary card at the top of the form
        if let summaryCard = createProfileSummaryCard(profile) {
            formStack.insertArrangedSubview(summaryCard, at: 0)
            self.profileSummaryCard = summaryCard
            
            // Add a divider
            let divider = UIView()
            divider.backgroundColor = UIColor.systemGray5
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            formStack.insertArrangedSubview(divider, at: 1)
        }
    }
    
    // MARK: - Create Profile Summary Card
    private func createProfileSummaryCard(_ profile: CastingProfileRecord) -> UIView? {
        let card = UIView()
        card.backgroundColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 0.08)
        card.layer.cornerRadius = 12
        card.layer.borderColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 0.2).cgColor
        card.layer.borderWidth = 1
        
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
        checkIcon.tintColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
        checkIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        checkIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Profile Information"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
        
        headerStack.addArrangedSubview(checkIcon)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView()) // Spacer
        
        // Edit button
        let editButton = UIButton(type: .system)
        editButton.setTitle("Change", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        editButton.setTitleColor(UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1), for: .normal)
        editButton.addTarget(self, action: #selector(changeProfileTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(editButton)
        
        stack.addArrangedSubview(headerStack)
        
        // Profile details
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 8
        
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
        
        // Casting types / Specializations
        if !profile.castingTypes.isEmpty {
            let typesLabel = UILabel()
            typesLabel.text = "Specializations: \(profile.castingTypes.joined(separator: ", "))"
            typesLabel.font = UIFont.systemFont(ofSize: 13)
            typesLabel.textColor = .darkGray
            typesLabel.numberOfLines = 0
            detailsStack.addArrangedSubview(typesLabel)
        }
        
        stack.addArrangedSubview(detailsStack)
        
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        return card
    }
    
    // MARK: - Change Profile Action
    @objc private func changeProfileTapped() {
        // Check if ProfileInfoViewController is already in the navigation stack
        if let profileVC = navigationController?.viewControllers.first(where: { $0 is ProfileInfoViewController }) {
            // Pop back to it
            navigationController?.popToViewController(profileVC, animated: true)
        } else {
            // Push a new ProfileInfoViewController
            let profileVC = ProfileInfoViewController()
            navigationController?.pushViewController(profileVC, animated: true)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostJobViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
            if let url = url {
                // Copy to app's temporary directory to prevent file from being cleaned up
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = url.lastPathComponent
                let destinationURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileName)
                
                do {
                    // Copy the file
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    DispatchQueue.main.async {
                        self?.uploadedFileURL = destinationURL
                        self?.uploadedFileName?.text = fileName
                        self?.uploadedFileName?.textColor = .appPurple
                    }
                } catch {
                    print("❌ Error copying video file: \(error)")
                }
            } else {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { [weak self] url, error in
                    if let url = url {
                        // Copy to app's temporary directory
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let fileName = url.lastPathComponent
                        let destinationURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileName)
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            
                            DispatchQueue.main.async {
                                self?.uploadedFileURL = destinationURL
                                self?.uploadedFileName?.text = fileName
                                self?.uploadedFileName?.textColor = .appPurple
                            }
                        } catch {
                            print("❌ Error copying image file: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension PostJobViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Start accessing security-scoped resource for documents
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Copy to app's temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = url.lastPathComponent
        let destinationURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileName)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            uploadedFileURL = destinationURL
            uploadedFileName?.text = fileName
            uploadedFileName?.textColor = .appPurple
        } catch {
            print("❌ Error copying document file: \(error)")
        }
    }
}

// MARK: - UITextViewDelegate
extension PostJobViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear placeholder text
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Restore placeholder if empty
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if textView == taskDescriptionTextView {
                textView.text = "Describe what the actor needs..."
            } else if textView == characterDescriptionTextView {
                textView.text = "Describe the character..."
            } else if textView == personalityTraitsTextView {
                textView.text = "e.g., confident, emotional"
            } else if textView == settingDescriptionTextView {
                textView.text = "Describe the setting"
            }
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - Checkmark View
class CheckmarkView: UIView {
    private let circleLayer = CAShapeLayer()
    private let checkmarkLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }
    
    private func setupLayers() {
        circleLayer.removeFromSuperlayer()
        checkmarkLayer.removeFromSuperlayer()
        
        // Circle background
        let circlePath = UIBezierPath(ovalIn: bounds)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.appPurple.withAlphaComponent(0.1).cgColor
        circleLayer.strokeColor = UIColor.appPurple.cgColor
        circleLayer.lineWidth = 4
        circleLayer.strokeEnd = 0
        
        // Checkmark
        let checkmarkPath = UIBezierPath()
        let size = bounds.size
        checkmarkPath.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.5))
        checkmarkPath.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.67))
        checkmarkPath.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.33))
        
        checkmarkLayer.path = checkmarkPath.cgPath
        checkmarkLayer.fillColor = UIColor.clear.cgColor
        checkmarkLayer.strokeColor = UIColor.appPurple.cgColor
        checkmarkLayer.lineWidth = 5
        checkmarkLayer.lineCap = .round
        checkmarkLayer.lineJoin = .round
        checkmarkLayer.strokeEnd = 0
        
        layer.addSublayer(circleLayer)
        layer.addSublayer(checkmarkLayer)
    }
    
    func animateCheckmark() {
        // Animate circle drawing
        let circleAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circleAnimation.duration = 0.4
        circleAnimation.fromValue = 0
        circleAnimation.toValue = 1
        circleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        circleLayer.strokeEnd = 1
        circleLayer.add(circleAnimation, forKey: "circleAnimation")
        
        // Animate checkmark after circle
        let checkmarkAnimation = CABasicAnimation(keyPath: "strokeEnd")
        checkmarkAnimation.duration = 0.3
        checkmarkAnimation.fromValue = 0
        checkmarkAnimation.toValue = 1
        checkmarkAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        checkmarkAnimation.beginTime = CACurrentMediaTime() + 0.3
        
        checkmarkLayer.strokeEnd = 1
        checkmarkLayer.add(checkmarkAnimation, forKey: "checkmarkAnimation")
        
        // Add scale animation for extra polish
        UIView.animate(withDuration: 0.15, delay: 0.6, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.transform = .identity
            })
        }
    }
    
    func reset() {
        circleLayer.strokeEnd = 0
        checkmarkLayer.strokeEnd = 0
        transform = .identity
    }
}

// MARK: - Helpers
extension PostJobViewController {
    private func createSectionHeader(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = .secondaryLabel
        return lbl
    }

    private func createCardContainer(_ content: (UIStackView) -> Void) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        content(stack)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func createFieldTitle(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 17, weight: .regular)
        lbl.textColor = .label
        return lbl
    }

    private func createUnderline() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.systemGray4
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    private func createTextField(title: String, placeholder: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let titleLabel = createFieldTitle(title)

        let field = UITextField()
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 17)
        field.textColor = .label
        
        // Store reference based on title for form extraction
        if title == "Task Title" {
            taskTitleTextField = field
        } else if title == "Character Name" {
            characterNameTextField = field
        } else if title == "Age" {
            characterAgeTextField = field
        } else if title == "Scene Title" {
            sceneTitleTextField = field
        } else if title == "Expected Duration" {
            expectedDurationTextField = field
        }

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(field)
        container.addArrangedSubview(createUnderline())
        return container
    }

    private func createTextView(title: String, placeholder: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let titleLabel = createFieldTitle(title)

        let tv = UITextView()
        tv.text = placeholder
        tv.textColor = .placeholderText
        tv.font = .systemFont(ofSize: 17)
        tv.isScrollEnabled = false
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = self
        
        // Store reference based on title for form extraction
        if title == "Description" {
            taskDescriptionTextView = tv
        } else if title == "Character Description" {
            characterDescriptionTextView = tv
        } else if title == "Personality Traits" {
            personalityTraitsTextView = tv
        } else if title == "Setting Description" {
            settingDescriptionTextView = tv
        }

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(tv)
        container.addArrangedSubview(createUnderline())
        return container
    }

    private func createDateField(title: String, placeholder: String, datePicker: UIDatePicker, textField: inout UITextField?) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let titleLabel = createFieldTitle(title)

        let fieldStack = UIStackView()
        fieldStack.axis = .horizontal
        fieldStack.alignment = .center
        fieldStack.spacing = 8

        let field = UITextField()
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 17)
        field.textColor = .label
        field.inputView = datePicker
        
        // Create toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        field.inputAccessoryView = toolbar
        
        textField = field

        let icon = UIImageView(image: UIImage(systemName: "calendar"))
        icon.tintColor = .systemGray
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        fieldStack.addArrangedSubview(field)
        fieldStack.addArrangedSubview(icon)

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(fieldStack)
        container.addArrangedSubview(createUnderline())
        return container
    }

    private func createDropdown(title: String, placeholder: String, label: inout UILabel?) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let titleLabel = createFieldTitle(title)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8

        let genreLabel = UILabel()
        genreLabel.text = placeholder
        genreLabel.textColor = .placeholderText
        genreLabel.font = .systemFont(ofSize: 17)
        
        label = genreLabel

        let icon = UIImageView(image: UIImage(systemName: "chevron.down"))
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 13).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 13).isActive = true

        stack.addArrangedSubview(genreLabel)
        stack.addArrangedSubview(icon)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(genreDropdownTapped))
        stack.addGestureRecognizer(tapGesture)
        stack.isUserInteractionEnabled = true

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(stack)
        container.addArrangedSubview(createUnderline())
        return container
    }

    private func createUploadField(title: String, subtitle: String, fileNameLabel: inout UILabel?) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0

        let fieldStack = UIStackView()
        fieldStack.axis = .horizontal
        fieldStack.spacing = 12
        fieldStack.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: "square.and.arrow.up"))
        icon.tintColor = .systemBlue
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 22).isActive = true
        icon.contentMode = .scaleAspectFit

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        
        fileNameLabel = subtitleLabel

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 13).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 13).isActive = true

        fieldStack.addArrangedSubview(icon)
        fieldStack.addArrangedSubview(textStack)
        fieldStack.addArrangedSubview(chevron)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadFileTapped))
        fieldStack.addGestureRecognizer(tapGesture)
        fieldStack.isUserInteractionEnabled = true

        container.addArrangedSubview(fieldStack)
        container.addArrangedSubview(createUnderline())
        return container
    }

    private func createPaymentField(title: String, placeholder: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let titleLabel = createFieldTitle(title)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4

        let rupee = UILabel()
        rupee.text = "₹"
        rupee.font = .systemFont(ofSize: 17, weight: .medium)
        rupee.textColor = .secondaryLabel

        let field = UITextField()
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 17)
        field.textColor = .label
        field.keyboardType = .numberPad
        paymentAmountTextField = field
        
        // Create toolbar with Done button for number pad
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        field.inputAccessoryView = toolbar

        stack.addArrangedSubview(rupee)
        stack.addArrangedSubview(field)

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(stack)
        container.addArrangedSubview(createUnderline())

        return container
    }
}

// MARK: - Buttons
extension UIButton {
    static func createFilledButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = .appPurple
        btn.tintColor = .white
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return btn
    }

    static func createOutlineButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.tintColor = .appPurple
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.appPurple.cgColor
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return btn
    }
}
