//
//  ProfilePictureViewController.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class ProfilePictureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let headerView = OnboardingProgressHeader()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add your profile picture"
        label.font = UIFont(name: "AvenirNext-DemiBold", size: 20) ?? .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 75
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let addPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        button.tintColor = .darkGray
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip for now", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Complete Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let backgroundImageView = UIImageView()
    private let glassCard = UIView()
    private var btnGradientLayer: CAGradientLayer?
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    var coordinator: OnboardingCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPremiumUI()
        
        addPhotoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
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
        headerView.configure(title: "Almost done!", currentStep: 5)
        
        // 3. Card
        glassCard.backgroundColor = .white
        glassCard.layer.cornerRadius = 32
        glassCard.clipsToBounds = true
        glassCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassCard)
        
        // 4. Content
        glassCard.addSubview(titleLabel)
        glassCard.addSubview(profileImageView)
        glassCard.addSubview(addPhotoButton)
        glassCard.addSubview(skipButton)
        
        view.addSubview(saveButton)
        view.addSubview(activityIndicator)
        
        // Gradient
        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 0.31, green: 0.07, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.46, green: 0.11, blue: 0.28, alpha: 1.0).cgColor
        ]
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint = CGPoint(x: 1, y: 0.5)
        saveButton.layer.insertSublayer(grad, at: 0)
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
            glassCard.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            skipButton.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -24),
            
            titleLabel.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
            
            profileImageView.centerXAnchor.constraint(equalTo: glassCard.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            profileImageView.widthAnchor.constraint(equalToConstant: 160),
            profileImageView.heightAnchor.constraint(equalToConstant: 160),
            
            addPhotoButton.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: -2),
            addPhotoButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -2),
            addPhotoButton.widthAnchor.constraint(equalToConstant: 44),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            saveButton.heightAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 5)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnGradientLayer?.frame = saveButton.bounds
        btnGradientLayer?.cornerRadius = 20
    }
    
    @objc private func selectPhoto() {
        let alert = UIAlertController(title: "Choose Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addPhotoButton
            popover.sourceRect = addPhotoButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    @objc private func skipTapped() {
        saveProfileToSupabase()
    }
    
    @objc private func saveTapped() {
        saveProfileToSupabase()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            profileImageView.image = image
            profileImageView.tintColor = nil
            coordinator?.profileData.profilePicture = image
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func saveProfileToSupabase() {
        saveButton.isEnabled = false
        skipButton.isEnabled = false
        addPhotoButton.isEnabled = false
        activityIndicator.startAnimating()
        
        Task {
            do {
                guard let profileData = coordinator?.profileData else {
                    throw ProfileError.invalidSession
                }
                
                try await AuthManager.shared.saveProfile(profileData)
                
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    showSuccessAndNavigate()
                }
            } catch {
                print("Error saving profile: \(error)")
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    saveButton.isEnabled = true
                    skipButton.isEnabled = true
                    addPhotoButton.isEnabled = true

                    // Present clearer messages for common failure modes
                    if let pErr = error as? ProfileError {
                        switch pErr {
                        case .invalidSession:
                            showErrorAlert(message: "No valid session. Please sign in and try again.")
                        case .imageCompressionFailed:
                            showErrorAlert(message: "Failed to process the selected image. Try a different photo.")
                        case .uploadFailed:
                            showErrorAlert(message: "Uploading the profile picture failed. The profile may have been saved without the picture.")
                        case .noProfileFound:
                            showErrorAlert(message: "Unable to find profile data to save. Please restart onboarding.")
                        }
                    } else {
                        // Fallback: show the underlying error description when available
                        let message = (error as NSError).localizedDescription
                        showErrorAlert(message: "Failed to save profile: \(message)")
                    }
                }
            }
        }
    }
    
    private func showSuccessAndNavigate() {
        let successLabel = UILabel()
        successLabel.text = "✓ Profile Created!"
        successLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        successLabel.textColor = .white
        successLabel.backgroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        successLabel.textAlignment = .center
        successLabel.layer.cornerRadius = 12
        successLabel.clipsToBounds = true
        successLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(successLabel)
        
        NSLayoutConstraint.activate([
            successLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            successLabel.widthAnchor.constraint(equalToConstant: 200),
            successLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        successLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            successLabel.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.navigateToHomeDashboard()
            }
        }
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
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.saveProfileToSupabase()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
