//
//  SignUpViewController.swift
//  CineMystApp
//
//  Created by user@50 on 19/11/25.
//

import UIKit
import Supabase

class SignUpViewController: UIViewController {
    
    // PROGRAMMATIC UI ELEMENTS
    let usernameTextField    = UITextField()
    let fullNameTextField    = UITextField()
    let emailTextField       = UITextField()
    let passwordTextField    = UITextField()
    let confirmPasswordTextField = UITextField()
    let signUpButton         = UIButton(type: .system)
    let signInButton         = UIButton(type: .system)
    
    let cardView             = UIView()
    let termsCheckbox        = UIButton(type: .custom)
    let termsLabel           = UILabel()
    
    private var activityIndicator: UIActivityIndicatorView!
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear 
        // applyGradientBackground() // Removed to allow clear background
        setupProgrammaticUI()
        setupActivityIndicator()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // updateGradientFrame()
    }
    
    // MARK: - Gradient Background
    private func applyGradientBackground() {
        let gradient = CAGradientLayer()
        
        gradient.colors = [
            UIColor(red: 54/255, green: 18/255, blue: 52/255, alpha: 1).cgColor,
            UIColor(red: 22/255, green: 8/255, blue: 35/255, alpha: 1).cgColor
        ]
        
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        
        view.layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    private func updateGradientFrame() {
        gradientLayer?.frame = view.bounds
    }
    
    private func setupProgrammaticUI() {
        // 1. Card View setup 
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)
        
        // 2. Element Style helpers
        func applyLabelStyle(_ l: UILabel, text: String) {
            l.text = text
            l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            l.textColor = UIColor(red: 0.35, green: 0.4, blue: 0.5, alpha: 1.0)
            l.translatesAutoresizingMaskIntoConstraints = false
        }
        
        func applyFieldStyle(_ f: UITextField, placeholder: String) {
            f.placeholder = placeholder
            f.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
            f.layer.cornerRadius = 14
            f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
            f.leftViewMode = .always
            f.font = UIFont.systemFont(ofSize: 16)
            f.translatesAutoresizingMaskIntoConstraints = false
            f.heightAnchor.constraint(equalToConstant: 52).isActive = true
            f.delegate = self
            f.autocorrectionType = .no
        }
        
        // 3. Setup Elements
        let userLabel = UILabel(); applyLabelStyle(userLabel, text: "Username/Stage Name")
        applyFieldStyle(usernameTextField, placeholder: "ashina_mehra")
        usernameTextField.autocapitalizationType = .none
        
        let nameLabel = UILabel(); applyLabelStyle(nameLabel, text: "Full Name")
        applyFieldStyle(fullNameTextField, placeholder: "Enter your name")
        
        let mailLabel = UILabel(); applyLabelStyle(mailLabel, text: "Email")
        applyFieldStyle(emailTextField, placeholder: "eg: sam67@gmail.com")
        emailTextField.autocapitalizationType = .none
        
        let passLabel = UILabel(); applyLabelStyle(passLabel, text: "Password")
        applyFieldStyle(passwordTextField, placeholder: "********")
        passwordTextField.isSecureTextEntry = true
        addEyeToggle(to: passwordTextField)
        
        let confirmLabel = UILabel(); applyLabelStyle(confirmLabel, text: "Confirm Password")
        applyFieldStyle(confirmPasswordTextField, placeholder: "********")
        confirmPasswordTextField.isSecureTextEntry = true
        addEyeToggle(to: confirmPasswordTextField)
        
        // Terms Checkbox
        termsCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        termsCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        termsCheckbox.tintColor = .black
        termsCheckbox.isSelected = true 
        termsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        termsCheckbox.addTarget(self, action: #selector(toggleTerms), for: .touchUpInside)
        
        termsLabel.text = "I agree to the Terms & Privacy Policy"
        termsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        termsLabel.textColor = .black
        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.backgroundColor = UIColor(red: 0.2, green: 0.08, blue: 0.18, alpha: 1.0)
        signUpButton.layer.cornerRadius = 20
        signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        signUpButton.addTarget(self, action: #selector(confirmSignUpTapped), for: .touchUpInside)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.alignment = .center
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        let noteLabel = UILabel()
        noteLabel.text = "Already have an account?"
        noteLabel.font = UIFont.systemFont(ofSize: 15)
        noteLabel.textColor = .gray
        
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(UIColor(red: 0.2, green: 0.08, blue: 0.18, alpha: 1.0), for: .normal)
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        signInButton.addTarget(self, action: #selector(backToSignInTapped), for: .touchUpInside)
        
        bottomStack.addArrangedSubview(noteLabel)
        bottomStack.addArrangedSubview(signInButton)
        
        // 4. Content Scroll View (for accessibility)
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        cardView.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Add to contentView
        contentView.addSubview(userLabel)
        contentView.addSubview(usernameTextField)
        contentView.addSubview(nameLabel)
        contentView.addSubview(fullNameTextField)
        contentView.addSubview(mailLabel)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passLabel)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(confirmLabel)
        contentView.addSubview(confirmPasswordTextField)
        contentView.addSubview(termsCheckbox)
        contentView.addSubview(termsLabel)
        contentView.addSubview(signUpButton)
        contentView.addSubview(bottomStack)
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.topAnchor.constraint(equalTo: view.topAnchor),
            
            scrollView.topAnchor.constraint(equalTo: cardView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            userLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            userLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            usernameTextField.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 10),
            usernameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            usernameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            nameLabel.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            fullNameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            fullNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            fullNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            mailLabel.topAnchor.constraint(equalTo: fullNameTextField.bottomAnchor, constant: 18),
            mailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            emailTextField.topAnchor.constraint(equalTo: mailLabel.bottomAnchor, constant: 10),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            passLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 18),
            passLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            passwordTextField.topAnchor.constraint(equalTo: passLabel.bottomAnchor, constant: 10),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            confirmLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 18),
            confirmLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            confirmPasswordTextField.topAnchor.constraint(equalTo: confirmLabel.bottomAnchor, constant: 10),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            termsCheckbox.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 20),
            termsCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            termsCheckbox.widthAnchor.constraint(equalToConstant: 24),
            termsCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            termsLabel.centerYAnchor.constraint(equalTo: termsCheckbox.centerYAnchor),
            termsLabel.leadingAnchor.constraint(equalTo: termsCheckbox.trailingAnchor, constant: 8),
            
            signUpButton.topAnchor.constraint(equalTo: termsCheckbox.bottomAnchor, constant: 30),
            signUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            signUpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            signUpButton.heightAnchor.constraint(equalToConstant: 58),
            
            bottomStack.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 24),
            bottomStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func toggleTerms() { termsCheckbox.isSelected.toggle() }
    @objc private func confirmSignUpTapped() { signUpButtonTapped(signUpButton) }
    @objc private func backToSignInTapped() { signInButtonTapped(signInButton) }

    private func addEyeToggle(to field: UITextField) {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        btn.setImage(UIImage(systemName: "eye"), for: .selected)
        btn.tintColor = .gray
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.tag = field.tag
        // Store the field reference via closure
        btn.addAction(UIAction { [weak btn, weak field] _ in
            guard let btn, let field else { return }
            field.isSecureTextEntry.toggle()
            btn.isSelected = !field.isSecureTextEntry
        }, for: .touchUpInside)
        field.rightView = btn
        field.rightViewMode = .always
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func signUpButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespaces), !username.isEmpty,
              let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespaces), !fullName.isEmpty,
              let email = emailTextField.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill all fields")
            return
        }

        guard isValidUsername(username) else {
            showAlert(message: "Username must be 3-20 characters, only letters, numbers, and underscores allowed")
            return
        }

        guard isValidEmail(email) else {
            showAlert(message: "Enter a valid email")
            return
        }

        guard password.count >= 6 else {
            showAlert(message: "Password must be at least 6 characters")
            return
        }

        // ✅ Confirm password check — prevents mistyped passwords
        let confirm = confirmPasswordTextField.text ?? ""
        guard !confirm.isEmpty else {
            showAlert(message: "Please confirm your password")
            confirmPasswordTextField.becomeFirstResponder()
            return
        }
        guard password == confirm else {
            showAlert(message: "Passwords do not match. Please re-enter them carefully.")
            passwordTextField.text = ""
            confirmPasswordTextField.text = ""
            passwordTextField.becomeFirstResponder()
            return
        }

        performSignUp(username: username, fullName: fullName, email: email, password: password)
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Sign Up
    private func performSignUp(username: String, fullName: String, email: String, password: String) {
        showLoading(true)

        Task {
            do {
                // ✅ Sign up with user metadata
                let authResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "username": AnyJSON(username),
                        "full_name": AnyJSON(fullName)
                    ]
                )

                // ✅ NEW: Create minimal profile record immediately (for username login)
                // Using authResponse.user (non-optional)
                let userId = authResponse.user.id
                print("📝 Creating initial profile record for username lookup...")
                
                // Get current timestamp for lastActiveAt
                let dateFormatter = ISO8601DateFormatter()
                let now = dateFormatter.string(from: Date())
                
                let initialProfile = ProfileRecordForSave(
                    id: userId.uuidString,
                    username: username,
                    fullName: fullName,
                    dateOfBirth: nil,
                    profilePictureUrl: nil,
                    avatarUrl: nil,  // Will be set when user uploads profile picture
                    role: nil,  // Optional - Instagram style (set later in profile settings)
                    employmentStatus: nil,
                    locationState: nil,
                    postalCode: nil,
                    locationCity: nil,
                    bio: nil,  // Can be added later
                    phoneNumber: nil,  // Can be added later
                    websiteUrl: nil,  // Can be added later
                    isVerified: false,  // New users start unverified
                    connectionCount: 0,  // New users have 0 connections
                    onboardingCompleted: false,  // Not complete until role is set
                    lastActiveAt: now,
                    bannerUrl: nil  // ✅ ADD THIS LINE
                    
                )
                
                do {
                    try await supabase
                        .from("profiles")
                        .upsert(initialProfile)
                        .execute()
                    print("✅ Initial profile created (username: \(username), email: \(email), onboarding_completed: false)")
                } catch {
                    print("⚠️ Could not create initial profile, continuing: \(error)")
                }

                await MainActor.run {
                    showLoading(false)
                    
                    if self.requiresEmailConfirmation() {
                        self.showAlert(
                            title: "Account Created",
                            message: "Please check your email to verify your account, then sign in to continue."
                        )
                    } else {
                        // ✅ Check if session exists
                        if authResponse.session != nil {
                            print("✅ Session established during signup - going to dashboard")
                            self.navigateToDashboard()
                        } else {
                            // ✅ No session - try signing in
                            print("⚠️ No session after signup, attempting sign in...")
                            Task {
                                do {
                                    try await supabase.auth.signIn(email: email, password: password)
                                    
                                    // ✅ Wait a moment for session to be established
                                    try await Task.sleep(nanoseconds: 500_000_000)
                                    
                                    await MainActor.run {
                                        print("✅ Session created via signIn - going to dashboard")
                                        self.navigateToDashboard()
                                    }
                                } catch {
                                    await MainActor.run {
                                        print("❌ Sign-in failed: \(error)")
                                        self.showAlert(
                                            title: "Account Created",
                                            message: "Your account was created. Please sign in manually."
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

            } catch {
                await MainActor.run {
                    showLoading(false)
                    
                    var errorMessage = error.localizedDescription
                    if errorMessage.contains("already registered") || errorMessage.contains("duplicate") {
                        errorMessage = "This email or username is already registered. Please sign in instead."
                    } else if errorMessage.contains("username") {
                        errorMessage = "This username is already taken. Please choose another one."
                    }
                    
                    showAlert(message: errorMessage)
                }
            }
        }
    }
    
    // ✅ LINKEDIN STYLE: Go straight to dashboard (profile setup is optional)
    private func navigateToDashboard() {
        let tabBarVC = CineMystTabBarController()
        tabBarVC.modalPresentationStyle = .fullScreen
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()
            
            UIView.transition(with: window,
                             duration: 0.5,
                             options: .transitionCrossDissolve,
                             animations: nil)
        }
    }
    
    // MARK: - Email Confirmation Check
    private func requiresEmailConfirmation() -> Bool {
        // Set to true if your Supabase has email confirmation enabled
        return true // Change to true in production
    }

    // MARK: - Helpers
    private func isValidUsername(_ username: String) -> Bool {
        // 3-20 characters, only letters, numbers, and underscores
        let regex = "^[a-zA-Z0-9_]{3,20}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        view.isUserInteractionEnabled = !show
    }

    
}

// MARK: - UITextFieldDelegate
extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == confirmPasswordTextField {
            textField.resignFirstResponder()
            signUpButtonTapped(signUpButton as Any)
        }
        return true
    }
}

