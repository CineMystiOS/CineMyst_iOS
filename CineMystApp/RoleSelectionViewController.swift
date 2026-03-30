//
//  RoleSelectionViewController.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class RoleSelectionViewController: UIViewController {
    
    private let headerView = OnboardingProgressHeader()
    
    private var roleCards: [RoleCardView] = []
    private var selectedRole: UserRole?
    
    var coordinator: OnboardingCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        
        headerView.configure(title: "What brings you here?", currentStep: 2)
        navigationItem.hidesBackButton = false
        setupBackButton()
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
    
    private func setupUI() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Artist Card
        let artistCard = createRoleCard(
            role: .artist,
            icon: "theatermasks.fill",
            title: "Artist / Talent",
            description: "I'm looking for acting roles, gigs, and opportunities"
        )
        stackView.addArrangedSubview(artistCard)
        roleCards.append(artistCard)
        
        // Casting Professional Card
        let castingCard = createRoleCard(
            role: .castingProfessional,
            icon: "person.3.fill",
            title: "Casting Professional",
            description: "I'm recruiting talent for productions and projects"
        )
        stackView.addArrangedSubview(castingCard)
        roleCards.append(castingCard)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createRoleCard(role: UserRole, icon: String, title: String, description: String) -> RoleCardView {
        let card = RoleCardView()
        card.configure(icon: icon, title: title, description: description)
        card.role = role
        card.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(roleCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        
        return card
    }
    
    @objc private func roleCardTapped(_ sender: UITapGestureRecognizer) {
        guard let card = sender.view as? RoleCardView,
              let role = card.role else { return }
        
        selectedRole = role
        coordinator?.profileData.role = role
        coordinator?.nextStep()
        
        // Animate selection
        roleCards.forEach { $0.setSelected(false) }
        card.setSelected(true)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.navigateToRoleDetails()
        }
    }
    
    private func navigateToRoleDetails() {
        let roleDetailsVC = RoleDetailsViewController()
        roleDetailsVC.coordinator = coordinator
        navigationController?.pushViewController(roleDetailsVC, animated: true)
    }
}

// MARK: - Role Card View
class RoleCardView: UIView {
    
    var role: UserRole?
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 16
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 28),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    func configure(icon: String, title: String, description: String) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            if selected {
                self.backgroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 0.1)
                self.layer.borderColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0).cgColor
                self.checkmarkImageView.isHidden = false
                self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            } else {
                self.backgroundColor = .secondarySystemGroupedBackground
                self.layer.borderColor = UIColor.clear.cgColor
                self.checkmarkImageView.isHidden = true
                self.transform = .identity
            }
        }
    }
}
