//
//  LoginViewController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit
import Supabase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!

    private var activityIndicator: UIActivityIndicatorView!
    private var loginTimeoutTimer: Timer?
    
    // MARK: - Gradient Layer
    private var gradientLayer: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
        setupUI()
        setupActivityIndicator()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
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
    
    // MARK: - UI SETUP
    private func setupUI() {
        emailTextField.keyboardType = .default
        emailTextField.autocapitalizationType = .none
        emailTextField.placeholder = "Username or Email"
        emailTextField.delegate = self

        passwordTextField.isSecureTextEntry = true
        passwordTextField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
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
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
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
            return false
        }
        
        let userId = session.user.id
        print("🔍 Checking profile for user: \(userId)")
        
        do {
            let response = try await supabase
                .from("profiles")
                .select("onboarding_completed")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            if let data = response.data as? [String: Any],
               let onboardingCompleted = data["onboarding_completed"] as? Bool {
                print("✅ Profile found - Onboarding complete: \(onboardingCompleted)")
                return onboardingCompleted
            } else {
                print("⚠️ Profile exists but onboarding_completed status unclear")
                return false
            }
        } catch {
            print("⚠️ Profile check error: \(error)")
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
        let message: String
        if let supabaseError = error as? AuthError {
            message = supabaseError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        showAlert(message: message)
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
}

extension LoginError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials"
        }
    }
}
