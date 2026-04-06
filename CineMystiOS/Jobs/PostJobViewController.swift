import UIKit
import PhotosUI
import Supabase

class PostJobViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundGradient = CAGradientLayer()
    
    private let formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let nextButton = UIButton.createFilledButton(title: "Next: Add Task")
    private let postWithoutTaskButton = UIButton.createOutlineButton(title: "Post Without Task")
    private let cancelButton = UIButton.createOutlineButton(title: "Cancel")
    
    // MARK: - Form Fields
    private var projectTitleTextField: UITextField?
    private var characterNameTextField: UITextField?
    private var characterDescriptionTextView: UITextView?
    private var ageTextField: UITextField?
    private var paymentAmountTextField: UITextField?
    private var applicationDeadlineTextField: UITextField?
    private var genreLabel: UILabel?
    private var genderLabel: UILabel?
    
    private var selectedDeadlineDate: Date?
    private var selectedGenre: String?
    private var selectedGender: String?
    
    private let statusLabelView = UILabel()
    private var currentStatus: String = "pending"
    private var hasProfile: Bool = false
    
    private let deadlineDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.minimumDate = Date()
        return picker
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupTheme()
        setupNavBar()
        setupScrollView()
        buildForm()
        setupBottomButtons()
        setupKeyboardDismissal()
        fetchStatus()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    private func setupTheme() {
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

    private func setupNavBar() {
        title = "Post a job"
        navigationController?.navigationBar.tintColor = CineMystTheme.brandPlum
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -180)
        ])
    }

    private func buildForm() {
        // Verification Shortcut Section
        formStack.addArrangedSubview(createSectionHeader("VERIFICATION PROFILE"))
        let profileCard = createCardContainer { stack in
            let hStack = UIStackView()
            hStack.axis = .horizontal
            hStack.spacing = 12
            hStack.alignment = .center
            
            let icon = UIImageView(image: UIImage(systemName: "person.badge.shield.fill"))
            icon.tintColor = CineMystTheme.brandPlum
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
            
            let vStack = UIStackView()
            vStack.axis = .vertical
            vStack.spacing = 2
            
            let titleLabel = UILabel()
            titleLabel.text = "Business Profile"
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            
            statusLabelView.text = "Loading status..."
            statusLabelView.font = UIFont.systemFont(ofSize: 13)
            statusLabelView.textColor = .secondaryLabel
            
            vStack.addArrangedSubview(titleLabel)
            vStack.addArrangedSubview(statusLabelView)
            
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .systemGray3
            arrow.contentMode = .scaleAspectFit
            arrow.widthAnchor.constraint(equalToConstant: 14).isActive = true
            
            hStack.addArrangedSubview(icon)
            hStack.addArrangedSubview(vStack)
            hStack.addArrangedSubview(UIView()) // spacer
            hStack.addArrangedSubview(arrow)
            
            stack.addArrangedSubview(hStack)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
            stack.isUserInteractionEnabled = true
            stack.addGestureRecognizer(tap)
        }
        formStack.addArrangedSubview(profileCard)

        formStack.addArrangedSubview(createSectionHeader("PROJECT INFORMATION"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Project Title (Serial/Movie/Show)", placeholder: "e.g., The Midnight Echo", textField: &projectTitleTextField))
                $0.addArrangedSubview(createTextField(title: "Payment Amount/Day (₹)", placeholder: "5000", textField: &paymentAmountTextField))
                $0.addArrangedSubview(createDateField(title: "Application Deadline", placeholder: "dd/mm/yyyy", datePicker: deadlineDatePicker, textField: &applicationDeadlineTextField))
            }
        )

        formStack.addArrangedSubview(createSectionHeader("ROLE INFORMATION"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Character Name", placeholder: "e.g., Alex Carter", textField: &characterNameTextField))
                $0.addArrangedSubview(createTextView(title: "Character Description", placeholder: "Describe the character...", textView: &characterDescriptionTextView))

                let hStack = UIStackView()
                hStack.axis = .horizontal
                hStack.distribution = .fillEqually
                hStack.spacing = 12
                
                hStack.addArrangedSubview(createDropdown(title: "Gender", placeholder: "Select", label: &genderLabel, action: #selector(genderTapped)))
                hStack.addArrangedSubview(createTextField(title: "Age Range", placeholder: "e.g., 20-30", textField: &ageTextField))
                
                $0.addArrangedSubview(hStack)
                $0.addArrangedSubview(createDropdown(title: "Genre", placeholder: "Select", label: &genreLabel, action: #selector(genreTapped)))
            }
        )
    }

    private func setupBottomButtons() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemGroupedBackground
        
        let stack = UIStackView(arrangedSubviews: [nextButton, postWithoutTaskButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 180),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        postWithoutTaskButton.addTarget(self, action: #selector(postWithoutTaskTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func genderTapped() {
        let genders = ["Male", "Female", "Non-Binary", "Any"]
        showPicker(title: "Select Gender", options: genders) { choice in
            self.selectedGender = choice
            self.genderLabel?.text = choice
            self.genderLabel?.textColor = .label
        }
    }

    @objc private func genreTapped() {
        let genres = ["Drama", "Comedy", "Action", "Horror", "Sci-Fi", "Romance", "Thriller"]
        showPicker(title: "Select Genre", options: genres) { choice in
            self.selectedGenre = choice
            self.genreLabel?.text = choice
            self.genreLabel?.textColor = .label
        }
    }

    private func showPicker(title: String, options: [String], completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for option in options {
            alert.addAction(UIAlertAction(title: option, style: .default, handler: { _ in completion(option) }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func profileTapped() {
        let vc = ProfileInfoViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func fetchStatus() {
        Task {
            do {
                guard let userId = supabase.auth.currentUser?.id else { return }
                let casting: CastingProfileRecord = try await supabase
                    .from("casting_profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.currentStatus = casting.status ?? "pending"
                    self.hasProfile = true
                    self.updateStatusUI()
                }
            } catch {
                await MainActor.run {
                    self.statusLabelView.text = "Profile not submitted"
                    self.statusLabelView.textColor = .systemOrange
                }
            }
        }
    }

    private func updateStatusUI() {
        if currentStatus == "verified" {
            statusLabelView.text = "Verified Account ✅"
            statusLabelView.textColor = .systemGreen
        } else {
            statusLabelView.text = "Verification Pending ⏳"
            statusLabelView.textColor = .systemOrange
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextTapped() {
        guard validateInputs() else { return }
        let (job, task) = prepareData()
        let vc = PostTaskViewController()
        vc.job = job
        vc.taskToPost = task
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func postWithoutTaskTapped() {
        guard validateInputs() else { return }
        let (job, task) = prepareData()
        
        postWithoutTaskButton.isEnabled = false
        
        Task {
            do {
                let savedJob = try await JobsService.shared.createJob(job)
                
                let taskWithJobId = JobTask(
                    id: UUID(),
                    jobId: savedJob.id,
                    taskTitle: nil,
                    taskDescription: nil,
                    characterName: task.characterName,
                    characterDescription: task.characterDescription,
                    characterAgeRange: task.characterAgeRange, // Added missing arg
                    characterGender: task.characterGender,      // Added missing arg
                    genre: task.genre,
                    personalityTraits: task.personalityTraits,
                    sceneTitle: nil,
                    sceneSetting: nil,
                    expectedDuration: nil,
                    referenceMaterialUrl: nil,
                    requirements: nil,
                    dueDate: nil,
                    createdAt: Date()
                )
                
                _ = try await JobsService.shared.createTask(taskWithJobId)
                
                await MainActor.run {
                    self.showSuccess()
                }
            } catch {
                await MainActor.run {
                    self.postWithoutTaskButton.isEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func validateInputs() -> Bool {
        if (projectTitleTextField?.text?.isEmpty ?? true) {
            showAlert(title: "Required", message: "Project Title is required")
            return false
        }
        return true
    }

    private func prepareData() -> (Job, JobTask) {
        let rateStr = paymentAmountTextField?.text ?? "0"
        let rate = Int(rateStr) ?? 0
        let userId = supabase.auth.currentUser?.id
        
        let job = Job(
            id: UUID(),
            directorId: userId,
            title: projectTitleTextField?.text,
            companyName: "CineMyst Production",
            location: "Mumbai",
            ratePerDay: rate,
            jobType: selectedGenre,
            description: characterDescriptionTextView?.text,
            requirements: nil,
            status: .active,
            applicationDeadline: selectedDeadlineDate,
            referenceMaterialUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let task = JobTask(
            id: UUID(),
            jobId: nil,
            taskTitle: nil,
            taskDescription: nil,
            characterName: characterNameTextField?.text,
            characterDescription: (characterDescriptionTextView?.text == "Describe the character...") ? nil : characterDescriptionTextView?.text,
            characterAgeRange: ageTextField?.text,
            characterGender: selectedGender,
            genre: selectedGenre,
            personalityTraits: nil,
            sceneTitle: nil,
            sceneSetting: nil,
            expectedDuration: nil,
            referenceMaterialUrl: nil,
            requirements: nil,
            dueDate: nil,
            createdAt: Date()
        )
        
        return (job, task)
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "Success", message: "Job posted successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - UI Helpers
    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .systemGray
        return label
    }

    private func createCardContainer(configuration: (UIStackView) -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.05
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 12

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        configuration(stack)
        return container
    }

    private func createTextField(title: String, placeholder: String, textField: inout UITextField?) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(tf)
        stack.addArrangedSubview(line)
        
        textField = tf
        return stack
    }

    private func createTextView(title: String, placeholder: String, textView: inout UITextView?) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.text = placeholder
        tv.textColor = .placeholderText
        tv.isScrollEnabled = false
        tv.delegate = self
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(tv)
        stack.addArrangedSubview(line)
        
        textView = tv
        return stack
    }

    private func createDateField(title: String, placeholder: String, datePicker: UIDatePicker, textField: inout UITextField?) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.inputView = datePicker
        
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(tf)
        stack.addArrangedSubview(line)
        
        textField = tf
        
        datePicker.addTarget(self, action: #selector(deadlineDateChanged(_:)), for: .valueChanged)
        
        return stack
    }

    @objc private func deadlineDateChanged(_ picker: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        applicationDeadlineTextField?.text = formatter.string(from: picker.date)
        selectedDeadlineDate = picker.date
    }

    private func createDropdown(title: String, placeholder: String, label: inout UILabel?, action: Selector) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        
        let dropdown = UIView()
        dropdown.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        dropdown.addGestureRecognizer(tap)
        
        let valLabel = UILabel()
        valLabel.text = placeholder
        valLabel.font = .systemFont(ofSize: 16)
        valLabel.textColor = .placeholderText
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .systemGray3
        chevron.contentMode = .scaleAspectFit
        
        dropdown.addSubview(valLabel)
        dropdown.addSubview(chevron)
        valLabel.translatesAutoresizingMaskIntoConstraints = false
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            valLabel.leadingAnchor.constraint(equalTo: dropdown.leadingAnchor),
            valLabel.centerYAnchor.constraint(equalTo: dropdown.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: dropdown.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: dropdown.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            dropdown.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(dropdown)
        stack.addArrangedSubview(line)
        
        label = valLabel
        return stack
    }
}

extension PostJobViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe..."
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - Buttons extension if not defined globally
// Note: Assuming UIButton extension for createFilledButton and createOutlineButton exists elsewhere,
// but adding it here just in case or using the one that was in the file.
extension UIButton {
    static func createFilledButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = CineMystTheme.brandPlum
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return btn
    }

    static func createOutlineButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = .clear
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = CineMystTheme.brandPlum.cgColor
        btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return btn
    }
}
