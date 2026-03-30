//
//  PostCellTableViewCell.swift
//  CineMystApp
//
//  Updated to work with real Post model from database
//

import UIKit

final class PostCellTableViewCell: UITableViewCell {
    
    static let reuseId = "PostCellTableViewCell"
    
    // MARK: - UI Components
    private let avatar = UIImageView()
    private let usernameLabel = UILabel()
    private let timeLabel = UILabel()
    private let captionLabel = UILabel()
    private let postImage = UIImageView()
    
    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    
    private let likeCountLabel = UILabel()
    private let commentCountLabel = UILabel()
    private let shareCountLabel = UILabel()
    
    // MARK: - State
    private var isLiked = false
    private var post: Post?
    
    // MARK: - Callbacks
    var commentTapped: (() -> Void)?
    var shareTapped: (() -> Void)?
    var profileTapped: (() -> Void)?
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Avatar setup
        avatar.layer.cornerRadius = 20
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.isUserInteractionEnabled = true
        avatar.backgroundColor = .systemGray5
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAvatar))
        avatar.addGestureRecognizer(tap)
        
        // Labels
        usernameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .secondaryLabel
        
        captionLabel.font = .systemFont(ofSize: 14)
        captionLabel.numberOfLines = 0
        
        // Post image
        postImage.layer.cornerRadius = 12
        postImage.contentMode = .scaleAspectFill
        postImage.clipsToBounds = true
        postImage.backgroundColor = .systemGray6
        
        // Buttons
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .label
        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        
        commentButton.setImage(UIImage(systemName: "bubble.right"), for: .normal)
        commentButton.tintColor = .label
        commentButton.addTarget(self, action: #selector(didTapComment), for: .touchUpInside)
        
        shareButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward"), for: .normal)
        shareButton.tintColor = .label
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        
        [likeCountLabel, commentCountLabel, shareCountLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
        }
    }

    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [
            likeButton, likeCountLabel,
            commentButton, commentCountLabel,
            shareButton, shareCountLabel
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        
        [avatar, usernameLabel, timeLabel, captionLabel, postImage, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 40),
            avatar.heightAnchor.constraint(equalToConstant: 40),
            
            usernameLabel.topAnchor.constraint(equalTo: avatar.topAnchor, constant: 2),
            usernameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            captionLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 12),
            captionLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            
            postImage.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 10),
            postImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            postImage.heightAnchor.constraint(equalToConstant: 300),
            
            stack.topAnchor.constraint(equalTo: postImage.bottomAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configure
    func configure(with post: Post) {
        self.post = post
        
        // Set username
        usernameLabel.text = post.username
        
        // Set time ago
        timeLabel.text = post.timeAgo
        
        // Set caption (or hide if empty)
        if let caption = post.caption, !caption.isEmpty {
            captionLabel.text = caption
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }
        
        // Load user profile picture
        if let urlString = post.userProfilePictureUrl,
           let url = URL(string: urlString) {
            loadImage(from: url, into: avatar)
        } else {
            avatar.image = UIImage(systemName: "person.circle.fill")
            avatar.tintColor = .secondaryLabel
        }
        
        // Load post image (first media item)
        if let firstMedia = post.mediaUrls.first,
           let url = URL(string: firstMedia.url) {
            postImage.isHidden = false
            loadImage(from: url, into: postImage)
        } else {
            // No media - hide image view and adjust layout
            postImage.isHidden = true
        }
        
        // Set stats
        likeCountLabel.text = "\(post.likesCount)"
        commentCountLabel.text = "\(post.commentsCount)"
        shareCountLabel.text = "\(post.sharesCount)"
        
        // Reset like state
        isLiked = false
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .label
    }
    
    // MARK: - Image Loading
    private func loadImage(from url: URL, into imageView: UIImageView) {
        // Cancel any existing image load
        imageView.image = nil
        
        URLSession.shared.dataTask(with: url) { [weak imageView] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  let imageView = imageView else {
                return
            }
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Button Actions
    @objc private func didTapLike() {
        guard let post = post else { return }
        
        isLiked.toggle()
        
        let heartImage = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        likeButton.setImage(heartImage, for: .normal)
        likeButton.tintColor = isLiked ? UIColor.systemRed : UIColor.label
        
        let currentLikes = Int(likeCountLabel.text ?? "\(post.likesCount)") ?? post.likesCount
        let updatedLikes = isLiked ? currentLikes + 1 : currentLikes - 1
        likeCountLabel.text = "\(updatedLikes)"
        
        // Animate the like button
        UIView.animate(withDuration: 0.1,
                       animations: {
                           self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                       }, completion: { _ in
                           UIView.animate(withDuration: 0.1) {
                               self.likeButton.transform = .identity
                           }
                       })
        
        // Call API to like/unlike post
        Task {
            do {
                if isLiked {
                    try await PostManager.shared.likePost(postId: post.id)
                } else {
                    try await PostManager.shared.unlikePost(postId: post.id)
                }
            } catch {
                print("❌ Error updating like: \(error)")
                // Revert UI on error
                await MainActor.run {
                    isLiked.toggle()
                    let revertedImage = UIImage(systemName: isLiked ? "heart.fill" : "heart")
                    likeButton.setImage(revertedImage, for: .normal)
                    likeButton.tintColor = isLiked ? UIColor.systemRed : UIColor.label
                    likeCountLabel.text = "\(currentLikes)"
                }
            }
        }
    }
    
    @objc private func didTapComment() {
        commentTapped?()
    }

    @objc private func didTapShare() {
        shareTapped?()
    }
    
    @objc private func didTapAvatar() {
        profileTapped?()
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        avatar.image = nil
        postImage.image = nil
        usernameLabel.text = nil
        timeLabel.text = nil
        captionLabel.text = nil
        isLiked = false
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .label
    }
}
