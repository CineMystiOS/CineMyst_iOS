//
//  TaskVideoPlayerViewController.swift
//  CineMystApp
//
//  Created by AI Assistant on 03/02/26.
//

import UIKit
import AVKit
import AVFoundation

class TaskVideoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    var videoURL: String?
    var actorNotes: String?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let videoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let notesContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.text = "Actor's Notes"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .secondaryLabel
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Task Submission"
        
        setupNavigationBar()
        setupUI()
        setupVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    deinit {
        player?.pause()
        player = nil
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        navigationItem.rightBarButtonItem = closeButton
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(videoContainerView)
        contentView.addSubview(notesContainer)
        
        videoContainerView.addSubview(loadingIndicator)
        
        notesContainer.addSubview(notesLabel)
        notesContainer.addSubview(notesTextView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set notes text
        notesTextView.text = actorNotes ?? "No notes provided"
        
        // Hide notes container if no notes
        if actorNotes == nil || actorNotes?.isEmpty == true {
            notesContainer.isHidden = true
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            videoContainerView.heightAnchor.constraint(equalTo: videoContainerView.widthAnchor, multiplier: 16.0/9.0),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor),
            
            notesContainer.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 20),
            notesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            notesLabel.topAnchor.constraint(equalTo: notesContainer.topAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: notesContainer.leadingAnchor, constant: 16),
            notesLabel.trailingAnchor.constraint(equalTo: notesContainer.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: notesContainer.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: notesContainer.trailingAnchor, constant: -16),
            notesTextView.bottomAnchor.constraint(equalTo: notesContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupVideo() {
        guard let videoURLString = videoURL,
              let url = URL(string: videoURLString) else {
            print("❌ Invalid video URL")
            showErrorAlert()
            return
        }
        
        print("🎬 Loading video from: \(videoURLString)")
        loadingIndicator.startAnimating()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoContainerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            videoContainerView.layer.addSublayer(playerLayer)
        }
        
        // Add player controls
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = videoContainerView.bounds
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.showsPlaybackControls = true
        
        addChild(playerViewController)
        videoContainerView.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        
        // Observe player status
        player?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // Auto-play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.player?.play()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let player = object as? AVPlayer {
            switch player.status {
            case .readyToPlay:
                print("✅ Video ready to play")
                loadingIndicator.stopAnimating()
            case .failed:
                print("❌ Video failed to load: \(player.error?.localizedDescription ?? "Unknown error")")
                loadingIndicator.stopAnimating()
                showErrorAlert()
            case .unknown:
                print("⚠️ Video status unknown")
            @unknown default:
                break
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        player?.pause()
        navigationController?.popViewController(animated: true)
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Unable to load video. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
