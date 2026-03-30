//
//  FlickComposerViewController.swift
//  CineMystApp
//
//  Composer for creating and uploading Flicks
//

import UIKit
import AVFoundation
import AVKit

class FlickComposerViewController: UIViewController {
    
    // MARK: - Properties
    private var videoURL: URL
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isUploading = false
    
    // MARK: - UI Elements
    private let playerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captionTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Add a caption..."
        tf.font = .systemFont(ofSize: 16)
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let audioTitleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Audio title (optional)"
        tf.font = .systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let uploadButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Post Flick", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "Uploading..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupVideoPlayer()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerContainerView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(playerContainerView)
        view.addSubview(captionTextField)
        view.addSubview(audioTitleTextField)
        view.addSubview(uploadButton)
        view.addSubview(cancelButton)
        view.addSubview(loadingIndicator)
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            // Video player
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // Caption
            captionTextField.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 20),
            captionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captionTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Audio title
            audioTitleTextField.topAnchor.constraint(equalTo: captionTextField.bottomAnchor, constant: 12),
            audioTitleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            audioTitleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            audioTitleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Upload button
            uploadButton.topAnchor.constraint(equalTo: audioTitleTextField.bottomAnchor, constant: 24),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Progress label
            progressLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupVideoPlayer() {
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            playerContainerView.layer.addSublayer(playerLayer)
        }
        
        // Loop video
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        player?.play()
    }
    
    private func setupActions() {
        uploadButton.addTarget(self, action: #selector(uploadFlick), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Tap to play/pause
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        playerContainerView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func togglePlayPause() {
        if player?.timeControlStatus == .playing {
            player?.pause()
        } else {
            player?.play()
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func uploadFlick() {
        guard !isUploading else { return }
        
        view.endEditing(true)
        isUploading = true
        
        // Show loading
        uploadButton.isEnabled = false
        cancelButton.isEnabled = false
        loadingIndicator.startAnimating()
        progressLabel.isHidden = false
        
        Task {
            do {
                // Get user ID
                guard let userId = try? await supabase.auth.session.user.id.uuidString else {
                    throw NSError(domain: "FlickComposer", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
                }
                
                // Load video data
                progressLabel.text = "Preparing video..."
                let videoData = try Data(contentsOf: videoURL)
                
                // Upload video
                progressLabel.text = "Uploading video..."
                let videoUrl = try await FlicksService.shared.uploadFlickVideo(videoData, userId: userId)
                
                // Generate and upload thumbnail
                progressLabel.text = "Creating thumbnail..."
                var thumbnailUrl: String?
                if let thumbnail = generateThumbnail(from: videoURL) {
                    if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                        thumbnailUrl = try await FlicksService.shared.uploadThumbnail(thumbnailData, userId: userId)
                    }
                }
                
                // Create flick record
                progressLabel.text = "Finalizing..."
                let caption = captionTextField.text?.isEmpty == false ? captionTextField.text : nil
                let audioTitle = audioTitleTextField.text?.isEmpty == false ? audioTitleTextField.text : "Original Audio"
                
                let _ = try await FlicksService.shared.createFlick(
                    videoUrl: videoUrl,
                    thumbnailUrl: thumbnailUrl,
                    caption: caption,
                    audioTitle: audioTitle
                )
                
                // Success
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    progressLabel.isHidden = true
                    
                    showSuccessAndDismiss()
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    progressLabel.isHidden = true
                    uploadButton.isEnabled = true
                    cancelButton.isEnabled = true
                    isUploading = false
                    
                    showError(message: "Failed to upload: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func generateThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Failed to generate thumbnail: \(error)")
            return nil
        }
    }
    
    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Success!",
            message: "Your Flick has been posted",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Upload Failed",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
