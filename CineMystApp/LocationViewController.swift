//
//  LocationViewController.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class LocationViewController: UIViewController {
    private let headerView = OnboardingProgressHeader()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var stateTextField: UITextField!
    private var postalCodeTextField: UITextField!
    private var cityTextField: UITextField!
    private var districtLabel: UILabel!
    
    private var selectedState: String?
    private var verifiedPincode: PincodeData?
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    var coordinator: OnboardingCoordinator?
    
    // Indian states and union territories
    private let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
        "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand",
        "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur",
        "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab",
        "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
        "Uttar Pradesh", "Uttarakhand", "West Bengal",
        "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
        "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
    ].sorted()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        headerView.configure(title: "Where are you based?", currentStep: 4)
        setupBackButton()
        navigationItem.hidesBackButton = false
        
        setupUI()
        
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
    
    private func setupUI() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // State Dropdown
        stackView.addArrangedSubview(createLabel(text: "State / Union Territory *", fontSize: 16, weight: .semibold))
        stateTextField = createDropdownField(placeholder: "Select your state")
        stackView.addArrangedSubview(stateTextField)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Postal Code with verification
        stackView.addArrangedSubview(createLabel(text: "Postal Code (Pincode) *", fontSize: 16, weight: .semibold))
        let pincodeContainer = createPincodeField()
        stackView.addArrangedSubview(pincodeContainer)
        
        // District info (shown after verification)
        districtLabel = createLabel(text: "", fontSize: 14, weight: .regular, color: .secondaryLabel)
        districtLabel.isHidden = true
        stackView.addArrangedSubview(districtLabel)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // City/Area
        stackView.addArrangedSubview(createLabel(text: "City / Area *", fontSize: 16, weight: .semibold))
        cityTextField = createTextField(placeholder: "Enter your city or locality")
        stackView.addArrangedSubview(cityTextField)
        
        stackView.addArrangedSubview(createSpacer(height: 24))
        
        // Info text
        let infoLabel = createLabel(text: "We use this to show you relevant nearby opportunities", fontSize: 13, weight: .regular, color: .secondaryLabel)
        infoLabel.numberOfLines = 0
        stackView.addArrangedSubview(infoLabel)
        
        stackView.addArrangedSubview(createSpacer(height: 8))
        
        // Next Button
        let nextButton = createNextButton()
        stackView.addArrangedSubview(nextButton)
        
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
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
    
    private func createDropdownField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 17)
        textField.backgroundColor = .tertiarySystemGroupedBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Left padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        
        // Chevron
        let chevronContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronView.tintColor = .secondaryLabel
        chevronView.contentMode = .scaleAspectFit
        chevronView.frame = CGRect(x: 8, y: 15, width: 20, height: 20)
        chevronContainer.addSubview(chevronView)
        textField.rightView = chevronContainer
        textField.rightViewMode = .always
        
        // Picker
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        textField.inputView = picker
        
        // Toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        return textField
    }
    
    private func createPincodeField() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        postalCodeTextField = UITextField()
        postalCodeTextField.placeholder = "Enter 6-digit pincode"
        postalCodeTextField.font = .systemFont(ofSize: 17)
        postalCodeTextField.backgroundColor = .tertiarySystemGroupedBackground
        postalCodeTextField.layer.cornerRadius = 10
        postalCodeTextField.layer.borderWidth = 1
        postalCodeTextField.layer.borderColor = UIColor.separator.cgColor
        postalCodeTextField.keyboardType = .numberPad
        postalCodeTextField.delegate = self
        postalCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Left padding
        postalCodeTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        postalCodeTextField.leftViewMode = .always
        
        // Loading indicator on right
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        container.addSubview(postalCodeTextField)
        container.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            postalCodeTextField.topAnchor.constraint(equalTo: container.topAnchor),
            postalCodeTextField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            postalCodeTextField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            postalCodeTextField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            postalCodeTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.trailingAnchor.constraint(equalTo: postalCodeTextField.trailingAnchor, constant: -16),
            loadingIndicator.centerYAnchor.constraint(equalTo: postalCodeTextField.centerYAnchor)
        ])
        
        return container
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
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.rightViewMode = .always
        
        return textField
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
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }
    
    // MARK: - Pincode Verification
    private func verifyPincode(_ pincode: String) {
        guard pincode.count == 6, pincode.allSatisfy({ $0.isNumber }) else {
            resetPincodeVerification()
            return
        }
        
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let pincodeData = try await fetchPincodeData(pincode)
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.handlePincodeSuccess(pincodeData)
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.handlePincodeError()
                }
            }
        }
    }
    
    private func fetchPincodeData(_ pincode: String) async throws -> PincodeData {
        let urlString = "https://api.postalpincode.in/pincode/\(pincode)"
        guard let url = URL(string: urlString) else {
            throw PincodeError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([PincodeAPIResponse].self, from: data)
        
        guard let firstResult = response.first,
              firstResult.status == "Success",
              let postOffice = firstResult.postOffice?.first else {
            throw PincodeError.notFound
        }
        
        return PincodeData(
            pincode: pincode,
            district: postOffice.district,
            state: postOffice.state,
            postOffice: postOffice.name
        )
    }
    
    private func handlePincodeSuccess(_ data: PincodeData) {
        verifiedPincode = data
        
        // Update state field if matches
        if indianStates.contains(data.state) {
            selectedState = data.state
            stateTextField.text = data.state
        }
        
        // Show district info
        districtLabel.text = "✓ \(data.district) District, \(data.state)"
        districtLabel.textColor = .systemGreen
        districtLabel.isHidden = false
        
        // Update border to green
        postalCodeTextField.layer.borderColor = UIColor.systemGreen.cgColor
        postalCodeTextField.layer.borderWidth = 1.5
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-populate city if empty
        if cityTextField.text?.isEmpty ?? true {
            cityTextField.text = data.postOffice
        }
    }
    
    private func handlePincodeError() {
        verifiedPincode = nil
        districtLabel.text = "✗ Invalid pincode"
        districtLabel.textColor = .systemRed
        districtLabel.isHidden = false
        
        postalCodeTextField.layer.borderColor = UIColor.systemRed.cgColor
        postalCodeTextField.layer.borderWidth = 1.5
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    private func resetPincodeVerification() {
        verifiedPincode = nil
        districtLabel.isHidden = true
        postalCodeTextField.layer.borderColor = UIColor.separator.cgColor
        postalCodeTextField.layer.borderWidth = 1
    }
    
    @objc private func nextTapped() {
        guard validateForm() else {
            return
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        saveFormData()
        navigateToProfilePicture()
    }
    
    private func validateForm() -> Bool {
        guard selectedState != nil else {
            showAlert(message: "Please select your state")
            return false
        }
        
        guard let pincode = postalCodeTextField.text,
              pincode.count == 6,
              verifiedPincode != nil else {
            showAlert(message: "Please enter a valid 6-digit pincode")
            return false
        }
        
        guard let city = cityTextField.text?.trimmingCharacters(in: .whitespaces),
              !city.isEmpty else {
            showAlert(message: "Please enter your city or area")
            return false
        }
        
        return true
    }
    
    private func saveFormData() {
        coordinator?.profileData.locationState = selectedState
        coordinator?.profileData.postalCode = postalCodeTextField.text
        coordinator?.profileData.locationCity = cityTextField.text?.trimmingCharacters(in: .whitespaces)
        coordinator?.nextStep()
    }
    
    private func navigateToProfilePicture() {
        let profilePictureVC = ProfilePictureViewController()
        profilePictureVC.coordinator = coordinator
        navigationController?.pushViewController(profilePictureVC, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Required Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView Delegate
extension LocationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return indianStates.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return indianStates[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedState = indianStates[row]
        stateTextField.text = indianStates[row]
    }
}

// MARK: - UITextField Delegate
extension LocationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == postalCodeTextField {
            // Only allow numbers
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }
            
            // Limit to 6 digits
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            if updatedText.count > 6 {
                return false
            }
            
            // Verify when 6 digits entered
            if updatedText.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.verifyPincode(updatedText)
                }
            } else {
                resetPincodeVerification()
            }
            
            return true
        }
        
        return true
    }
}

// MARK: - Models
struct PincodeData {
    let pincode: String
    let district: String
    let state: String
    let postOffice: String
}

struct PincodeAPIResponse: Codable {
    let status: String
    let postOffice: [PostOffice]?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case postOffice = "PostOffice"
    }
}

struct PostOffice: Codable {
    let name: String
    let district: String
    let state: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case district = "District"
        case state = "State"
    }
}

enum PincodeError: Error {
    case invalidURL
    case notFound
    case networkError
}
