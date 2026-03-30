//
//  FlickUploadViewController.swift
//  CineMystApp
//
//  Allows users to record or select videos for Flicks
//

import UIKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

class FlickUploadViewController: UIViewController {
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Flick"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let recordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Record Video", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let uploadButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Upload from Library", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
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
    
    private let recordIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "video.circle.fill")
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let uploadIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "photo.on.rectangle.angled")
        iv.tintColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(recordIcon)
        view.addSubview(recordButton)
        view.addSubview(uploadIcon)
        view.addSubview(uploadButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Record icon
            recordIcon.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            recordIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordIcon.widthAnchor.constraint(equalToConstant: 80),
            recordIcon.heightAnchor.constraint(equalToConstant: 80),
            
            // Record button
            recordButton.topAnchor.constraint(equalTo: recordIcon.bottomAnchor, constant: 20),
            recordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            recordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            recordButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Upload icon
            uploadIcon.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 40),
            uploadIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadIcon.widthAnchor.constraint(equalToConstant: 80),
            uploadIcon.heightAnchor.constraint(equalToConstant: 80),
            
            // Upload button
            uploadButton.topAnchor.constraint(equalTo: uploadIcon.bottomAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            uploadButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 24),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupActions() {
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func recordTapped() {
        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    @objc private func uploadTapped() {
        // Check photo library permission
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.presentVideoPicker()
                case .denied, .restricted:
                    self?.showPermissionAlert()
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Video Picker
    private func presentVideoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Photo Library Access",
            message: "Please enable photo library access in Settings to upload videos.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension FlickUploadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        // Show loading with custom view instead of alert
        let loadingView = createLoadingView()
        view.addSubview(loadingView)
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.showError(message: "Failed to load video: \(error.localizedDescription)")
                }
                return
            }
            
            guard let url = url else {
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.showError(message: "Failed to access video file")
                }
                return
            }
            
            // IMPORTANT: Copy file immediately as the URL is temporary and will be deleted
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
            
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                // Now validate the copied file
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.validateAndPresentVideo(url: tempURL)
                }
            } catch {
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.showError(message: "Failed to copy video: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createLoadingView() -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        container.addSubview(activityIndicator)
        
        let label = UILabel()
        label.text = "Loading video..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
    }
    
    private func validateAndPresentVideo(url: URL) {
        // Show processing view
        let loadingView = createLoadingView()
        loadingView.subviews.compactMap { $0 as? UILabel }.first?.text = "Processing video..."
        view.addSubview(loadingView)
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVAsset(url: url)
            let duration = asset.duration.seconds
            
            DispatchQueue.main.async {
                loadingView.removeFromSuperview()
                
                // Check if video is too long (max 60 seconds for Flicks)
                if duration > 60 {
                    self?.showError(message: "Video must be 60 seconds or less. Your video is \(Int(duration)) seconds.")
                    return
                }
                
                // Get the presenting view controller before dismissing
                guard let presentingVC = self?.presentingViewController else { return }
                
                // Present FlickComposerViewController from the presenting view controller
                self?.dismiss(animated: true) {
                    let composer = FlickComposerViewController(videoURL: url)
                    composer.modalPresentationStyle = .fullScreen
                    presentingVC.present(composer, animated: true)
                }
            }
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
