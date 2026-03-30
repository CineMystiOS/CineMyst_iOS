//
//  CommentCell.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//



import UIKit

final class CommentCell: UITableViewCell {
    static let reuseId = "CommentCell"
    
    private let userImage = UIImageView()
    private let usernameLabel = UILabel()
    private let commentLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        userImage.layer.cornerRadius = 18
        userImage.clipsToBounds = true
        userImage.contentMode = .scaleAspectFill
        
        usernameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        commentLabel.font = .systemFont(ofSize: 14)
        commentLabel.textColor = .label
        commentLabel.numberOfLines = 0
    }
    
    private func layoutUI() {
        [userImage, usernameLabel, commentLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            userImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            userImage.widthAnchor.constraint(equalToConstant: 36),
            userImage.heightAnchor.constraint(equalToConstant: 36),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: 12),
            usernameLabel.topAnchor.constraint(equalTo: userImage.topAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            commentLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            commentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with comment: Comment) {
        userImage.image = UIImage(named: comment.userImage)
        usernameLabel.text = comment.username
        commentLabel.text = comment.text
    }
}
