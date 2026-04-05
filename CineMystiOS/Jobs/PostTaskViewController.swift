import UIKit
import PhotosUI
import Supabase

class PostTaskViewController: UIViewController {

    // MARK: - Properties
    var job: Job?
    var taskToPost: JobTask?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundGradient = CAGradientLayer()
    
    private let formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let postButton = UIButton.createFilledButton(title: "Post Job with Task")
    private let backButton = UIButton.createOutlineButton(title: "Back")
    
    // MARK: - Form Fields
    private var taskTitleTextField: UITextField?
    private var taskDescriptionTextView: UITextView?
    private var sceneTitleTextField: UITextField?
    private var settingDescriptionTextView: UITextView?
    private var expectedDurationTextField: UITextField?
    private var dueDateTextField: UITextField?
    private var uploadedFileName: UILabel?
    
    private var selectedDueDate: Date?
    private var uploadedFileURL: URL?
    
    private let dueDatePicker: UIDatePicker = {
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
        title = "Task Details"
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
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100)
        ])
    }

    private func buildForm() {
        formStack.addArrangedSubview(createSectionHeader("AUDITION TASK"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Task Title", placeholder: "e.g., Dramatic Monologue", textField: &taskTitleTextField))
                $0.addArrangedSubview(createTextView(title: "Task Description", placeholder: "Describe what the actor needs to do...", textView: &taskDescriptionTextView))
                $0.addArrangedSubview(createDateField(title: "Due Date", placeholder: "dd/mm/yyyy", datePicker: dueDatePicker, textField: &dueDateTextField))
            }
        )

        formStack.addArrangedSubview(createSectionHeader("SCENE DETAILS"))
        formStack.addArrangedSubview(
            createCardContainer {
                $0.addArrangedSubview(createTextField(title: "Scene Title", placeholder: "e.g., Opening Sequence", textField: &sceneTitleTextField))
                $0.addArrangedSubview(createTextView(title: "Setting Description", placeholder: "Describe the setting", textView: &settingDescriptionTextView))
                $0.addArrangedSubview(createTextField(title: "Expected Duration", placeholder: "e.g., 3–5 minutes", textField: &expectedDurationTextField))
                $0.addArrangedSubview(createUploadField(title: "Upload Reference Material", subtitle: "Video or script", fileNameLabel: &uploadedFileName))
            }
        )
    }

    private func setupBottomButtons() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemGroupedBackground
        
        let stack = UIStackView(arrangedSubviews: [backButton, postButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 85),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func postTapped() {
        guard let job = job else { return }
        
        // Show loading or disable button
        postButton.isEnabled = false
        
        Task {
            do {
                // 1. Create Job
                let savedJob = try await JobsService.shared.createJob(job)
                
                // 2. Upload reference if any
                var refUrl: String? = nil
                if let url = uploadedFileURL {
                    refUrl = try await uploadReferenceFile(url)
                }
                
                // 3. Create Task
                let finalTask = JobTask(
                    id: UUID(),
                    jobId: savedJob.id,
                    taskTitle: taskTitleTextField?.text,
                    taskDescription: taskDescriptionTextView?.text,
                    characterName: taskToPost?.characterName,
                    characterDescription: taskToPost?.characterDescription,
                    characterAgeRange: taskToPost?.characterAgeRange,
                    characterGender: taskToPost?.characterGender,
                    genre: taskToPost?.genre,
                    personalityTraits: taskToPost?.personalityTraits,
                    sceneTitle: sceneTitleTextField?.text,
                    sceneSetting: settingDescriptionTextView?.text,
                    expectedDuration: expectedDurationTextField?.text,
                    referenceMaterialUrl: refUrl,
                    requirements: nil,
                    dueDate: selectedDueDate,
                    createdAt: Date()
                )
                
                _ = try await JobsService.shared.createTask(finalTask)
                
                await MainActor.run {
                    self.showSuccess()
                }
            } catch {
                await MainActor.run {
                    self.postButton.isEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "Success", message: "Job and Task posted successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Helpers (Copied from PostJobViewController and modified)
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
        
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        return stack
    }
    
    @objc private func dateChanged(_ picker: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dueDateTextField?.text = formatter.string(from: picker.date)
        selectedDueDate = picker.date
    }

    private func createUploadField(title: String, subtitle: String, fileNameLabel: inout UILabel?) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        
        let container = UIView()
        container.backgroundColor = CineMystTheme.pinkPale.withAlphaComponent(0.3)
        container.layer.cornerRadius = 12
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let icon = UIImageView(image: UIImage(systemName: "plus.circle.fill"))
        icon.tintColor = CineMystTheme.brandPlum
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let sub = UILabel()
        sub.text = subtitle
        sub.font = .systemFont(ofSize: 14)
        sub.textColor = .systemGray
        sub.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(icon)
        container.addSubview(sub)
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            
            sub.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            sub.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(uploadTapped))
        container.addGestureRecognizer(tap)
        
        let fileLabel = UILabel()
        fileLabel.font = .systemFont(ofSize: 12)
        fileLabel.textColor = .systemGreen
        fileLabel.text = ""
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(container)
        stack.addArrangedSubview(fileLabel)
        
        fileNameLabel = fileLabel
        return stack
    }

    @objc private func uploadTapped() {
        let picker = PHPickerViewController(configuration: PHPickerConfiguration())
        picker.delegate = self
        present(picker, animated: true)
    }

    private func uploadReferenceFile(_ fileURL: URL) async throws -> String {
        let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
        let fileData = try Data(contentsOf: fileURL)
        return try await JobsService.shared.uploadFile(fileData: fileData, fileName: fileName, bucket: "job-files", folder: "reference_materials")
    }
}

extension PostTaskViewController: UITextViewDelegate {
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

extension PostTaskViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { url, error in
            if let url = url {
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: localURL)
                DispatchQueue.main.async {
                    self.uploadedFileURL = localURL
                    self.uploadedFileName?.text = url.lastPathComponent
                }
            }
        }
    }
}
