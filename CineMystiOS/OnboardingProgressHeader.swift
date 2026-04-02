//
//  OnboardingProgressHeader.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import UIKit

class OnboardingProgressHeader: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "This helps us personalize your experience"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let totalSteps = 5
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(progressStackView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        // Create progress bars (not dots)
        for _ in 0..<totalSteps {
            let bar = createProgressBar()
            progressStackView.addArrangedSubview(bar)
        }
        
        NSLayoutConstraint.activate([
            progressStackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            progressStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            progressStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            progressStackView.heightAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: progressStackView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    private func createProgressBar() -> UIView {
        let bar = UIView()
        bar.backgroundColor = UIColor.systemGray5
        bar.layer.cornerRadius = 2
        bar.clipsToBounds = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }
    
    func configure(title: String, currentStep: Int, subtitle: String? = nil) {
        titleLabel.text = title
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
        
        // Update progress bars with animation
        for (index, view) in progressStackView.arrangedSubviews.enumerated() {
            UIView.animate(withDuration: 0.4, delay: Double(index) * 0.05) {
                if index < currentStep {
                    view.backgroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
                } else {
                    view.backgroundColor = UIColor.systemGray5
                }
            }
        }
    }
}
