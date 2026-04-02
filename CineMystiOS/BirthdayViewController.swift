//
//  BirthdayViewController.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class BirthdayViewController: UIViewController {
    
    private let backgroundImageView = UIImageView()
    private let glassCard = UIView()
    private let contentStack = UIStackView()
    private var btnGradientLayer: CAGradientLayer?
    
    private let nextButton = UIButton(type: .system)
    
    var coordinator: OnboardingCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPremiumUI()
        
        // Hide back button
        navigationItem.hidesBackButton = true
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
        headerView.configure(title: "When's your birthday?", currentStep: 1)
        
        // 3. Card
        glassCard.backgroundColor = .white
        glassCard.layer.cornerRadius = 32
        glassCard.clipsToBounds = true
        glassCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassCard)
        
        // 4. Content
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        glassCard.addSubview(datePicker)
        
        // 5. Button
        nextButton.setTitle("Next Step", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        setupButtonGradient()
        
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
            
            glassCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            glassCard.heightAnchor.constraint(equalToConstant: 240),
            
            datePicker.centerXAnchor.constraint(equalTo: glassCard.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: glassCard.centerYAnchor),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupButtonGradient() {
        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 0.31, green: 0.07, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.46, green: 0.11, blue: 0.28, alpha: 1.0).cgColor
        ]
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint = CGPoint(x: 1, y: 0.5)
        nextButton.layer.insertSublayer(grad, at: 0)
        self.btnGradientLayer = grad
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnGradientLayer?.frame = nextButton.bounds
        btnGradientLayer?.cornerRadius = 20
    }
    
    private let datePicker = UIDatePicker()
    private let headerView = OnboardingProgressHeader()
    
    @objc private func nextTapped() {
        coordinator?.profileData.dateOfBirth = datePicker.date
        coordinator?.nextStep()
        
        let roleSelectionVC = RoleSelectionViewController()
        roleSelectionVC.coordinator = coordinator
        navigationController?.pushViewController(roleSelectionVC, animated: true)
    }
}
