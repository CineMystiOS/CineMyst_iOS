//
//  ReelCell.swift
//  CineMystApp
//
//  Cinematic redesign — deep plum + rose gradient aesthetic, spring animations

import UIKit
import AVFoundation

// MARK: - Delegate

protocol ReelCellDelegate: AnyObject {
    func didTapComment(on cell: ReelCell)
    func didTapShare(on cell: ReelCell)
    func didTapMore(on cell: ReelCell, sourceView: UIView)
    func didTapProfile(on cell: ReelCell, userId: String)
}

// MARK: - ReelCell

final class ReelCell: UICollectionViewCell {

    static let identifier = "ReelCell"
    weak var delegate: ReelCellDelegate?

    // MARK: State
    private var isLiked        = false
    private var currentLikes   = 0
    private var currentFlickId: String?
    private var currentUserId:  String?
    private var isFollowing     = false
    private var isOwnContent    = false

    // MARK: Player
    private var playerLayer:  AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer:  AVQueuePlayer?

    // MARK: - Design tokens
    private enum DS {
        static let plum  = UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1)
        static let rose  = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1)
        static let red   = UIColor(red: 1, green: 0.27, blue: 0.36, alpha: 1)
    }

    // MARK: - Video Layer
    // inserted at 0 in contentView.layer

    // MARK: - Gradient Overlay (bottom)
    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor,
            UIColor.black.withAlphaComponent(0.88).cgColor,
        ]
        g.locations = [0, 0.4, 0.75, 1]
        return g
    }()

    // MARK: - Play Icon
    private let playIconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 64, weight: .ultraLight)
        iv.image = UIImage(systemName: "play.fill", withConfiguration: cfg)
        iv.tintColor = UIColor.white.withAlphaComponent(0.85)
        iv.contentMode = .center
        iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Right Action Stack
    private let actionStack: UIStackView = {
        let sv = UIStackView()
        sv.axis      = .vertical
        sv.alignment = .center
        sv.spacing   = 18
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var likeStack      = makeActionItem(icon: "heart",        tint: .white)
    private lazy var commentStack   = makeActionItem(icon: "bubble.right", tint: .white)
    private lazy var shareStack     = makeActionItem(icon: "paperplane",   tint: .white, hideLabel: true)

    // MARK: - Bottom Info
    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.layer.borderWidth  = 1.5
        iv.layer.borderColor  = UIColor.white.cgColor
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(white: 0.3, alpha: 1)
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
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

    private let followButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Follow", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        b.layer.cornerRadius = 14
        b.layer.borderWidth  = 1.5
        b.layer.borderColor  = UIColor.white.cgColor
        b.contentEdgeInsets  = UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14)
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

    private let likeCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let audioRow: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let audioIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "music.note"))
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

    // MARK: - Double-tap heart burst
    private let heartBurst: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "heart.fill"))
        iv.tintColor = UIColor(red: 1, green: 0.27, blue: 0.36, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame  = contentView.bounds
        gradientLayer.frame = contentView.bounds
    }

    // MARK: - Setup Views

    private func setupViews() {
        contentView.backgroundColor = .black
        contentView.layer.addSublayer(gradientLayer)

        contentView.addSubview(playIconView)
        contentView.addSubview(heartBurst)
        contentView.addSubview(actionStack)

        // Action stack — 2 buttons (Like, Comment)
        actionStack.addArrangedSubview(likeStack)
        actionStack.addArrangedSubview(commentStack)
        
        // Share stack stands alone now
        contentView.addSubview(shareStack)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(followButton)
        contentView.addSubview(captionLabel)
        contentView.addSubview(likeCountLabel)
        contentView.addSubview(audioRow)
        audioRow.addSubview(audioIcon)
        audioRow.addSubview(audioLabel)

        // Tab bar ≈ 83pt (49 bar + 34 safe area on Face ID) + buffer = 130
        let tabOffset: CGFloat = 96

        NSLayoutConstraint.activate([
            // Play icon — centred
            playIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 100),
            playIconView.heightAnchor.constraint(equalToConstant: 100),

            // Heart burst — centred
            heartBurst.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            heartBurst.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            heartBurst.widthAnchor.constraint(equalToConstant: 90),
            heartBurst.heightAnchor.constraint(equalToConstant: 90),

            // Action stack pinned to right edge, above tab bar
            actionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(tabOffset + 95)),

            // Share stack pinned to top right
            shareStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            shareStack.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),

            // Audio row — bottom left, above tab bar
            audioRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            audioRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -tabOffset),
            audioRow.heightAnchor.constraint(equalToConstant: 34),
            audioRow.trailingAnchor.constraint(lessThanOrEqualTo: actionStack.leadingAnchor, constant: -16),

            audioIcon.leadingAnchor.constraint(equalTo: audioRow.leadingAnchor, constant: 10),
            audioIcon.centerYAnchor.constraint(equalTo: audioRow.centerYAnchor),
            audioIcon.widthAnchor.constraint(equalToConstant: 14),
            audioIcon.heightAnchor.constraint(equalToConstant: 14),
            audioLabel.leadingAnchor.constraint(equalTo: audioIcon.trailingAnchor, constant: 6),
            audioLabel.centerYAnchor.constraint(equalTo: audioRow.centerYAnchor),
            audioLabel.trailingAnchor.constraint(equalTo: audioRow.trailingAnchor, constant: -10),

            // Like count label
            likeCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            likeCountLabel.bottomAnchor.constraint(equalTo: audioRow.topAnchor, constant: -8),
            likeCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionStack.leadingAnchor, constant: -16),

            // Caption
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            captionLabel.bottomAnchor.constraint(equalTo: likeCountLabel.topAnchor, constant: -6),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionStack.leadingAnchor, constant: -16),

            // Avatar
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            avatarView.bottomAnchor.constraint(equalTo: captionLabel.topAnchor, constant: -12),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            // Follow button
            followButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            followButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            followButton.trailingAnchor.constraint(lessThanOrEqualTo: actionStack.leadingAnchor, constant: -16),
            followButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }


    // MARK: - Gestures

    private func setupGestures() {
        // Double-tap to like
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)

        // Single tap to play/pause
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(singleTap)

        let profileTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        avatarView.addGestureRecognizer(profileTap)
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        nameLabel.addGestureRecognizer(nameTap)

        followButton.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)

        // Wire action buttons
        actionButton(in: likeStack)?.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        actionButton(in: commentStack)?.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        actionButton(in: shareStack)?.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
    }

    private func actionButton(in stack: UIStackView) -> UIButton? {
        stack.arrangedSubviews.first as? UIButton
    }
    private func actionLabel(in stack: UIStackView) -> UILabel? {
        stack.arrangedSubviews.last as? UILabel
    }

    // MARK: - Actions

    @objc private func handleSingleTap() { togglePlayPause() }

    @objc private func handleDoubleTap() {
        if !isLiked { 
            performLike()
        }
        showHeartBurst()
    }

    @objc private func handleProfileTap() {
        guard let uid = currentUserId else { return }
        delegate?.didTapProfile(on: self, userId: uid)
    }

    @objc private func handleFollow() {
        guard !isOwnContent else { return }
        isFollowing.toggle()
        animateFollowButton()
        persistFollowState()
    }

    @objc private func handleLike() {
        performLike()
    }

    @objc private func handleComment() {
        delegate?.didTapComment(on: self)
    }

    @objc private func handleShare() {
        delegate?.didTapShare(on: self)
    }

    @objc private func handleMore(_ sender: UIButton) {
        delegate?.didTapMore(on: self, sourceView: sender)
    }

    // MARK: - Like Logic

    private func performLike() {
        guard let flickId = currentFlickId else { return }
        let btn = actionButton(in: likeStack)
        btn?.isEnabled = false

        isLiked.toggle()
        currentLikes += isLiked ? 1 : -1
        if currentLikes < 0 { currentLikes = 0 }

        refreshLikeUI(animated: true)

        Task {
            do {
                if isLiked {
                    try await FlicksService.shared.likeFlick(flickId: flickId)
                } else {
                    try await FlicksService.shared.unlikeFlick(flickId: flickId)
                }
            } catch {
                // Revert
                self.isLiked.toggle()
                self.currentLikes += self.isLiked ? 1 : -1
                self.refreshLikeUI(animated: false)
            }
            btn?.isEnabled = true
        }
    }

    private func refreshLikeUI(animated: Bool) {
        let btn = actionButton(in: likeStack)
        let lbl = actionLabel(in: likeStack)

        let cfg   = UIImage.SymbolConfiguration(pointSize: 20, weight: isLiked ? .regular : .thin)
        let name  = isLiked ? "heart.fill" : "heart"
        let color = isLiked ? DS.red : UIColor.white

        btn?.setImage(UIImage(systemName: name, withConfiguration: cfg), for: .normal)
        lbl?.text = formatCount(currentLikes)

        if animated {
            UIView.animate(withDuration: 0.12, animations: {
                btn?.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                btn?.tintColor = color
            }) { _ in
                UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 8) {
                    btn?.transform = .identity
                }
            }
        } else {
            btn?.tintColor = color
        }

        likeCountLabel.text = currentLikes == 0 ? "Be the first to like" : "❤️ \(formatCount(currentLikes)) likes"
    }

    // MARK: - Heart Burst Animation

    private func showHeartBurst() {
        heartBurst.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        heartBurst.alpha     = 0

        UIView.animate(withDuration: 0.3, delay: 0,
                       usingSpringWithDamping: 0.5, initialSpringVelocity: 10,
                       options: .allowUserInteraction) {
            self.heartBurst.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.heartBurst.alpha     = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 0.3) {
                self.heartBurst.alpha     = 0
                self.heartBurst.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
            }
        }
    }

    // MARK: - Follow Logic

    private func animateFollowButton() {
        if isFollowing {
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = DS.plum
            followButton.layer.borderColor = DS.plum.cgColor
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = .clear
            followButton.layer.borderColor = UIColor.white.cgColor
        }

        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 8) {
            self.followButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.followButton.transform = .identity
            }
        }
    }

    private func persistFollowState() {
        guard let receiverId = currentUserId else { return }
        Task {
            do {
                if isFollowing {
                    try await ConnectionService.shared.sendRequest(to: receiverId)
                } else {
                    try await ConnectionService.shared.cancelRequest(to: receiverId)
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    self.isFollowing.toggle()
                    self.animateFollowButton()
                }
                print("❌ Follow action failed: \(error)")
            }
        }
    }

    // MARK: - Configure

    func configure(with reel: Reel) {
        currentFlickId = reel.id
        currentUserId  = reel.userId
        isLiked        = reel.isLiked
        currentLikes   = Int(reel.likes) ?? 0

        nameLabel.text  = reel.authorName
        captionLabel.text = reel.caption?.isEmpty == false ? reel.caption : ""
        audioLabel.text = reel.audioTitle

        actionLabel(in: commentStack)?.text = reel.comments
        actionLabel(in: shareStack)?.text   = reel.shares

        likeCountLabel.text = currentLikes == 0 ? "Be the first to like" : "❤️ \(reel.likes) likes"
        refreshLikeUI(animated: false)

        // Check if own content (hide follow button)
        Task {
            if let session = try? await supabase.auth.session {
                let isMine = session.user.id.uuidString == reel.userId
                await MainActor.run {
                    self.isOwnContent = isMine
                    self.followButton.isHidden = isMine
                }
            }
        }

        // Avatar only — disc no longer shows profile photo
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = UIColor(white: 0.5, alpha: 1)

        if let avatarURL = reel.authorAvatarURL, let url = URL(string: avatarURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.avatarView.image = img
                }
            }.resume()
        }

        setupVideoPlayer(with: reel.videoURL)
    }

    func updateLikeStatus(isLiked: Bool) {
        self.isLiked = isLiked
        refreshLikeUI(animated: false)
    }

    // MARK: - Video

    private func setupVideoPlayer(with videoString: String) {
        cleanupPlayer()
        guard let url = videoString.hasPrefix("http") ? URL(string: videoString)
                        : Bundle.main.url(forResource: videoString, withExtension: "mp4")
        else { return }

        let item = AVPlayerItem(asset: AVAsset(url: url))
        queuePlayer  = AVQueuePlayer(playerItem: item)
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: item)
        playerLayer  = AVPlayerLayer(player: queuePlayer)
        playerLayer!.videoGravity = .resizeAspectFill
        playerLayer!.frame = contentView.bounds
        contentView.layer.insertSublayer(playerLayer!, at: 0)
        // Re-add gradient on top of player
        if gradientLayer.superlayer == nil {
            contentView.layer.addSublayer(gradientLayer)
        }
    }

    func play() {
        queuePlayer?.isMuted = false
        queuePlayer?.volume  = 1
        queuePlayer?.play()
        UIView.animate(withDuration: 0.2) { self.playIconView.alpha = 0 }
    }

    func pause() {
        queuePlayer?.pause()
        UIView.animate(withDuration: 0.2) { self.playIconView.alpha = 1 }
    }

    private func togglePlayPause() {
        guard let p = queuePlayer else { return }
        if p.rate > 0 { pause() } else { play() }
    }

    private func cleanupPlayer() {
        queuePlayer?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer  = nil
        queuePlayer  = nil
        playerLooper = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cleanupPlayer()
        avatarView.image   = nil
        nameLabel.text     = nil
        captionLabel.text  = nil
        isFollowing        = false
        followButton.setTitle("Follow", for: .normal)
        followButton.backgroundColor       = .clear
        followButton.layer.borderColor     = UIColor.white.cgColor
        followButton.isHidden = false
    }

    deinit { cleanupPlayer() }

    // MARK: - Helpers

    private func formatCount(_ n: Int) -> String {
        switch n {
        case 0..<1000:    return "\(n)"
        case 0..<1000000: return String(format: "%.1fK", Double(n)/1000)
        default:           return String(format: "%.1fM", Double(n)/1_000_000)
        }
    }

    private func makeActionItem(icon: String, tint: UIColor, hideLabel: Bool = false) -> UIStackView {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        btn.setImage(UIImage(systemName: icon, withConfiguration: cfg), for: .normal)
        btn.tintColor = tint
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let lbl = UILabel()
        lbl.text      = "0"
        lbl.font      = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.isHidden  = hideLabel

        let sv = UIStackView(arrangedSubviews: [btn, lbl])
        sv.axis      = .vertical
        sv.alignment = .center
        sv.spacing   = 2
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }
}
