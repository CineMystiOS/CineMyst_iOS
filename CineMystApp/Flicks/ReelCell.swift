//
//  ReelCell.swift
//  CineMystApp
//
//  Updated to match Instagram Reels design
//  Second pass: fixed bottom alignment and safe-area issues
//  Third pass: removed the top-right share icon that overlapped the "Snaps" title
//  Fourth pass: wired the "more" (ellipsis) button to notify the delegate so the
//  containing view controller can present an action sheet with Save / Interested / Not Interested / Report
//

import UIKit
import AVFoundation

// MARK: - Delegate Protocol
protocol ReelCellDelegate: AnyObject {
    func didTapComment(on cell: ReelCell)
    func didTapShare(on cell: ReelCell)
    /// Called when the user taps the "more" (ellipsis) button. The sourceView can be used
    /// by the presenter for popover anchoring on iPad.
    func didTapMore(on cell: ReelCell, sourceView: UIView)
    func didTapProfile(on cell: ReelCell, userId: String)
}

final class ReelCell: UICollectionViewCell {
    
    static let identifier = "ReelCell"
    
    // Delegates for button actions
    weak var delegate: ReelCellDelegate?
    
    // State
    private var isLiked = false
    private var currentFlickId: String?
    private var currentUserId: String?
    
    // Video player
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    // Small layout tune constants
    private enum Layout {
        static let rightStackBottom: CGFloat = -20   // move icons up from safe area
        static let bottomInfoBottom: CGFloat = -20    // bottom-left info baseline above tab bar
        static let musicDiscBottom: CGFloat = -90
        static let horizontalMargin: CGFloat = 12
    }
    
    // UI Elements
    private let playIconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 120, weight: .ultraLight)
        iv.image = UIImage(systemName: "play.fill", withConfiguration: cfg)
        iv.tintColor = UIColor(white: 1, alpha: 0.85)
        iv.contentMode = .center
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    // Top bar
    private let topBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let snapsLabel: UILabel = {
        let l = UILabel()
        l.text = "Snaps"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let dropdownIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Right action stack
    private let actionStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .trailing
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let likeButton = ReelCell.actionButton(systemName: "heart.fill", value: "253K")
    private let commentButton = ReelCell.actionButton(systemName: "message", value: "1,139")
    private let shareButton = ReelCell.actionButton(systemName: "paperplane", value: "29")
    private let moreButton = ReelCell.actionButton(systemName: "ellipsis", value: "")
    
    // Music disc at bottom of action stack
    private let musicDiscView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .darkGray
        return iv
    }()
    
    // Bottom info section
    private let bottomInfoContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 18
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 1.5
        iv.layer.borderColor = UIColor.white.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .darkGray
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = .white
        l.isUserInteractionEnabled = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let connectButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Follow", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .clear
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        b.layer.cornerRadius = 6
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.white.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let captionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let likedByLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let audioContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.3)
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let audioIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "music.note")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let audioLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let giftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "gift")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let sendGiftLabel: UILabel = {
        let l = UILabel()
        l.text = "Send gift"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let musicThumb: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 5
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .darkGray
        return iv
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Use contentView bounds for full coverage
        playerLayer?.frame = contentView.bounds
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = .black
        
        // Play icon
        contentView.addSubview(playIconView)
        
        // Top bar
        contentView.addSubview(topBar)
        topBar.addSubview(snapsLabel)
        topBar.addSubview(dropdownIcon)
        // NOTE: removed the top-right share icon to prevent overlap with other UI elements
        
        // Action stack
        contentView.addSubview(actionStack)
        actionStack.addArrangedSubview(likeButton)
        actionStack.addArrangedSubview(commentButton)
        actionStack.addArrangedSubview(shareButton)
        actionStack.addArrangedSubview(moreButton)
        
        // Bottom info
        contentView.addSubview(bottomInfoContainer)
        bottomInfoContainer.addSubview(avatarImageView)
        bottomInfoContainer.addSubview(nameLabel)
        bottomInfoContainer.addSubview(connectButton)
        bottomInfoContainer.addSubview(captionLabel)
        bottomInfoContainer.addSubview(likedByLabel)
        bottomInfoContainer.addSubview(audioContainer)
        
        audioContainer.addSubview(audioIcon)
        audioContainer.addSubview(audioLabel)
        audioContainer.addSubview(giftIcon)
        audioContainer.addSubview(sendGiftLabel)
        audioContainer.addSubview(musicThumb)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // ensure autoresizing masks are off
        [playIconView, topBar, snapsLabel, dropdownIcon, actionStack, musicDiscView,
         bottomInfoContainer, avatarImageView, nameLabel, connectButton, captionLabel, likedByLabel,
         audioContainer, audioIcon, audioLabel, giftIcon, sendGiftLabel, musicThumb]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            // Play icon
            playIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 150),
            playIconView.heightAnchor.constraint(equalToConstant: 150),
            
            // Top bar - now that we respect safe area, reduce the offset
            topBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            topBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),
            
            snapsLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            snapsLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            dropdownIcon.leadingAnchor.constraint(equalTo: snapsLabel.trailingAnchor, constant: 8),
            dropdownIcon.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            dropdownIcon.widthAnchor.constraint(equalToConstant: 16),
            dropdownIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Action stack pinned to bottom-right (flush with right edge)
            actionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionStack.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            
            // Bottom info container pinned to bottom-left and raised above the tab bar
            bottomInfoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            bottomInfoContainer.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -12),
            bottomInfoContainer.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: Layout.bottomInfoBottom),
            
            // Avatar & name
            avatarImageView.leadingAnchor.constraint(equalTo: bottomInfoContainer.leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: bottomInfoContainer.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            
            // connect button should not push out of container: allow it to compress if needed
            connectButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            connectButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            connectButton.heightAnchor.constraint(equalToConstant: 26),
            connectButton.trailingAnchor.constraint(lessThanOrEqualTo: bottomInfoContainer.trailingAnchor),
            
            // Caption
            captionLabel.leadingAnchor.constraint(equalTo: bottomInfoContainer.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: bottomInfoContainer.trailingAnchor),
            captionLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            
            // Liked by
            likedByLabel.leadingAnchor.constraint(equalTo: bottomInfoContainer.leadingAnchor),
            likedByLabel.trailingAnchor.constraint(equalTo: bottomInfoContainer.trailingAnchor),
            likedByLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 6),
            
            // Audio container
            audioContainer.leadingAnchor.constraint(equalTo: bottomInfoContainer.leadingAnchor),
            audioContainer.trailingAnchor.constraint(lessThanOrEqualTo: bottomInfoContainer.trailingAnchor),
            audioContainer.topAnchor.constraint(equalTo: likedByLabel.bottomAnchor, constant: 8),
            audioContainer.bottomAnchor.constraint(equalTo: bottomInfoContainer.bottomAnchor),
            audioContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // Audio icon
            audioIcon.leadingAnchor.constraint(equalTo: audioContainer.leadingAnchor, constant: 10),
            audioIcon.centerYAnchor.constraint(equalTo: audioContainer.centerYAnchor),
            audioIcon.widthAnchor.constraint(equalToConstant: 16),
            audioIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Audio label
            audioLabel.leadingAnchor.constraint(equalTo: audioIcon.trailingAnchor, constant: 6),
            audioLabel.centerYAnchor.constraint(equalTo: audioContainer.centerYAnchor),
            
            // Gift icon
            giftIcon.leadingAnchor.constraint(equalTo: audioLabel.trailingAnchor, constant: 16),
            giftIcon.centerYAnchor.constraint(equalTo: audioContainer.centerYAnchor),
            giftIcon.widthAnchor.constraint(equalToConstant: 16),
            giftIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Send gift label
            sendGiftLabel.leadingAnchor.constraint(equalTo: giftIcon.trailingAnchor, constant: 6),
            sendGiftLabel.centerYAnchor.constraint(equalTo: audioContainer.centerYAnchor),
            
            // Music thumb
            musicThumb.leadingAnchor.constraint(equalTo: sendGiftLabel.trailingAnchor, constant: 12),
            musicThumb.trailingAnchor.constraint(equalTo: audioContainer.trailingAnchor, constant: -8),
            musicThumb.centerYAnchor.constraint(equalTo: audioContainer.centerYAnchor),
            musicThumb.widthAnchor.constraint(equalToConstant: 28),
            musicThumb.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // prevent "Connect" from growing past the available space
        connectButton.setContentCompressionResistancePriority(.required, for: .vertical)
        connectButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
        
        // Add tap gesture to name label for profile navigation
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(handleNameTap))
        nameLabel.addGestureRecognizer(nameTap)
        
        // Add tap gesture to avatar for profile navigation
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleNameTap))
        avatarImageView.addGestureRecognizer(avatarTap)
        
        // Add action to follow button
        connectButton.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        
        // Add button actions
        if let likeBtn = likeButton.arrangedSubviews.first as? UIButton {
            likeBtn.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        }
        if let commentBtn = commentButton.arrangedSubviews.first as? UIButton {
            commentBtn.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        }
        if let shareBtn = shareButton.arrangedSubviews.first as? UIButton {
            shareBtn.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        }
        // Wire the more (ellipsis) button to notify delegate so the VC can present an action sheet
        if let moreBtn = moreButton.arrangedSubviews.first as? UIButton {
            moreBtn.addTarget(self, action: #selector(handleMore(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func handleNameTap() {
        guard let userId = currentUserId else { return }
        delegate?.didTapProfile(on: self, userId: userId)
    }
    
    @objc private func handleFollow() {
        connectButton.setTitle("Request sent", for: .normal)
        connectButton.isEnabled = false
        connectButton.alpha = 0.7
    }
    
    @objc private func handleTap() {
        togglePlayPause()
    }
    
    @objc private func handleLike() {
        // Prevent double taps
        guard let likeBtn = likeButton.arrangedSubviews.first as? UIButton else { return }
        likeBtn.isEnabled = false
        
        // Optimistic UI update
        isLiked.toggle()
        
        // Animate
        UIView.animate(withDuration: 0.1, animations: {
            likeBtn.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                likeBtn.transform = .identity
            }
        }
        
        updateLikeButtonAppearance()
        
        // Update like count
        if let likeLabel = likeButton.arrangedSubviews.last as? UILabel,
           let currentCount = Int(likeLabel.text?.replacingOccurrences(of: "K", with: "000").replacingOccurrences(of: "M", with: "000000") ?? "0") {
            let newCount = isLiked ? currentCount + 1 : max(0, currentCount - 1)
            likeLabel.text = formatLikeCount(newCount)
        }
        
        // Call API
        Task {
            do {
                guard let flickId = currentFlickId else {
                    likeBtn.isEnabled = true
                    return
                }
                
                if isLiked {
                    try await FlicksService.shared.likeFlick(flickId: flickId)
                } else {
                    try await FlicksService.shared.unlikeFlick(flickId: flickId)
                }
                
                await MainActor.run {
                    likeBtn.isEnabled = true
                }
            } catch {
                print("❌ Failed to toggle like: \(error)")
                // Revert on error
                await MainActor.run {
                    self.isLiked.toggle()
                    self.updateLikeButtonAppearance()
                    likeBtn.isEnabled = true
                }
            }
        }
    }
    
    private func formatLikeCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    @objc private func handleComment() {
        delegate?.didTapComment(on: self)
    }
    
    @objc private func handleShare() {
        delegate?.didTapShare(on: self)
    }
    
    @objc private func handleMore(_ sender: UIButton) {
        // Forward to delegate. The delegate (usually the view controller) should present
        // a UIAlertController.actionSheet anchored to `sender` for iPad compatibility.
        delegate?.didTapMore(on: self, sourceView: sender)
    }
    
    // MARK: - Configuration
    func configure(with reel: Reel) {
        currentFlickId = reel.id
        currentUserId = reel.userId
        nameLabel.text = reel.authorName
        musicThumb.image = reel.authorAvatar
        musicDiscView.image = reel.authorAvatar
        audioLabel.text = reel.audioTitle
        captionLabel.text = reel.caption ?? "Check this out!"
        isLiked = reel.isLiked
        
        // Load avatar from URL if available
        if let avatarURL = reel.authorAvatarURL, let url = URL(string: avatarURL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.avatarImageView.image = image
                            self.musicThumb.image = image
                            self.musicDiscView.image = image
                        }
                    }
                } catch {
                    // Use placeholder if download fails
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                }
            }
        } else {
            avatarImageView.image = reel.authorAvatar ?? UIImage(systemName: "person.circle.fill")
        }
        
        // Show actual like count
        if reel.likes == "0" {
            likedByLabel.text = "Be the first to like this"
        } else {
            likedByLabel.text = "Liked by \(reel.likes) people"
        }
        
        if let likeLabel = likeButton.arrangedSubviews.last as? UILabel {
            likeLabel.text = reel.likes
        }
        if let commentLabel = commentButton.arrangedSubviews.last as? UILabel {
            commentLabel.text = reel.comments
        }
        if let shareLabel = shareButton.arrangedSubviews.last as? UILabel {
            shareLabel.text = reel.shares
        }
        
        // Update like button appearance
        updateLikeButtonAppearance()
        
        setupVideoPlayer(with: reel.videoURL)
    }
    
    // MARK: - Video Player
    private func setupVideoPlayer(with videoString: String) {
        cleanupPlayer()
        
        var videoURL: URL?
        
        // Check if it's a remote URL or local file
        if videoString.hasPrefix("http") {
            videoURL = URL(string: videoString)
        } else {
            videoURL = Bundle.main.url(forResource: videoString, withExtension: "mp4")
        }
        
        guard let url = videoURL else {
            print("❌ Video not found: \(videoString)")
            return
        }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer?.isMuted = false
        queuePlayer?.volume = 1.0
        
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = contentView.bounds
        
        if let playerLayer = playerLayer {
            contentView.layer.insertSublayer(playerLayer, at: 0)
        }
    }
    
    func play() {
        queuePlayer?.play()
        queuePlayer?.isMuted = false
        queuePlayer?.volume = 1.0
        playIconView.isHidden = true
    }
    
    func pause() {
        queuePlayer?.pause()
        playIconView.isHidden = false
    }
    
    func updateLikeStatus(isLiked: Bool) {
        self.isLiked = isLiked
        updateLikeButtonAppearance()
    }
    
    private func updateLikeButtonAppearance() {
        if let likeStackView = likeButton as? UIStackView,
           let button = likeStackView.arrangedSubviews.first as? UIButton {
            let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
            let imageName = isLiked ? "heart.fill" : "heart"
            button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            button.tintColor = isLiked ? .systemRed : .white
        }
    }
    
    private func togglePlayPause() {
        guard let player = queuePlayer else { return }
        
        if player.rate > 0 {
            pause()
        } else {
            play()
        }
    }
    
    private func cleanupPlayer() {
        queuePlayer?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        queuePlayer = nil
        playerLooper = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanupPlayer()
    }
    
    deinit {
        cleanupPlayer()
    }
    
    // MARK: - Helper
    private static func actionButton(systemName: String, value: String) -> UIStackView {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .thin)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let lbl = UILabel()
        lbl.text = value
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        let sv = UIStackView(arrangedSubviews: [btn, lbl])
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 2
        return sv
    }
}

