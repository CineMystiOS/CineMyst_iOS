//
//  RoleDetailsViewController.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class RoleDetailsViewController: UIViewController {
    
    private let headerView = OnboardingProgressHeader()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    var coordinator: OnboardingCoordinator?
    
    // Form data storage
    private var selectedEmploymentStatus: String?
    private var selectedPrimaryRoles: Set<String> = []
    private var selectedCareerStage: String?
    private var selectedExperience: String?
    private var travelWillingSwitch: UISwitch?
    
    private var specificRoleTextField: UITextField?
    private var companyNameTextField: UITextField?
    private var selectedCastingTypes: Set<String> = []
    private var castingRadiusTextField: UITextField?
    
    // Pickers for dropdowns
    private var employmentPicker: UIPickerView?
    private var careerStagePicker: UIPickerView?
    private var experiencePicker: UIPickerView?
    
    private var employmentTextField: UITextField?
    private var careerStageTextField: UITextField?
    private var experienceTextField: UITextField?
    
    // Dropdown options
    private let employmentOptionsArtist = ["Freelancer", "Agency-Represented", "In-House / Full-time", "Project-based", "Student / Recent Graduate"]
    private let employmentOptionsCasting = ["Freelancer", "Agency-Represented", "In-House / Full-time", "Project-based"]
    private let careerStageOptions = ["Beginner", "Intermediate", "Pro", "Student"]
    private let experienceOptions = ["0", "1-2", "3-5", "5+"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        let title = coordinator?.profileData.role == .artist ?
            "Tell us about yourself" :
            "Tell us about your work"
        headerView.configure(title: title, currentStep: 3)
        
        setupScrollView()
        setupBackButton()
        navigationItem.hidesBackButton = false
        
        if coordinator?.profileData.role == .artist {
            setupArtistForm()
        } else {
            setupCastingProfessionalForm()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func setupBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupScrollView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
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
    
    private func setupArtistForm() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Employment Status (Dropdown)
        stackView.addArrangedSubview(createLabel(text: "Employment Status *", fontSize: 16, weight: .semibold))
        let employmentField = createDropdownField(placeholder: "Select employment status", options: employmentOptionsArtist, tag: 0)
        employmentTextField = employmentField
        stackView.addArrangedSubview(employmentField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Primary Roles (Multi-select chips)
        stackView.addArrangedSubview(createLabel(text: "Primary Roles *", fontSize: 16, weight: .semibold))
        stackView.addArrangedSubview(createLabel(text: "Select all that apply", fontSize: 13, weight: .regular, color: .secondaryLabel))
        let rolesChipView = createChipSelectionView(options: ["Actor", "Dancer", "Singer", "Model", "Voice Artist"], isMultiSelect: true, tag: 1)
        stackView.addArrangedSubview(rolesChipView)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Career Stage (Dropdown)
        stackView.addArrangedSubview(createLabel(text: "Career Stage *", fontSize: 16, weight: .semibold))
        let careerField = createDropdownField(placeholder: "Select career stage", options: careerStageOptions, tag: 1)
        careerStageTextField = careerField
        stackView.addArrangedSubview(careerField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Experience (Dropdown)
        stackView.addArrangedSubview(createLabel(text: "Years of Experience *", fontSize: 16, weight: .semibold))
        let expField = createDropdownField(placeholder: "Select experience", options: experienceOptions.map { $0 + " years" }, tag: 2)
        experienceTextField = expField
        stackView.addArrangedSubview(expField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Travel Willingness
        let travelSwitch = UISwitch()
        travelSwitch.isOn = false
        self.travelWillingSwitch = travelSwitch
        let travelContainer = createSwitchRow(label: "Willing to travel for work", switchControl: travelSwitch)
        stackView.addArrangedSubview(travelContainer)
        
        stackView.addArrangedSubview(createSpacer(height: 24))
        
        // Next Button
        let nextButton = createNextButton()
        stackView.addArrangedSubview(nextButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupCastingProfessionalForm() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Employment Status (Dropdown)
        stackView.addArrangedSubview(createLabel(text: "Employment Status *", fontSize: 16, weight: .semibold))
        let employmentField = createDropdownField(placeholder: "Select employment status", options: employmentOptionsCasting, tag: 0)
        employmentTextField = employmentField
        stackView.addArrangedSubview(employmentField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Specific Role
        stackView.addArrangedSubview(createLabel(text: "Your Role *", fontSize: 16, weight: .semibold))
        let roleTextField = createTextField(placeholder: "e.g., Casting Director, Assistant, Producer")
        self.specificRoleTextField = roleTextField
        stackView.addArrangedSubview(roleTextField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Company Name
        stackView.addArrangedSubview(createLabel(text: "Company / Production Name *", fontSize: 16, weight: .semibold))
        let companyTextField = createTextField(placeholder: "Enter company or production house name")
        self.companyNameTextField = companyTextField
        stackView.addArrangedSubview(companyTextField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Casting Types (Multi-select chips)
        stackView.addArrangedSubview(createLabel(text: "Casting Types *", fontSize: 16, weight: .semibold))
        stackView.addArrangedSubview(createLabel(text: "Select all that apply", fontSize: 13, weight: .regular, color: .secondaryLabel))
        let castingChipView = createChipSelectionView(options: ["Film", "TV", "Ads", "Theater", "Web Series"], isMultiSelect: true, tag: 2)
        stackView.addArrangedSubview(castingChipView)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Casting Radius
        stackView.addArrangedSubview(createLabel(text: "Casting Radius (km)", fontSize: 16, weight: .semibold))
        let radiusTextField = createTextField(placeholder: "e.g., 50")
        radiusTextField.keyboardType = .numberPad
        self.castingRadiusTextField = radiusTextField
        stackView.addArrangedSubview(radiusTextField)
        
        stackView.addArrangedSubview(createSpacer(height: 24))
        
        // Next Button
        let nextButton = createNextButton()
        stackView.addArrangedSubview(nextButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Helper Methods
    private func createLabel(text: String, fontSize: CGFloat, weight: UIFont.Weight, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        return label
    }
    
    private func createSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }
    
    private func createDropdownField(placeholder: String, options: [String], tag: Int) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 17)
        textField.backgroundColor = .tertiarySystemGroupedBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.tag = tag
        
        // Add left padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        
        // Add chevron icon with padding
        let chevronContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronView.tintColor = .secondaryLabel
        chevronView.contentMode = .scaleAspectFit
        chevronView.frame = CGRect(x: 8, y: 15, width: 20, height: 20)
        chevronContainer.addSubview(chevronView)
        textField.rightView = chevronContainer
        textField.rightViewMode = .always
        
        // Setup picker
        let picker = UIPickerView()
        picker.tag = tag
        picker.delegate = self
        picker.dataSource = self
        textField.inputView = picker
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickerTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        return textField
    }
    
    @objc private func donePickerTapped() {
        view.endEditing(true)
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 17)
        textField.backgroundColor = .tertiarySystemGroupedBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Add padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.rightViewMode = .always
        
        return textField
    }
    
    private func createChipSelectionView(options: [String], isMultiSelect: Bool, tag: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.tag = tag
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        var currentRow: UIStackView?
        for (index, option) in options.enumerated() {
            if index % 2 == 0 {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = 12
                currentRow?.distribution = .fillEqually
                stackView.addArrangedSubview(currentRow!)
            }
            
            let chipButton = createChipButton(title: option, tag: tag)
            currentRow?.addArrangedSubview(chipButton)
        }
        
        // If odd number of items, add spacer to last row
        if options.count % 2 != 0 {
            let spacer = UIView()
            currentRow?.addArrangedSubview(spacer)
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createChipButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .tertiarySystemGroupedBackground
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.separator.cgColor
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.tag = tag
        button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func chipTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        let isSelected = sender.backgroundColor != .tertiarySystemGroupedBackground
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.2) {
            if isSelected {
                // Deselect
                sender.backgroundColor = .tertiarySystemGroupedBackground
                sender.setTitleColor(.label, for: .normal)
                sender.layer.borderColor = UIColor.separator.cgColor
                
                if sender.tag == 1 {
                    self.selectedPrimaryRoles.remove(title)
                } else if sender.tag == 2 {
                    self.selectedCastingTypes.remove(title)
                }
            } else {
                // Select
                sender.backgroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
                sender.setTitleColor(.white, for: .normal)
                sender.layer.borderColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0).cgColor
                
                if sender.tag == 1 {
                    self.selectedPrimaryRoles.insert(title)
                } else if sender.tag == 2 {
                    self.selectedCastingTypes.insert(title)
                }
            }
        }
    }
    
    private func createSwitchRow(label: String, switchControl: UISwitch) -> UIView {
        let container = UIView()
        container.backgroundColor = .tertiarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.separator.cgColor
        
        let labelView = createLabel(text: label, fontSize: 17, weight: .regular)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelView)
        container.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelView.trailingAnchor.constraint(equalTo: switchControl.leadingAnchor, constant: -12),
            switchControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        return container
    }
    
    private func createNextButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.backgroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        // Add shadow for depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }
    
    @objc private func nextTapped() {
        guard validateForm() else {
            return
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        saveFormData()
        
        let locationVC = LocationViewController()
        locationVC.coordinator = coordinator
        navigationController?.pushViewController(locationVC, animated: true)
    }
    
    private func validateForm() -> Bool {
        guard selectedEmploymentStatus != nil else {
            showAlert(message: "Please select your employment status")
            return false
        }
        
        if coordinator?.profileData.role == .artist {
            if selectedPrimaryRoles.isEmpty {
                showAlert(message: "Please select at least one primary role")
                return false
            }
            if selectedCareerStage == nil {
                showAlert(message: "Please select your career stage")
                return false
            }
            if selectedExperience == nil {
                showAlert(message: "Please select your years of experience")
                return false
            }
            return true
        } else {
            if specificRoleTextField?.text?.trimmingCharacters(in: .whitespaces).isEmpty != false {
                showAlert(message: "Please enter your specific role")
                return false
            }
            if companyNameTextField?.text?.trimmingCharacters(in: .whitespaces).isEmpty != false {
                showAlert(message: "Please enter your company or production name")
                return false
            }
            if selectedCastingTypes.isEmpty {
                showAlert(message: "Please select at least one casting type")
                return false
            }
            return true
        }
    }
    
    private func saveFormData() {
        coordinator?.profileData.employmentStatus = selectedEmploymentStatus
        
        if coordinator?.profileData.role == .artist {
            coordinator?.profileData.primaryRoles = selectedPrimaryRoles
            coordinator?.profileData.careerStage = selectedCareerStage
            coordinator?.profileData.experienceYears = selectedExperience
            coordinator?.profileData.travelWilling = travelWillingSwitch?.isOn ?? false
        } else {
            coordinator?.profileData.specificRole = specificRoleTextField?.text
            coordinator?.profileData.companyName = companyNameTextField?.text
            coordinator?.profileData.castingTypes = selectedCastingTypes
            coordinator?.profileData.castingRadius = Int(castingRadiusTextField?.text ?? "0")
        }
        
        coordinator?.nextStep()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Required Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView Delegate & DataSource
extension RoleDetailsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // Employment
            return coordinator?.profileData.role == .artist ? employmentOptionsArtist.count : employmentOptionsCasting.count
        case 1: // Career Stage
            return careerStageOptions.count
        case 2: // Experience
            return experienceOptions.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return coordinator?.profileData.role == .artist ? employmentOptionsArtist[row] : employmentOptionsCasting[row]
        case 1:
            return careerStageOptions[row]
        case 2:
            return experienceOptions[row] + " years"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0: // Employment
            let options = coordinator?.profileData.role == .artist ? employmentOptionsArtist : employmentOptionsCasting
            selectedEmploymentStatus = options[row]
            employmentTextField?.text = options[row]
        case 1: // Career Stage
            selectedCareerStage = careerStageOptions[row]
            careerStageTextField?.text = careerStageOptions[row]
        case 2: // Experience
            selectedExperience = experienceOptions[row]
            experienceTextField?.text = experienceOptions[row] + " years"
        default:
            break
        }
    }
}
