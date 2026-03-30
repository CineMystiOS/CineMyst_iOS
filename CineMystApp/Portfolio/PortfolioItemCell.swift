//
//  PortfolioItemCell.swift
//  CineMystApp
//
//  Created by user@50 on 23/01/26.
//


// Create: Views/Cells/PortfolioItemCell.swift

import UIKit

class PortfolioItemCell: UITableViewCell {
    
    private let yearLabel = UILabel()
    private let roleLabel = UILabel()
    private let productionLabel = UILabel()
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let genreLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .black
        
        // Year
        yearLabel.font = .systemFont(ofSize: 32, weight: .bold)
        yearLabel.textColor = .white
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yearLabel)
        
        // Role
        roleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        roleLabel.textColor = UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Production
        productionLabel.font = .systemFont(ofSize: 13)
        productionLabel.textColor = .lightGray
        productionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(productionLabel)
        
        // Poster Images Stack
        let imageStack = UIStackView()
        imageStack.axis = .horizontal
        imageStack.spacing = 8
        imageStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageStack)
        
        // Title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Genre
        genreLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        genreLabel.textColor = .lightGray
        genreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(genreLabel)
        
        // Description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            yearLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            yearLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            roleLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 8),
            roleLabel.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            
            productionLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 4),
            productionLabel.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            
            imageStack.topAnchor.constraint(equalTo: productionLabel.bottomAnchor, constant: 16),
            imageStack.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            imageStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageStack.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: imageStack.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            
            genreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            genreLabel.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: genreLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: yearLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    func configure(with item: PortfolioItem) {
        yearLabel.text = "\(item.year)"
        roleLabel.text = "Role: \(item.role ?? "N/A")"
        productionLabel.text = item.productionCompany ?? item.organization ?? ""
        titleLabel.text = item.title
        genreLabel.text = "\(item.genre ?? "FILM") | \(item.durationText)"
        descriptionLabel.text = item.description
        
        // Load poster image if available
        if let posterUrlString = item.posterUrl, let url = URL(string: posterUrlString) {
            loadImage(from: url)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    // Add to image stack
                }
            }
        }.resume()
    }
}
