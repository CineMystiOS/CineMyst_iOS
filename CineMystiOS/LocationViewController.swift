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
    
    private let backgroundImageView = UIImageView()
    private let glassCard = UIView()
    private var btnGradientLayer: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPremiumUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func setupPremiumUI() {
        // 1. Background
        backgroundImageView.image = UIImage(named: "onboarding")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        
        // 2. Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        headerView.configure(title: "Where are you based?", currentStep: 4)
        
        // 3. Card View (Using ScrollView inside it if needed, or making card scrollable)
        glassCard.backgroundColor = .white
        glassCard.layer.cornerRadius = 32
        glassCard.clipsToBounds = true
        glassCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassCard)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        glassCard.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Elements
        stackView.addArrangedSubview(createLabel(text: "State / Union Territory *", fontSize: 16, weight: .bold))
        stateTextField = createDropdownField(placeholder: "Select your state")
        stackView.addArrangedSubview(stateTextField)
        
        stackView.addArrangedSubview(createLabel(text: "Postal Code (Pincode) *", fontSize: 16, weight: .bold))
        let pincodeContainer = createPincodeField()
        stackView.addArrangedSubview(pincodeContainer)
        
        districtLabel = createLabel(text: "", fontSize: 14, weight: .regular, color: .secondaryLabel)
        districtLabel.isHidden = true
        stackView.addArrangedSubview(districtLabel)
        
        stackView.addArrangedSubview(createLabel(text: "City / Area *", fontSize: 16, weight: .bold))
        cityTextField = createTextField(placeholder: "Enter your city or area")
        stackView.addArrangedSubview(cityTextField)
        
        // Button
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Continue", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 0.31, green: 0.07, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.46, green: 0.11, blue: 0.28, alpha: 1.0).cgColor
        ]
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint = CGPoint(x: 1, y: 0.5)
        nextButton.layer.insertSublayer(grad, at: 0)
        self.btnGradientLayer = grad
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            glassCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassCard.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnGradientLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width - 64, height: 60)
        btnGradientLayer?.cornerRadius = 20
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Help label
    private func createLabel(text: String, fontSize: CGFloat, weight: UIFont.Weight, color: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "AvenirNext-Bold", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .bold)
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
            } catch let error as PincodeError {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.handlePincodeError(error)
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.handlePincodeError(.networkError)
                }
            }
        }
    }
    
    private func fetchPincodeData(_ pincode: String) async throws -> PincodeData {
        let urlString = "https://api.postalpincode.in/pincode/\(pincode)"
        guard let url = URL(string: urlString) else {
            throw PincodeError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                print("Pincode API Response Status: \(httpResponse.statusCode)")
            }
            
            // Log raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Pincode API Raw Response: \(jsonString)")
            }
            
            let decodedResponse = try JSONDecoder().decode([PincodeAPIResponse].self, from: data)
            
            guard let firstResult = decodedResponse.first else {
                print("ERROR: Empty response from pincode API")
                throw PincodeError.notFound
            }
            
            print("Pincode Status: \(firstResult.status)")
            
            guard firstResult.status == "Success" else {
                print("ERROR: Pincode API returned status: \(firstResult.status)")
                throw PincodeError.notFound
            }
            
            guard let postOffice = firstResult.postOffice?.first else {
                print("ERROR: No post office data in response")
                throw PincodeError.notFound
            }
            
            return PincodeData(
                pincode: pincode,
                district: postOffice.district,
                state: postOffice.state,
                postOffice: postOffice.name
            )
        } catch let decodingError as DecodingError {
            print("ERROR: Failed to decode pincode response: \(decodingError)")
            throw PincodeError.networkError
        } catch {
            print("ERROR: Network error checking pincode: \(error.localizedDescription)")
            throw PincodeError.networkError
        }
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
    
    private func handlePincodeError(_ error: PincodeError? = nil) {
        verifiedPincode = nil
        
        let errorMessage: String
        switch error {
        case .networkError:
            errorMessage = "✗ Network error - check connection"
        case .invalidURL, .notFound, .none:
            errorMessage = "✗ Invalid or not found"
        default:
            errorMessage = "✗ Invalid pincode"
        }
        
        districtLabel.text = errorMessage
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
