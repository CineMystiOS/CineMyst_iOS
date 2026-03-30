//
//  PostComposerViewController.swift
//  CineMystApp
//
//  Universal post creation screen (Instagram-style)
//

import UIKit
import PhotosUI

protocol PostComposerDelegate: AnyObject {
    func postComposerDidCreatePost(_ post: Post)
    func postComposerDidCancel()
}

final class PostComposerViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: PostComposerDelegate?
    private var draft = PostDraft()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let headerView = UIView()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let postButton = UIButton(type: .system)
    
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    
    private let captionTextView = UITextView()
    private let captionPlaceholder = UILabel()
    
    private let mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 100, height: 100)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private let addMediaButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Initialization
    init(initialMedia: [DraftMedia] = []) {
        super.init(nibName: nil, bundle: nil)
        self.draft.selectedMedia = initialMedia
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
        loadUserProfile()
        
        // Focus caption if no media, otherwise show media first
        if draft.selectedMedia.isEmpty {
            captionTextView.becomeFirstResponder()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupHeader()
        setupScrollView()
        setupProfileSection()
        setupCaptionSection()
        setupMediaSection()
        setupAddMediaButton()
        
        updatePostButtonState()
    }
    
    private func setupHeader() {
        headerView.backgroundColor = .systemBackground
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        headerView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "New Post"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Post button
        postButton.setTitle("Post", for: .normal)
        postButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
        headerView.addSubview(postButton)
        postButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        headerView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            postButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            postButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
        
        // Separator
        let separator = UIView()
        separator.backgroundColor = .separator
        headerView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    private func setupScrollView() {
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func setupProfileSection() {
        let profileStack = UIStackView()
        profileStack.axis = .horizontal
        profileStack.spacing = 12
        profileStack.alignment = .center
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .systemGray5
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        usernameLabel.font = .boldSystemFont(ofSize: 15)
        usernameLabel.text = "Loading..."
        
        profileStack.addArrangedSubview(profileImageView)
        profileStack.addArrangedSubview(usernameLabel)
        
        contentStack.addArrangedSubview(profileStack)
    }
    
    private func setupCaptionSection() {
        let captionContainer = UIView()
        captionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        captionTextView.font = .systemFont(ofSize: 16)
        captionTextView.textColor = .label
        captionTextView.backgroundColor = .clear
        captionTextView.isScrollEnabled = false
        captionTextView.delegate = self
        captionTextView.textContainerInset = .zero
        captionTextView.textContainer.lineFragmentPadding = 0
        captionContainer.addSubview(captionTextView)
        captionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        captionPlaceholder.text = "Write a caption..."
        captionPlaceholder.font = .systemFont(ofSize: 16)
        captionPlaceholder.textColor = .placeholderText
        captionContainer.addSubview(captionPlaceholder)
        captionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            captionTextView.topAnchor.constraint(equalTo: captionContainer.topAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor),
            captionTextView.trailingAnchor.constraint(equalTo: captionContainer.trailingAnchor),
            captionTextView.bottomAnchor.constraint(equalTo: captionContainer.bottomAnchor),
            captionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            captionPlaceholder.topAnchor.constraint(equalTo: captionTextView.topAnchor),
            captionPlaceholder.leadingAnchor.constraint(equalTo: captionTextView.leadingAnchor)
        ])
        
        contentStack.addArrangedSubview(captionContainer)
    }
    
    private func setupMediaSection() {
        guard !draft.selectedMedia.isEmpty else { return }
        
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = self
        mediaCollectionView.register(MediaPreviewCell.self, forCellWithReuseIdentifier: "MediaCell")
        mediaCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mediaCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        contentStack.addArrangedSubview(mediaCollectionView)
    }
    
    private func setupAddMediaButton() {
        addMediaButton.setTitle("📷  Add Photos/Videos", for: .normal)
        addMediaButton.setTitleColor(.systemBlue, for: .normal)
        addMediaButton.titleLabel?.font = .systemFont(ofSize: 16)
        addMediaButton.contentHorizontalAlignment = .left
        addMediaButton.addTarget(self, action: #selector(addMediaTapped), for: .touchUpInside)
        addMediaButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(addMediaButton)
    }
    
    // MARK: - User Profile Loading
    private func loadUserProfile() {
        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else { return }
                let userId = session.user.id
                
                let response = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()
                
                let decoder = JSONDecoder()
                let profile = try decoder.decode(ProfileRecord.self, from: response.data)
                
                await MainActor.run {
                    usernameLabel.text = profile.username ?? "User"
                    
                    if let urlString = profile.profilePictureUrl,
                       let url = URL(string: urlString) {
                        loadImage(from: url, into: profileImageView)
                    }
                }
            } catch {
                print("❌ Error loading profile: \(error)")
            }
        }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        if draft.hasContent {
            showCancelConfirmation()
        } else {
            delegate?.postComposerDidCancel()
            dismiss(animated: true)
        }
    }
    
    private func showCancelConfirmation() {
        let alert = UIAlertController(
            title: "Discard post?",
            message: "If you go back now, you'll lose this post.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.delegate?.postComposerDidCancel()
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func postTapped() {
        draft.caption = captionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard draft.hasContent else {
            showAlert(message: "Please add a caption or media to post")
            return
        }
        
        createPost()
    }
    
    @objc private func addMediaTapped() {
        showMediaPicker()
    }
    
    // MARK: - Media Picker
    private func showMediaPicker() {
        let alert = UIAlertController(title: "Add Media", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo/Video", style: .default) { [weak self] _ in
            self?.openCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.openGallery()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.mediaTypes = ["public.image", "public.movie"]
        present(picker, animated: true)
    }
    
    private func openGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - draft.selectedMedia.count // Instagram allows 10
        config.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Post Creation
    private func createPost() {
        postButton.isEnabled = false
        titleLabel.isHidden = true
        activityIndicator.startAnimating()
        
        Task {
            do {
                // Use PostManager to create post
                let post = try await PostManager.shared.createPost(
                    caption: draft.caption.isEmpty ? nil : draft.caption,
                    media: draft.selectedMedia
                )
                
                // Check if view is still in the window before dismissing
                if self.view.window != nil {
                    await MainActor.run {
                        activityIndicator.stopAnimating()
                        titleLabel.isHidden = false
                        delegate?.postComposerDidCreatePost(post)
                        dismiss(animated: true)
                    }
                }
                
            } catch {
                // Check if view is still in the window before showing alert
                if self.view.window != nil {
                    await MainActor.run {
                        postButton.isEnabled = true
                        activityIndicator.stopAnimating()
                        titleLabel.isHidden = false
                        showAlert(message: "Failed to create post: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helpers
    private func updatePostButtonState() {
        postButton.isEnabled = draft.hasContent
        postButton.alpha = draft.hasContent ? 1.0 : 0.5
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension PostComposerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        captionPlaceholder.isHidden = !textView.text.isEmpty
        draft.caption = textView.text
        updatePostButtonState()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PostComposerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            draft.selectedMedia.append(DraftMedia(image: image, videoURL: nil, type: .image))
            refreshMediaSection()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostComposerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let group = DispatchGroup()
        
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                if let img = image as? UIImage {
                    self?.draft.selectedMedia.append(DraftMedia(image: img, videoURL: nil, type: .image))
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.refreshMediaSection()
        }
    }
    
    private func refreshMediaSection() {
        // Rebuild media section
        if draft.selectedMedia.isEmpty {
            mediaCollectionView.removeFromSuperview()
        } else if mediaCollectionView.superview == nil {
            setupMediaSection()
        }
        mediaCollectionView.reloadData()
        updatePostButtonState()
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension PostComposerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        draft.selectedMedia.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaPreviewCell
        let media = draft.selectedMedia[indexPath.item]
        cell.configure(with: media)
        cell.onDelete = { [weak self] in
            self?.draft.selectedMedia.remove(at: indexPath.item)
            self?.refreshMediaSection()
        }
        return cell
    }
}

// MARK: - Media Preview Cell
class MediaPreviewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    var onDelete: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = .black.withAlphaComponent(0.5)
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with media: DraftMedia) {
        imageView.image = media.image
    }
    
    @objc private func deleteTapped() {
        onDelete?()
    }
}
