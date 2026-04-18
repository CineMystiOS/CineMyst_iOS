//
//  FlickComposerViewController.swift
//  CineMystApp
//
//  Pixel-perfect Instagram-style Flick composer.
//

import UIKit
import AVFoundation
import AVKit

// MARK: - FlickComposerViewController
class FlickComposerViewController: UIViewController {

    // MARK: - Properties
    private var videoURL: URL
    private var isUploading = false
    private var selectedLocation: String?
    private var selectedUsers: [ProfileRecord] = []
    private var audienceIsEveryone = true
    private var allowComments = true
    private var captionCharLimit = 300
    private var videoDuration: Double = 0

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // -- Title
    private let pageTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Post Flick"
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // -- Media Card
    private let mediaCard = FlickCard()

    private let thumbnailView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.2, green: 0.05, blue: 0.15, alpha: 1)
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let liveBadge: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.55)
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let liveDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.96, green: 0.27, blue: 0.27, alpha: 1)
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let liveDurationLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let liveLabel: UILabel = {
        let l = UILabel()
        l.text = "LIVE"
        l.font = .systemFont(ofSize: 9, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let charCountLabel: UILabel = {
        let l = UILabel()
        l.text = "300"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .tertiaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let captionPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text = "Tell a story about this flick..."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .placeholderText
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // -- Audience Card
    private let audienceCard = FlickCard()

    private let audienceTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Audience"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let audienceValueDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let audienceValueLabel: UILabel = {
        let l = UILabel()
        l.text = "Everyone"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var everyoneButton: UIButton = makeAudienceButton(title: "Everyone", isSelected: true)
    private lazy var friendsButton: UIButton = makeAudienceButton(title: "Friends", isSelected: false)

    // -- Options Card
    private let optionsCard = FlickCard()

    private lazy var tagRow = makeOptionRow(icon: "person.2", iconBg: UIColor(red: 0.98, green: 0.91, blue: 0.95, alpha: 1), iconTint: CineMystTheme.pink, title: "Tag People", badge: nil, id: "tag")
    private lazy var locationRow = makeOptionRow(icon: "mappin.and.ellipse", iconBg: UIColor(red: 0.98, green: 0.91, blue: 0.95, alpha: 1), iconTint: CineMystTheme.pink, title: "Add Location", badge: nil, id: "location")
    private lazy var hashtagRow = makeOptionRow(icon: "number", iconBg: UIColor(red: 0.98, green: 0.91, blue: 0.95, alpha: 1), iconTint: CineMystTheme.pink, title: "Trending Hashtags", badge: "HOT", id: "hashtag")
    private lazy var commentsRow = makeToggleRow(icon: "bubble.left", iconBg: UIColor(red: 0.98, green: 0.91, blue: 0.95, alpha: 1), iconTint: CineMystTheme.pink, title: "Allow Comments")

    // -- Share Button (backed by a gradient UIView so text stays on top)
    private let shareButtonBg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 26
        v.clipsToBounds = true
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Share Flick", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 26
        btn.clipsToBounds = true
        btn.backgroundColor = .clear
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let shareGradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.40, green: 0.09, blue: 0.24, alpha: 1).cgColor,
            UIColor(red: 0.24, green: 0.05, blue: 0.14, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        return g
    }()

    private let shimmerGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        g.locations = [0, 0.5, 1]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.color = .white
        i.hidesWhenStopped = true
        i.translatesAutoresizingMaskIntoConstraints = false
        return i
    }()

    // Programmatic cancel button (always visible regardless of nav bar state)
    private let cancelBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        btn.setTitleColor(CineMystTheme.brandPlum, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "New Flick"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.96, alpha: 1)

        // Hide system nav bar — we draw our own top bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        buildTopBar()
        buildUI()
        loadVideoMeta()
        setupKeyboardDismiss()

        // Entrance animation
        contentStack.alpha = 0
        contentStack.transform = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.65, delay: 0.05,
                       usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.4, options: []) {
            self.contentStack.alpha = 1
            self.contentStack.transform = .identity
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore nav bar when going back to previous screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shareGradientLayer.frame = shareButtonBg.bounds
        shimmerGradient.frame = shareButtonBg.bounds
        startShimmer()
    }

    // MARK: - Setup
    // Top bar drawn directly on view (not nav bar) so it always shows
    private func buildTopBar() {
        view.addSubview(cancelBtn)
        view.addSubview(navTitleLabel)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            navTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            navTitleLabel.centerYAnchor.constraint(equalTo: cancelBtn.centerYAnchor)
        ])
    }

    private func buildUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: cancelBtn.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        buildPageTitle()
        buildMediaCard()
        buildAudienceCard()
        buildOptionsCard()
        buildShareButton()
    }

    private func buildPageTitle() {
        contentStack.addArrangedSubview(pageTitleLabel)
    }

    private func buildMediaCard() {
        // Thumbnail
        thumbnailView.addSubview(thumbnailImageView)
        thumbnailView.addSubview(liveBadge)

        let liveStack = UIStackView(arrangedSubviews: [liveDot, liveLabel, liveDurationLabel])
        liveStack.axis = .horizontal
        liveStack.spacing = 4
        liveStack.alignment = .center
        liveStack.translatesAutoresizingMaskIntoConstraints = false
        liveBadge.addSubview(liveStack)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),

            liveDot.widthAnchor.constraint(equalToConstant: 8),
            liveDot.heightAnchor.constraint(equalToConstant: 8),

            liveStack.topAnchor.constraint(equalTo: liveBadge.topAnchor, constant: 4),
            liveStack.leadingAnchor.constraint(equalTo: liveBadge.leadingAnchor, constant: 7),
            liveStack.trailingAnchor.constraint(equalTo: liveBadge.trailingAnchor, constant: -7),
            liveStack.bottomAnchor.constraint(equalTo: liveBadge.bottomAnchor, constant: -4),

            liveBadge.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: 6),
            liveBadge.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -6)
        ])

        // Caption area
        captionTextView.delegate = self
        captionTextView.addSubview(captionPlaceholderLabel)
        NSLayoutConstraint.activate([
            captionPlaceholderLabel.topAnchor.constraint(equalTo: captionTextView.topAnchor),
            captionPlaceholderLabel.leadingAnchor.constraint(equalTo: captionTextView.leadingAnchor)
        ])

        // Content layout inside card
        let rightStack = UIStackView(arrangedSubviews: [captionTextView, charCountLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .fill
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        let rowStack = UIStackView(arrangedSubviews: [thumbnailView, rightStack])
        rowStack.axis = .horizontal
        rowStack.spacing = 14
        rowStack.alignment = .top
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        mediaCard.addSubview(rowStack)
        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: 90),
            thumbnailView.heightAnchor.constraint(equalToConstant: 110),

            rowStack.topAnchor.constraint(equalTo: mediaCard.topAnchor, constant: 16),
            rowStack.leadingAnchor.constraint(equalTo: mediaCard.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: mediaCard.trailingAnchor, constant: -16),
            rowStack.bottomAnchor.constraint(equalTo: mediaCard.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(mediaCard)

        // Tap thumbnail to preview
        let tap = UITapGestureRecognizer(target: self, action: #selector(previewVideo))
        thumbnailView.isUserInteractionEnabled = true
        thumbnailView.addGestureRecognizer(tap)
    }

    private func buildAudienceCard() {
        // Left side
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 4
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        leftStack.addArrangedSubview(audienceTitleLabel)

        let dotRow = UIStackView(arrangedSubviews: [audienceValueDot, audienceValueLabel])
        dotRow.axis = .horizontal
        dotRow.spacing = 6
        dotRow.alignment = .center
        leftStack.addArrangedSubview(dotRow)
        NSLayoutConstraint.activate([
            audienceValueDot.widthAnchor.constraint(equalToConstant: 10),
            audienceValueDot.heightAnchor.constraint(equalToConstant: 10)
        ])

        // Right side: segmented-looking buttons
        everyoneButton.addTarget(self, action: #selector(audienceTapped(_:)), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(audienceTapped(_:)), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [everyoneButton, friendsButton])
        btnStack.axis = .horizontal
        btnStack.spacing = 6
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [leftStack, UIView(), btnStack])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        audienceCard.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: audienceCard.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: audienceCard.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: audienceCard.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: audienceCard.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(audienceCard)
    }

    private func buildOptionsCard() {
        let stack = UIStackView(arrangedSubviews: [
            tagRow,
            hairline(),
            locationRow,
            hairline(),
            hashtagRow,
            hairline(),
            commentsRow
        ])
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        optionsCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: optionsCard.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: optionsCard.bottomAnchor, constant: -6)
        ])

        contentStack.addArrangedSubview(optionsCard)
    }

    private func buildShareButton() {
        // Gradient goes on background view, NOT the button layer — so title stays visible
        shareButtonBg.layer.insertSublayer(shareGradientLayer, at: 0)
        shareButtonBg.layer.addSublayer(shimmerGradient)

        // Icon image in the button title
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "paperplane.fill")?.withTintColor(.white)
        attachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
        let iconStr = NSAttributedString(attachment: attachment)
        let spaceStr = NSAttributedString(string: "  ")
        let titleStr = NSAttributedString(
            string: "Share Flick",
            attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .bold), .foregroundColor: UIColor.white]
        )
        let combined = NSMutableAttributedString()
        combined.append(iconStr)
        combined.append(spaceStr)
        combined.append(titleStr)
        shareButton.setAttributedTitle(combined, for: .normal)

        shareButton.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: shareButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: shareButton.centerYAnchor)
        ])
        shareButton.addTarget(self, action: #selector(uploadFlick), for: .touchUpInside)

        // Container: background view sits behind the button
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 26
        container.layer.shadowColor = UIColor(red: 0.24, green: 0.05, blue: 0.14, alpha: 1).cgColor
        container.layer.shadowOpacity = 0.35
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.shadowRadius = 14

        container.addSubview(shareButtonBg)
        container.addSubview(shareButton)

        NSLayoutConstraint.activate([
            shareButtonBg.topAnchor.constraint(equalTo: container.topAnchor),
            shareButtonBg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shareButtonBg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shareButtonBg.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            shareButton.topAnchor.constraint(equalTo: container.topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shareButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shareButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 58)
        ])

        contentStack.addArrangedSubview(container)
    }

    // MARK: - Helpers
    private func makeAudienceButton(title: String, isSelected: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        if isSelected {
            btn.backgroundColor = CineMystTheme.brandPlum
            btn.setTitleColor(.white, for: .normal)
        } else {
            btn.backgroundColor = UIColor.systemGray5
            btn.setTitleColor(.label, for: .normal)
        }
        return btn
    }

    private func makeOptionRow(icon: String, iconBg: UIColor, iconTint: UIColor, title: String, badge: String?, id: String) -> UIView {
        let row = UIView()
        row.restorationIdentifier = id
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 62).isActive = true

        let iconWrap = UIView()
        iconWrap.backgroundColor = iconBg
        iconWrap.layer.cornerRadius = 12
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.widthAnchor.constraint(equalToConstant: 38).isActive = true
        iconWrap.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.textColor = CineMystTheme.pink
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor.systemGray3
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 12).isActive = true

        var rightViews: [UIView] = [valueLabel]
        if let badge = badge {
            let badgeView = makeBadge(text: badge)
            rightViews.append(badgeView)
        }
        rightViews.append(chevron)

        let rightStack = UIStackView(arrangedSubviews: rightViews)
        rightStack.axis = .horizontal
        rightStack.spacing = 8
        rightStack.alignment = .center
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconWrap)
        row.addSubview(titleLabel)
        row.addSubview(rightStack)

        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconWrap.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            rightStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rightStack.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(optionRowTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        return row
    }

    private func makeToggleRow(icon: String, iconBg: UIColor, iconTint: UIColor, title: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 62).isActive = true

        let iconWrap = UIView()
        iconWrap.backgroundColor = iconBg
        iconWrap.layer.cornerRadius = 12
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.widthAnchor.constraint(equalToConstant: 38).isActive = true
        iconWrap.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = true
        toggle.onTintColor = CineMystTheme.brandPlum
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(commentToggleChanged(_:)), for: .valueChanged)

        row.addSubview(iconWrap)
        row.addSubview(titleLabel)
        row.addSubview(toggle)

        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconWrap.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeBadge(text: String) -> UIView {
        let badge = UILabel()
        badge.text = text
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = CineMystTheme.pink
        badge.layer.cornerRadius = 9
        badge.clipsToBounds = true
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 36).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return badge
    }

    private func hairline() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func startShimmer() {
        guard shimmerGradient.animationKeys()?.contains("shimmer") != true else { return }
        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = -shareButton.bounds.width
        anim.toValue = shareButton.bounds.width
        anim.duration = 2.2
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerGradient.add(anim, forKey: "shimmer")
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func loadVideoMeta() {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: self.videoURL)
            let duration = asset.duration.seconds

            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            let img = try? gen.copyCGImage(at: time, actualTime: nil)

            DispatchQueue.main.async {
                self.videoDuration = duration
                let mins = Int(duration) / 60
                let secs = Int(duration) % 60
                self.liveDurationLabel.text = String(format: "%d:%02d", mins, secs)
                if let img = img {
                    self.thumbnailImageView.image = UIImage(cgImage: img)
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func previewVideo() {
        let player = AVPlayer(url: videoURL)
        let vc = AVPlayerViewController()
        vc.player = player
        present(vc, animated: true) { player.play() }
    }

    @objc private func audienceTapped(_ sender: UIButton) {
        audienceIsEveryone = sender == everyoneButton

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            self.everyoneButton.backgroundColor = self.audienceIsEveryone ? CineMystTheme.brandPlum : .systemGray5
            self.everyoneButton.setTitleColor(self.audienceIsEveryone ? .white : .label, for: .normal)
            self.friendsButton.backgroundColor = self.audienceIsEveryone ? .systemGray5 : CineMystTheme.brandPlum
            self.friendsButton.setTitleColor(self.audienceIsEveryone ? .label : .white, for: .normal)
            self.audienceValueLabel.text = self.audienceIsEveryone ? "Everyone" : "Friends"
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    @objc private func commentToggleChanged(_ sender: UISwitch) {
        allowComments = sender.isOn
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    @objc private func optionRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.12, animations: {
            row.alpha = 0.5
            row.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: []) {
                row.alpha = 1
                row.transform = .identity
            }

            switch row.restorationIdentifier {
            case "tag":
                let tagVC = PeopleTagViewController(selectedUsers: self.selectedUsers)
                tagVC.delegate = self
                self.navigationController?.pushViewController(tagVC, animated: true)
            case "location":
                let locVC = LocationPickerViewController()
                locVC.delegate = self
                let nav = UINavigationController(rootViewController: locVC)
                self.present(nav, animated: true)
            case "hashtag":
                self.showHashtagAlert()
            default: break
            }
        }
    }

    private func showHashtagAlert() {
        let alert = UIAlertController(title: "#️⃣ Trending Hashtags", message: "Add tags to boost your Flick's reach", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "#cinematic #film" }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.captionTextView.text = (self.captionTextView.text ?? "") + " " + text
                self.captionPlaceholderLabel.isHidden = true
                self.updateCharCount()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func updateCharCount() {
        let remaining = captionCharLimit - (captionTextView.text?.count ?? 0)
        charCountLabel.text = "\(remaining)"
        charCountLabel.textColor = remaining < 30 ? .systemRed : .tertiaryLabel
    }

    private func setRowValueLabel(in row: UIView, text: String?) {
        guard let label = row.subviews
            .compactMap({ $0 as? UIStackView })
            .flatMap({ $0.arrangedSubviews })
            .compactMap({ $0 as? UIStackView })
            .first(where: { $0.arrangedSubviews.first is UILabel && ($0.arrangedSubviews.first as? UILabel)?.textAlignment == .right })?
            .arrangedSubviews.first as? UILabel
        else {
            return
        }
        label.text = text
    }

    @objc private func uploadFlick() {
        guard !isUploading else { return }
        isUploading = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        shareButton.configuration = config
        loadingIndicator.startAnimating()

        let videoURL = self.videoURL
        let caption = captionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let userId = try await supabase.auth.session.user.id.uuidString
                let videoData = try Data(contentsOf: videoURL, options: .mappedIfSafe)
                let videoUrlStr = try await FlicksService.shared.uploadFlickVideo(videoData, userId: userId)

                var thumbnailUrl: String?
                let asset = AVAsset(url: videoURL)
                let gen = AVAssetImageGenerator(asset: asset)
                gen.appliesPreferredTrackTransform = true
                let t = CMTime(seconds: 0.5, preferredTimescale: 600)
                if let cgImg = try? gen.copyCGImage(at: t, actualTime: nil),
                   let jpeg = UIImage(cgImage: cgImg).jpegData(compressionQuality: 0.75) {
                    thumbnailUrl = try await FlicksService.shared.uploadThumbnail(jpeg, userId: userId)
                }

                _ = try await FlicksService.shared.createFlick(
                    videoUrl: videoUrlStr,
                    thumbnailUrl: thumbnailUrl,
                    caption: caption,
                    audioTitle: "Original Audio",
                    location: selectedLocation,
                    taggedUsers: selectedUsers.map { $0.id },
                    hashtags: [],
                    audience: audienceIsEveryone ? "everyone" : "friends",
                    allowComments: allowComments
                )

                await MainActor.run { self.finish() }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.resetShareButton()
                    self.isUploading = false
                    self.show(error)
                }
            }
        }
    }

    private func resetShareButton() {
        var config = UIButton.Configuration.plain()
        config.title = "Share Flick"
        config.image = UIImage(systemName: "paperplane.fill")
        config.imagePlacement = .leading
        config.imagePadding = 10
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
            var cc = c; cc.font = UIFont.systemFont(ofSize: 18, weight: .bold); return cc
        }
        shareButton.configuration = config
    }

    private func finish() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let alert = UIAlertController(title: "🎬 Posted!", message: "Your Flick is out there.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default) { _ in self.dismiss(animated: true) })
        present(alert, animated: true)
    }

    private func show(_ error: Error) {
        let alert = UIAlertController(title: "Oops", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Delegates
extension FlickComposerViewController: PeopleTagDelegate, LocationPickerDelegate {
    func didSelectUsers(_ users: [ProfileRecord]) {
        selectedUsers = users
        // Update value label on tagRow
        if let label = findValueLabel(in: tagRow) {
            label.text = users.isEmpty ? nil : "@\(users.count) people"
            UIView.animate(withDuration: 0.3) { label.alpha = 1 }
        }
    }

    func didSelectLocation(_ locationName: String) {
        selectedLocation = locationName
        if let label = findValueLabel(in: locationRow) {
            label.text = locationName
            UIView.animate(withDuration: 0.3) { label.alpha = 1 }
        }
    }

    private func findValueLabel(in row: UIView) -> UILabel? {
        return row.subviews
            .compactMap { $0 as? UILabel }
            .first(where: { $0.textAlignment == .right })
    }
}

// MARK: - UITextViewDelegate
extension FlickComposerViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        guard let r = Range(range, in: current) else { return true }
        let updated = current.replacingCharacters(in: r, with: text)
        return updated.count <= captionCharLimit
    }

    func textViewDidChange(_ textView: UITextView) {
        captionPlaceholderLabel.isHidden = !textView.text.isEmpty
        updateCharCount()
    }
}

// MARK: - FlickCard (Reusable Card Container)
class FlickCard: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }
}
