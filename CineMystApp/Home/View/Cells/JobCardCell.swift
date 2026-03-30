//
//  JobCardCell.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit

final class JobCardCell: UITableViewCell {
    
    static let reuseId = "JobCardCell"
    
    // MARK: - UI Components
    private let container = UIView()
    private let logo = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let locationLabel = UILabel()
    private let payLabel = UILabel()
    private let tagLabel = UILabel()
    private let applyButton = UIButton(type: .system)
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .clear
        
        // Container View
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo
        logo.layer.cornerRadius = 20
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFill
        logo.image = UIImage(named: "job_placeholder")
        
        // Labels
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        locationLabel.font = .systemFont(ofSize: 13)
        locationLabel.textColor = .secondaryLabel
        payLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        payLabel.textColor = .systemPink
        
        // Tag Label
        tagLabel.font = .systemFont(ofSize: 12, weight: .medium)
        tagLabel.textAlignment = .center
        tagLabel.textColor = .white
        tagLabel.backgroundColor = .systemRed
        tagLabel.layer.cornerRadius = 10
        tagLabel.clipsToBounds = true
        
        // Apply Button
        applyButton.setTitle("Apply Now", for: .normal)
        applyButton.backgroundColor = UIColor(red: 48/255, green: 0/255, blue: 36/255, alpha: 1)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.layer.cornerRadius = 8
        
        // Add all views
        [logo, titleLabel, subtitleLabel, locationLabel, payLabel, tagLabel, applyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        contentView.addSubview(container)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            logo.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            logo.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            logo.widthAnchor.constraint(equalToConstant: 40),
            logo.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: logo.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            locationLabel.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            
            payLabel.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            payLabel.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 12),
            
            tagLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            tagLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            tagLabel.widthAnchor.constraint(equalToConstant: 90),
            tagLabel.heightAnchor.constraint(equalToConstant: 24),
            
            applyButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            applyButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            applyButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            applyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Configure with Model
    func configure(with job: Job) {
        titleLabel.text = job.title
        subtitleLabel.text = job.companyName
        locationLabel.text = job.location
        payLabel.text = "₹\(job.ratePerDay)/day"
        tagLabel.text = "  \(job.jobType)  "
        logo.image = UIImage(named: "jobicon") // static or mapped
    }
}
