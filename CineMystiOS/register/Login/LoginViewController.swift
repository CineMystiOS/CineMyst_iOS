//
//  LoginViewController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit
import Supabase

class LoginViewController: UIViewController {

    // PROGRAMMATIC UI ELEMENTS
    let emailTextField    = UITextField()
    let passwordTextField = UITextField()
    let signInButton      = UIButton(type: .system)
    let cardView          = UIView()
    let titleLabel        = UILabel()
    let subtitleLabel     = UILabel()
    let forgotPasswordButton = UIButton(type: .system)
    let googleSignInButton = UIButton(type: .system)
    let signUpPromptLabel = UILabel()
    let signUpButton      = UIButton(type: .system)

    private var activityIndicator: UIActivityIndicatorView!
    private var loginTimeoutTimer: Timer?
    
    // MARK: - Gradient Layer
    private var gradientLayer: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear // Transparent to see onboarding below
        setupProgrammaticUI()
        setupActivityIndicator()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // updateGradientFrame()
    }
    
    // MARK: - Gradient Layer
    private func applyGradientBackground() {
        let gradient = CAGradientLayer()
        
        gradient.colors = [
            UIColor(red: 54/255, green: 18/255, blue: 52/255, alpha: 1).cgColor, // top color
            UIColor(red: 22/255, green: 8/255, blue: 35/255, alpha: 1).cgColor   // bottom color
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        
        // Clean old layers if you hot-reload
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
        // 1. Card View setup (Matches user screenshot)
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
            f.heightAnchor.constraint(equalToConstant: 54).isActive = true
            f.delegate = self
        }
        
        // 3. Setup Elements
        let emailLabel = UILabel(); applyLabelStyle(emailLabel, text: "Username or Email")
        applyFieldStyle(emailTextField, placeholder: "sam67@gmail.com")
        emailTextField.autocapitalizationType = .none
        
        let passLabel = UILabel(); applyLabelStyle(passLabel, text: "Password")
        applyFieldStyle(passwordTextField, placeholder: "********")
        passwordTextField.isSecureTextEntry = true
        
        forgotPasswordButton.setTitle("Forgot Password ?", for: .normal)
        forgotPasswordButton.setTitleColor(UIColor(red: 0.15, green: 0.05, blue: 0.2, alpha: 1.0), for: .normal)
        forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.backgroundColor = UIColor(red: 0.2, green: 0.08, blue: 0.18, alpha: 1.0)
        signInButton.layer.cornerRadius = 20
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.systemGray5
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let orLabel = UILabel()
        orLabel.text = "Or"
        orLabel.textColor = .systemGray3
        orLabel.font = UIFont.systemFont(ofSize: 14)
        orLabel.backgroundColor = .white
        orLabel.textAlignment = .center
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        
        googleSignInButton.setTitle("Continue with Google", for: .normal)
        googleSignInButton.setTitleColor(.black, for: .normal)
        googleSignInButton.layer.borderWidth = 1
        googleSignInButton.layer.borderColor = UIColor.systemGray5.cgColor
        googleSignInButton.layer.cornerRadius = 14
        googleSignInButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        googleSignInButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Google Icon from assets (preserving original color)
        if let googleImg = UIImage(named: "google")?.withRenderingMode(.alwaysOriginal) {
            googleSignInButton.setImage(googleImg, for: .normal)
            googleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
            googleSignInButton.imageView?.contentMode = .scaleAspectFit
        } else if let googleSF = UIImage(systemName: "g.circle.fill") {
            googleSignInButton.setImage(googleSF, for: .normal)
            googleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.alignment = .center
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        let noteLabel = UILabel()
        noteLabel.text = "Don't have an account?"
        noteLabel.font = UIFont.systemFont(ofSize: 15)
        noteLabel.textColor = .gray
        
        signUpButton.setTitle("Sign up", for: .normal)
        signUpButton.setTitleColor(UIColor(red: 0.2, green: 0.08, blue: 0.18, alpha: 1.0), for: .normal)
        signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        
        bottomStack.addArrangedSubview(noteLabel)
        bottomStack.addArrangedSubview(signUpButton)
        
        // 4. Content Scroll View (Prevents lower part from being hidden)
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        cardView.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        contentView.addSubview(emailLabel)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passLabel)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(forgotPasswordButton)
        contentView.addSubview(signInButton)
        contentView.addSubview(divider)
        contentView.addSubview(orLabel)
        contentView.addSubview(googleSignInButton)
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
            
            emailLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 10),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            passLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 24),
            passLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            
            passwordTextField.topAnchor.constraint(equalTo: passLabel.bottomAnchor, constant: 14),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 12),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            signInButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 30),
            signInButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            signInButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            signInButton.heightAnchor.constraint(equalToConstant: 58),
            
            divider.centerYAnchor.constraint(equalTo: orLabel.centerYAnchor),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            orLabel.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 18),
            orLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            orLabel.widthAnchor.constraint(equalToConstant: 40),
            
            googleSignInButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 18),
            googleSignInButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            googleSignInButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 58),
            
            bottomStack.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
            bottomStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func signInTapped() { signInButtonTapped(signInButton) }
    @objc private func forgotPasswordTapped() { forgetPasswordButtonTapped(forgotPasswordButton) }
    @objc private func signUpTapped() { signUpButtonTapped(signUpButton) }
    @objc private func googleTapped() { googleLoginTapped(googleSignInButton) }

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
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        guard let input = emailTextField.text?.trimmingCharacters(in: .whitespaces),
              !input.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            showAlert(message: "Please enter username/email and password")
            return
        }

        let isEmail = isValidEmail(input)
        
        if isEmail {
            signIn(email: input, password: password)
        } else {
            resolveUsernameToEmail(input, password: password)
        }
    }
    
    @IBAction func forgetPasswordButtonTapped(_ sender: UIButton) {
        showResetPasswordAlert()
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    

    
    @IBAction func googleLoginTapped(_ sender: UIButton) {
        print("🔵 Google login button tapped")
            AuthManager.shared.signInWithGoogle(from: self)
    }
    
    // MARK: - Resolve Username to Email
    private func resolveUsernameToEmail(_ username: String, password: String) {
        showLoading(true)
        disableUI()
        
        Task {
            do {
                // ✅ Query profiles table for username to get email
                print("🔍 Looking up username: \(username)")
                
                let response = try await supabase
                    .from("profiles")
                    .select("email")  // Get the email stored in profiles table
                    .eq("username", value: username.lowercased())
                    .single()
                    .execute()
                
                guard let data = response.data as? [String: Any],
                      let email = data["email"] as? String else {
                    throw LoginError.userNotFound
                }
                
                print("✅ Found email for username: \(email)")
                
                await MainActor.run {
                    self.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    showLoading(false)
                    enableUI()
                    showAlert(message: "Username not found. Please check the username spelling or sign up first.")
                }
            }
        }
    }
    
    // MARK: - SUPABASE LOGIN (Updated with Profile Check)
    private func signIn(email: String, password: String) {
        showLoading(true)
        disableUI()
        
        // Set timeout timer (15 seconds)
        loginTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            self?.handleLoginTimeout()
        }

        Task {
               do {
                   try await supabase.auth.signIn(email: email, password: password)
                   
                   // Invalidate timeout timer on success
                   self.loginTimeoutTimer?.invalidate()
                   self.loginTimeoutTimer = nil
                   
                   // ✅ VALIDATE SESSION EXISTS AFTER AUTH
                   let session = try await AuthManager.shared.currentSession()
                   guard session != nil else {
                       throw LoginError.sessionValidationFailed
                   }
                   
                   let isOnboardingComplete = try await checkUserProfile()
                   
                   await MainActor.run {
                       showLoading(false)
                       enableUI()
                       
                       if isOnboardingComplete {
                           // Onboarding complete - go to dashboard
                           self.navigateToHomeDashboard()
                       } else {
                           // Onboarding not complete - start step-by-step flow
                           self.navigateToBirthdate()
                       }
                   }
               } catch {
                   // Invalidate timeout timer on error
                   self.loginTimeoutTimer?.invalidate()
                   self.loginTimeoutTimer = nil
                   
                   await MainActor.run {
                       showLoading(false)
                       enableUI()
                       handleAuthError(error)
                   }
               }
           }
       }
    
    private func handleLoginTimeout() {
        DispatchQueue.main.async { [weak self] in
            self?.showLoading(false)
            self?.enableUI()
            self?.showAlert(message: "Login took too long. Please check your connection and try again.")
        }
    }
    
    // MARK: - Profile Check
    private func checkUserProfile() async throws -> Bool {
        guard let session = try await AuthManager.shared.currentSession() else {
            print("❌ No session available for profile check")
            return false  // let them through to onboarding
        }

        let userId = session.user.id
        print("🔍 Checking profile for user: \(userId)")

        // response.data is raw Data bytes — 'as? [String:Any]' always fails.
        // Use Codable .value decoding instead.
        struct ProfileCheck: Codable {
            let onboarding_completed: Bool?
        }

        do {
            let profile: ProfileCheck = try await supabase
                .from("profiles")
                .select("onboarding_completed")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let completed = profile.onboarding_completed ?? false
            print("✅ Onboarding complete: \(completed)")
            return completed
        } catch {
            // No profile row yet — route to onboarding, don't block login
            print("⚠️ Profile check failed (no row yet?): \(error). Routing to onboarding.")
            return false
        }
    }


    // MARK: - RESET PASSWORD
    private func showResetPasswordAlert() {
        let alert = UIAlertController(title: "Reset Password",
                                      message: "Enter your email",
                                      preferredStyle: .alert)

        alert.addTextField { tf in
            tf.placeholder = "Email"
            tf.keyboardType = .emailAddress
            tf.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text, !email.isEmpty else { return }
            self?.resetPassword(email: email)
        })

        present(alert, animated: true)
    }

    private func resetPassword(email: String) {
        guard isValidEmail(email) else {
            showAlert(message: "Invalid email")
            return
        }

        showLoading(true)

        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)

                await MainActor.run {
                    showLoading(false)
                    showAlert(title: "Check Email", message: "We sent you a reset password link.")
                }
            } catch {
                await MainActor.run {
                    showLoading(false)
                    showAlert(message: "Failed to send reset email")
                }
            }
        }
    }

    // MARK: - Navigation
    
    private func navigateToBirthdate() {
        // Start step-by-step onboarding flow: Birthdate → Location → Profile Picture → About
        let coordinator = OnboardingCoordinator()
        coordinator.isPostLoginFlow = true  // Skip role selection for post-login
        
        let birthdayVC = BirthdayViewController()
        birthdayVC.coordinator = coordinator
        
        navigationController?.pushViewController(birthdayVC, animated: true)
    }
    
    private func navigateToOnboarding() {
        // Create onboarding coordinator
        let coordinator = OnboardingCoordinator()
        
        // Create first onboarding screen (Birthday)
        let birthdayVC = BirthdayViewController()
        birthdayVC.coordinator = coordinator
        
        // Navigate to birthday screen
        navigationController?.pushViewController(birthdayVC, animated: true)
    }
    
    private func navigateToHomeDashboard() {
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

    // MARK: - ERROR HANDLING
    private func handleAuthError(_ error: Error) {
        let title: String
        let message: String
        
        // ✅ DETAILED ERROR MESSAGES
        if let loginError = error as? LoginError {
            title = "Login Failed"
            switch loginError {
            case .userNotFound:
                message = "User account not found. Please check your credentials or sign up."
            case .invalidCredentials:
                message = "Invalid email or password. Please try again."
            case .sessionValidationFailed:
                message = "Session validation failed. Please try signing in again."
            case .profileCheckFailed(let details):
                message = "Could not load your profile: \(details). Please try signing in again."
            }
        } else if let supabaseError = error as? AuthError {
            title = "Authentication Error"
            let errorDesc = supabaseError.localizedDescription.lowercased()
            if errorDesc.contains("invalid login") || errorDesc.contains("invalid credentials") {
                message = "Invalid email or password. Please check your credentials and try again."
            } else if errorDesc.contains("not registered") || errorDesc.contains("user not found") {
                message = "This email is not registered. Please sign up first."
            } else if errorDesc.contains("network") || errorDesc.contains("connection") {
                message = "Network error. Please check your internet connection and try again."
            } else {
                message = supabaseError.localizedDescription
            }
        } else {
            title = "Error"
            message = error.localizedDescription
        }
        
        showAlert(title: title, message: message)
    }

    // MARK: - HELPERS
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func showLoading(_ show: Bool) {
        show ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }

    private func disableUI() {
        view.isUserInteractionEnabled = false
    }

    private func enableUI() {
        view.isUserInteractionEnabled = true
    }

    private func showAlert(title: String = "CineMyst", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
   


}

// MARK: - TEXTFIELD DELEGATE
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signInButtonTapped(signInButton)
        }
        return true
    }
}

// MARK: - Login Errors
enum LoginError: Error {
    case userNotFound
    case invalidCredentials
    case sessionValidationFailed
    case profileCheckFailed(String)
}

extension LoginError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials"
        case .sessionValidationFailed:
            return "Session validation failed"
        case .profileCheckFailed(let details):
            return "Profile check failed: \(details)"
        }
    }
}
