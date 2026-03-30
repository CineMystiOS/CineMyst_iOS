//
//  PortfolioHeaderCell.swift
//  CineMystApp
//

import UIKit

final class PortfolioHeaderCell: UICollectionViewCell {
    static let reuseId = "PortfolioHeaderCell"
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .darkGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "CormorantGaramond-Medium", size: 28) ?? UIFont.systemFont(ofSize: 28, weight: .medium)
        lbl.textColor = UIColor(red: 207/255, green: 184/255, blue: 146/255, alpha: 1) // #CFB892
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let roleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let editButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("📝 Edit Portfolio", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = UIColor(red: 207/255, green: 184/255, blue: 146/255, alpha: 1)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btn.layer.cornerRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let contactButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Contact Me", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .clear
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 1
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btn.layer.cornerRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let socialStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 16
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let aboutTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "I am Nikki"
        lbl.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let aboutLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        lbl.textColor = UIColor(white: 0.8, alpha: 1)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .black
        
        addSubview(profileImageView)
        addSubview(nameLabel)
        addSubview(roleLabel)
        addSubview(editButton)
        addSubview(contactButton)
        addSubview(socialStackView)
        addSubview(aboutTitleLabel)
        addSubview(aboutLabel)
        
        // Create social media buttons
        let socialIcons = ["instagram", "youtube", "tiktok", "twitter", "facebook", "imdb"]
        for icon in socialIcons {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: "square.fill"), for: .normal) // Replace with actual icons
            btn.tintColor = UIColor(red: 207/255, green: 184/255, blue: 146/255, alpha: 1)
            btn.backgroundColor = UIColor(white: 0.15, alpha: 1)
            btn.layer.cornerRadius = 4
            socialStackView.addArrangedSubview(btn)
            
            btn.widthAnchor.constraint(equalToConstant: 32).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        }
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 200),
            profileImageView.heightAnchor.constraint(equalToConstant: 250),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            editButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 16),
            editButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            editButton.heightAnchor.constraint(equalToConstant: 36),
            editButton.widthAnchor.constraint(equalToConstant: 140),
            
            contactButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 16),
            contactButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contactButton.heightAnchor.constraint(equalToConstant: 36),
            contactButton.widthAnchor.constraint(equalToConstant: 120),
            
            socialStackView.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 20),
            socialStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            socialStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            socialStackView.heightAnchor.constraint(equalToConstant: 32),
            
            aboutTitleLabel.topAnchor.constraint(equalTo: socialStackView.bottomAnchor, constant: 20),
            aboutTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            aboutLabel.topAnchor.constraint(equalTo: aboutTitleLabel.bottomAnchor, constant: 8),
            aboutLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            aboutLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            aboutLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with data: PortfolioData) {
        nameLabel.text = data.name
        roleLabel.text = data.role
        aboutLabel.text = data.about
        profileImageView.image = UIImage(named: "profile_image") // Replace with actual image name
    }
}
