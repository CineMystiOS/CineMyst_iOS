//
//  SignUpViewController.swift
//  CineMystApp
//
//  Created by user@50 on 19/11/25.
//

import UIKit
import Supabase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    private var activityIndicator: UIActivityIndicatorView!
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Lifecycle
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
    
    // MARK: - UI Setup
    private func setupUI() {
        passwordTextField.isSecureTextEntry = true
        emailTextField.autocapitalizationType = .none
        usernameTextField.autocapitalizationType = .none
        
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
    @IBAction func signUpButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespaces), !username.isEmpty,
              let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespaces), !fullName.isEmpty,
              let email = emailTextField.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill all fields")
            return
        }

        // Validate username format
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

    private func showAlert(title: String = "CineMyst", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
