//
//  PostComposerViewController.swift
//  CineMystApp
//
//  Redesigned — #431631 plum-maroon + #CD72A8 pink aesthetic
//

import UIKit
import PhotosUI

// MARK: - Token mapping (old → new)
// accentHot  → CineMystTheme.pink
// plumMid    → CineMystTheme.deepPlumMid
// plumLight  → CineMystTheme.pink          (used as tint/border accent)
// accent     → CineMystTheme.accent        (purple, unchanged)
// plumPale   → CineMystTheme.pinkPale

protocol PostComposerDelegate: AnyObject {
    func postComposerDidCreatePost(_ post: Post)
    func postComposerDidCancel()
}

final class PostComposerViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: PostComposerDelegate?
    private var draft = PostDraft()

    // MARK: - UI Components
    private let scrollView      = UIScrollView()
    private let contentStack    = UIStackView()

    // Header
    private let headerView         = UIView()
    private let cancelButton       = UIButton(type: .system)
    private let titleLabel         = UILabel()
    private let postButton         = UIButton(type: .system)
    private let activityView       = UIActivityIndicatorView(style: .medium)

    // Profile row
    private let profileAvatarView  = UIView()
    private let profileAvatarLabel = UILabel()
    private let usernameLabel      = UILabel()
    private let audiencePill       = UIButton(type: .system)

    // Caption
    private let captionTextView    = UITextView()
    private let captionPlaceholder = UILabel()
    private let charCountLabel     = UILabel()

    // Media strip
    private let mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 110, height: 110)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()

    // Action toolbar
    private let toolbarView  = UIView()
    private let addPhotoBtn  = UIButton(type: .system)
    private let addVideoBtn  = UIButton(type: .system)
    private let tagPeopleBtn = UIButton(type: .system)
    private let locationBtn  = UIButton(type: .system)
    private let moodBtn      = UIButton(type: .system)

    // MARK: - Init
    init(initialMedia: [DraftMedia] = []) {
        super.init(nibName: nil, bundle: nil)
        draft.selectedMedia = initialMedia
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupHeader()
        setupScrollView()
        setupProfileRow()
        setupCaptionArea()
        setupMediaStrip()
        setupActionToolbar()
        setupKeyboardObservers()
        loadUserProfile()
        updatePostButton()
        animateIn()

        if draft.selectedMedia.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.captionTextView.becomeFirstResponder()
            }
        }
    }

    // MARK: - Animate In
    private func animateIn() {
        headerView.alpha   = 0
        contentStack.alpha = 0
        toolbarView.alpha  = 0

        UIView.animate(withDuration: 0.45, delay: 0.05, options: .curveEaseOut) {
            self.headerView.alpha = 1
        }
        UIView.animate(withDuration: 0.45, delay: 0.15, options: .curveEaseOut) {
            self.contentStack.alpha = 1
        }
        UIView.animate(withDuration: 0.35, delay: 0.25, options: .curveEaseOut) {
            self.toolbarView.alpha = 1
        }
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = UIColor.systemBackground
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let accentLine = UIView()
        accentLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(accentLine)

        // Cancel
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.secondaryLabel, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        headerView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text          = "New Post"
        titleLabel.font          = UIFont(name: "Georgia-Bold", size: 17) ?? .boldSystemFont(ofSize: 17)
        titleLabel.textColor     = .label
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Share button — pill with pink gradient
        postButton.setTitle("Share", for: .normal)
        postButton.setTitleColor(.white, for: .normal)
        postButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        postButton.layer.cornerRadius = 16
        postButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 18, bottom: 7, right: 18)
        postButton.clipsToBounds = true
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
        headerView.addSubview(postButton)
        postButton.translatesAutoresizingMaskIntoConstraints = false

        // Activity spinner — pink tint
        activityView.color = CineMystTheme.pink          // was: accentHot
        activityView.hidesWhenStopped = true
        headerView.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            postButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            postButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            activityView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            activityView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            accentLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            accentLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            accentLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            accentLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        accentLine.backgroundColor = CineMystTheme.pinkLight.withAlphaComponent(0.5)
        applyPostButtonGradient()
    }

    private func applyPostButtonGradient() {
        postButton.layoutIfNeeded()
        postButton.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        let grad = CAGradientLayer()
        // was: plumMid → accentHot  |  now: deepPlumMid → pink
        grad.colors     = [CineMystTheme.deepPlumMid.cgColor, CineMystTheme.pink.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 16
        postButton.layer.insertSublayer(grad, at: 0)
        DispatchQueue.main.async {
            grad.frame = self.postButton.bounds
        }
    }

    // MARK: - Scroll View
    private func setupScrollView() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis    = .vertical
        contentStack.spacing = 20
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -88),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Profile Row
    private func setupProfileRow() {
        profileAvatarView.layer.cornerRadius = 22
        profileAvatarView.clipsToBounds = true
        profileAvatarView.translatesAutoresizingMaskIntoConstraints = false
        profileAvatarView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        profileAvatarView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let grad = CAGradientLayer()
        grad.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        // was: plumLight → accentHot  |  now: pink → accent (purple)
        grad.colors     = [CineMystTheme.pink.cgColor, CineMystTheme.accent.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        profileAvatarView.layer.addSublayer(grad)

        profileAvatarLabel.textColor     = .white
        profileAvatarLabel.font          = .boldSystemFont(ofSize: 16)
        profileAvatarLabel.textAlignment = .center
        profileAvatarView.addSubview(profileAvatarLabel)
        profileAvatarLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileAvatarLabel.centerXAnchor.constraint(equalTo: profileAvatarView.centerXAnchor),
            profileAvatarLabel.centerYAnchor.constraint(equalTo: profileAvatarView.centerYAnchor)
        ])

        usernameLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        usernameLabel.textColor = .label
        usernameLabel.text      = "Loading..."

        // Audience pill — pink border/tint
        audiencePill.setTitle("Everyone  ▾", for: .normal)
        audiencePill.setTitleColor(CineMystTheme.pink, for: .normal)   // was: plumLight
        audiencePill.titleLabel?.font       = .systemFont(ofSize: 11, weight: .medium)
        audiencePill.layer.cornerRadius     = 10
        audiencePill.layer.borderWidth      = 1
        audiencePill.layer.borderColor      = CineMystTheme.pink.withAlphaComponent(0.45).cgColor
        audiencePill.contentEdgeInsets      = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        audiencePill.translatesAutoresizingMaskIntoConstraints = false

        let infoStack = UIStackView(arrangedSubviews: [usernameLabel, audiencePill])
        infoStack.axis      = .vertical
        infoStack.spacing   = 4
        infoStack.alignment = .leading

        let profileRow = UIStackView(arrangedSubviews: [profileAvatarView, infoStack])
        profileRow.axis      = .horizontal
        profileRow.spacing   = 12
        profileRow.alignment = .center

        contentStack.addArrangedSubview(profileRow)
    }

    // MARK: - Caption Area
    private func setupCaptionArea() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        captionTextView.font               = UIFont(name: "Georgia", size: 16) ?? .systemFont(ofSize: 16)
        captionTextView.textColor          = .label
        captionTextView.backgroundColor    = .clear
        captionTextView.isScrollEnabled    = false
        captionTextView.delegate           = self
        captionTextView.textContainerInset = .zero
        captionTextView.textContainer.lineFragmentPadding = 0
        container.addSubview(captionTextView)
        captionTextView.translatesAutoresizingMaskIntoConstraints = false

        captionPlaceholder.text          = "What's on your mind? Share your film story…"
        captionPlaceholder.font          = UIFont(name: "Georgia", size: 16) ?? .systemFont(ofSize: 16)
        captionPlaceholder.textColor     = .placeholderText
        captionPlaceholder.numberOfLines = 3
        container.addSubview(captionPlaceholder)
        captionPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        charCountLabel.text          = "0 / 2200"
        charCountLabel.font          = .systemFont(ofSize: 11)
        charCountLabel.textColor     = .tertiaryLabel
        charCountLabel.textAlignment = .right
        container.addSubview(charCountLabel)
        charCountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            captionTextView.topAnchor.constraint(equalTo: container.topAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            captionTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            captionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            captionPlaceholder.topAnchor.constraint(equalTo: captionTextView.topAnchor),
            captionPlaceholder.leadingAnchor.constraint(equalTo: captionTextView.leadingAnchor),
            captionPlaceholder.trailingAnchor.constraint(equalTo: captionTextView.trailingAnchor),

            charCountLabel.topAnchor.constraint(equalTo: captionTextView.bottomAnchor, constant: 6),
            charCountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            charCountLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        contentStack.addArrangedSubview(container)

        let sep = UIView()
        sep.backgroundColor = CineMystTheme.pinkLight.withAlphaComponent(0.4)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        contentStack.addArrangedSubview(sep)
    }

    // MARK: - Media Strip
    private func setupMediaStrip() {
        mediaCollectionView.delegate   = self
        mediaCollectionView.dataSource = self
        mediaCollectionView.register(ComposerMediaCell.self, forCellWithReuseIdentifier: "ComposerMedia")
        mediaCollectionView.register(AddMediaCell.self,      forCellWithReuseIdentifier: "AddMedia")
        mediaCollectionView.translatesAutoresizingMaskIntoConstraints = false
        mediaCollectionView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        let wrapLabel = UILabel()
        wrapLabel.text      = "Media"
        wrapLabel.font      = .systemFont(ofSize: 12, weight: .semibold)
        wrapLabel.textColor = .secondaryLabel
        wrapLabel.translatesAutoresizingMaskIntoConstraints = false

        let wrapView = UIView()
        wrapView.addSubview(wrapLabel)
        wrapView.addSubview(mediaCollectionView)
        wrapView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wrapLabel.topAnchor.constraint(equalTo: wrapView.topAnchor),
            wrapLabel.leadingAnchor.constraint(equalTo: wrapView.leadingAnchor),

            mediaCollectionView.topAnchor.constraint(equalTo: wrapLabel.bottomAnchor, constant: 10),
            mediaCollectionView.leadingAnchor.constraint(equalTo: wrapView.leadingAnchor, constant: -16),
            mediaCollectionView.trailingAnchor.constraint(equalTo: wrapView.trailingAnchor, constant: 16),
            mediaCollectionView.bottomAnchor.constraint(equalTo: wrapView.bottomAnchor)
        ])

        contentStack.addArrangedSubview(wrapView)
    }

    // MARK: - Action Toolbar
    private func setupActionToolbar() {
        toolbarView.backgroundColor = UIColor.systemBackground
        view.addSubview(toolbarView)
        toolbarView.translatesAutoresizingMaskIntoConstraints = false

        let topSep = UIView()
        topSep.backgroundColor = CineMystTheme.pinkLight.withAlphaComponent(0.4)
        topSep.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(topSep)

        let toolButtons: [(UIButton, String, String)] = [
            (addPhotoBtn,  "photo.on.rectangle",              "Photo"),
            (addVideoBtn,  "video.badge.plus",                "Video"),
            (tagPeopleBtn, "person.crop.circle.badge.plus",   "Tag"),
            (locationBtn,  "location",                        "Location"),
            (moodBtn,      "face.smiling",                    "Mood")
        ]

        let toolStack = UIStackView()
        toolStack.axis         = .horizontal
        toolStack.distribution = .equalSpacing
        toolStack.alignment    = .center
        toolStack.translatesAutoresizingMaskIntoConstraints = false

        for (btn, icon, label) in toolButtons {
            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false

            btn.setImage(UIImage(systemName: icon), for: .normal)
            btn.tintColor = CineMystTheme.pink          // was: plumLight
            btn.translatesAutoresizingMaskIntoConstraints = false

            let lbl = UILabel()
            lbl.text          = label
            lbl.font          = .systemFont(ofSize: 10)
            lbl.textColor     = .secondaryLabel
            lbl.textAlignment = .center
            lbl.translatesAutoresizingMaskIntoConstraints = false

            wrapper.addSubview(btn)
            wrapper.addSubview(lbl)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: wrapper.topAnchor),
                btn.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
                btn.widthAnchor.constraint(equalToConstant: 28),
                btn.heightAnchor.constraint(equalToConstant: 28),
                lbl.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 3),
                lbl.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
                lbl.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
                wrapper.widthAnchor.constraint(equalToConstant: 54)
            ])

            toolStack.addArrangedSubview(wrapper)
        }

        toolbarView.addSubview(toolStack)

        NSLayoutConstraint.activate([
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 80),

            topSep.topAnchor.constraint(equalTo: toolbarView.topAnchor),
            topSep.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
            topSep.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
            topSep.heightAnchor.constraint(equalToConstant: 0.5),

            toolStack.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor, constant: -4),
            toolStack.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 20),
            toolStack.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -20)
        ])

        addPhotoBtn.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        addVideoBtn.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
    }

    // MARK: - User Profile
    private func loadUserProfile() {
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let response = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: session.user.id.uuidString)
                    .single()
                    .execute()
                let profile = try JSONDecoder().decode(ProfileRecord.self, from: response.data)
                await MainActor.run {
                    usernameLabel.text      = profile.username ?? "User"
                    profileAvatarLabel.text = String((profile.username ?? "U").prefix(1)).uppercased()
                    if let url = URL(string: profile.profilePictureUrl ?? "") {
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            guard let d = data, let img = UIImage(data: d) else { return }
                            DispatchQueue.main.async {
                                self.profileAvatarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                                let iv = UIImageView(image: img)
                                iv.frame = self.profileAvatarView.bounds
                                iv.contentMode = .scaleAspectFill
                                self.profileAvatarView.addSubview(iv)
                                self.profileAvatarLabel.removeFromSuperview()
                            }
                        }.resume()
                    }
                }
            } catch {
                print("❌ Profile load error: \(error)")
            }
        }
    }

    // MARK: - Post Creation
    @objc private func postTapped() {
        draft.caption = captionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard draft.hasContent else {
            shakePostButton()
            return
        }
        submitPost()
    }

    private func shakePostButton() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values   = [-8, 8, -6, 6, -3, 3, 0]
        shake.duration = 0.4
        postButton.layer.add(shake, forKey: "shake")
    }

    private func submitPost() {
        postButton.isEnabled = false
        postButton.alpha     = 0
        activityView.startAnimating()

        Task {
            do {
                let post = try await PostManager.shared.createPost(
                    caption: draft.caption.isEmpty ? nil : draft.caption,
                    media: draft.selectedMedia
                )
                guard view.window != nil else { return }
                await MainActor.run {
                    activityView.stopAnimating()
                    postButton.isEnabled = true
                    postButton.alpha     = 1
                    delegate?.postComposerDidCreatePost(post)
                    dismiss(animated: true)
                }
            } catch {
                guard view.window != nil else { return }
                await MainActor.run {
                    activityView.stopAnimating()
                    postButton.isEnabled = true
                    postButton.alpha     = 1
                    showAlert(message: "Failed to post: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func cancelTapped() {
        if draft.hasContent { showDiscardAlert() } else { dismissComposer() }
    }

    private func showDiscardAlert() {
        let alert = UIAlertController(title: "Discard post?",
                                      message: "Your draft will be lost.",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.dismissComposer()
        })
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        present(alert, animated: true)
    }

    private func dismissComposer() {
        delegate?.postComposerDidCancel()
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }) { _ in self.dismiss(animated: false) }
    }

    @objc private func addPhotoTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - draft.selectedMedia.count
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Keyboard
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(kbWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(kbWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height
    }

    @objc private func kbWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
    }

    // MARK: - Helpers
    private func updatePostButton() {
        let enabled = draft.hasContent
        UIView.animate(withDuration: 0.2) {
            self.postButton.alpha = enabled ? 1.0 : 0.45
        }
        postButton.isEnabled = enabled
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func refreshMediaCollection() {
        mediaCollectionView.reloadData()
        updatePostButton()
    }
}

// MARK: - UITextViewDelegate
extension PostComposerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        captionPlaceholder.isHidden = !textView.text.isEmpty
        draft.caption = textView.text
        charCountLabel.text      = "\(textView.text.count) / 2200"
        charCountLabel.textColor = textView.text.count > 2000 ? .systemOrange : .tertiaryLabel
        updatePostButton()
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostComposerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let group = DispatchGroup()
        for r in results {
            group.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] img, _ in
                if let i = img as? UIImage {
                    self?.draft.selectedMedia.append(DraftMedia(image: i, videoURL: nil, type: .image))
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in self?.refreshMediaCollection() }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PostComposerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let img = info[.originalImage] as? UIImage {
            draft.selectedMedia.append(DraftMedia(image: img, videoURL: nil, type: .image))
            refreshMediaCollection()
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension PostComposerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        draft.selectedMedia.count + 1   // +1 for the "Add" cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AddMedia", for: indexPath) as! AddMediaCell
            cell.configure(canAdd: draft.selectedMedia.count < 10)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ComposerMedia", for: indexPath) as! ComposerMediaCell
        cell.configure(with: draft.selectedMedia[indexPath.item - 1])
        cell.onDelete = { [weak self] in
            self?.draft.selectedMedia.remove(at: indexPath.item - 1)
            self?.refreshMediaCollection()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 { addPhotoTapped() }
    }
}


// MARK: ─────────────────────────────────────────────
// MARK: ComposerMediaCell
// MARK: ─────────────────────────────────────────────

final class ComposerMediaCell: UICollectionViewCell {
    var onDelete: (() -> Void)?

    private let imageView    = UIImageView()
    private let deleteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 14
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        deleteButton.layer.cornerRadius = 13
        deleteButton.setImage(
            UIImage(systemName: "xmark",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)),
            for: .normal)
        deleteButton.tintColor = .white
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            deleteButton.widthAnchor.constraint(equalToConstant: 26),
            deleteButton.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with media: DraftMedia) { imageView.image = media.image }

    @objc private func deleteTapped() {
        UIView.animate(withDuration: 0.15, animations: {
            self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            self.onDelete?()
        }
    }
}


// MARK: ─────────────────────────────────────────────
// MARK: AddMediaCell
// MARK: ─────────────────────────────────────────────

final class AddMediaCell: UICollectionViewCell {
    private let iconView  = UIImageView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 14
        layer.borderWidth  = 1.5
        // was: CineMystTheme.accent  |  keeping accent (purple) as the border gives nice contrast
        layer.borderColor  = CineMystTheme.accent.withAlphaComponent(0.4).cgColor
        clipsToBounds = true

        iconView.tintColor   = CineMystTheme.pink       // was: plumLight
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        textLabel.text          = "Add"
        textLabel.font          = .systemFont(ofSize: 11, weight: .medium)
        textLabel.textColor     = CineMystTheme.pink    // was: plumLight
        textLabel.textAlignment = .center
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            textLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            textLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(canAdd: Bool) {
        backgroundColor = CineMystTheme.pinkPale.withAlphaComponent(0.6)  // was: plumPale
        iconView.image = UIImage(
            systemName: canAdd ? "plus.circle.fill" : "checkmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .light))
        iconView.tintColor = canAdd ? CineMystTheme.pink : UIColor.systemGreen  // was: accentHot
        textLabel.text = canAdd ? "Add" : "Full"
        isUserInteractionEnabled = canAdd
        alpha = canAdd ? 1.0 : 0.6
    }
}
