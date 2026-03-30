//
//  SearchResultCell.swift
//  CineMystApp
//
//  Created by user@50 on 12/11/25.
//

import UIKit

final class SearchResultCell: UITableViewCell {
    
    private let icon = UIImageView(image: UIImage(systemName: "person.circle.fill"))
    private let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        icon.tintColor = .systemGray
        icon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(icon)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: icon.centerYAnchor)
        ])
    }
    
    func configure(with text: String) {
        titleLabel.text = text
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
}
