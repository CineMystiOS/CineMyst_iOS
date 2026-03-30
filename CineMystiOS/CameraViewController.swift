//
//  CameraViewController.swift
//  CineMystApp
//
//  Instagram-style camera with photo/video switching and 15-second recording limit
//

import UIKit
import AVFoundation
import PhotosUI

enum CameraMode {
    case photo
    case video
}

class CameraViewController: UIViewController {

    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var audioInput: AVCaptureDeviceInput?   // ✅ FIXED
    
    private var currentMode: CameraMode = .photo
    private var recordingTimer: Timer?
    private let maxDuration: TimeInterval = 15.0
    private var recordedURL: URL?
    
    // MARK: - UI Elements
    private let modeSegmentControl = UISegmentedControl(items: ["Photo", "Video"])
    private let captureButton = UIButton()
    private let timerLabel = UILabel()
    private let flashButton = UIButton()
    private let galleryButton = UIButton()
    private var progressRingShapeLayer = CAShapeLayer()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        requestCameraPermissions()
        setupCamera()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
        recordingTimer?.invalidate()
    }

    // MARK: - Camera Setup
    private func requestCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .denied, .restricted:
            showAlert(message: "Camera access denied. Enable in Settings.")
        @unknown default:
            break
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        captureSession = session

        // Video input
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: backCamera),
              session.canAddInput(videoInput) else { return }

        session.addInput(videoInput)

        // Audio input ✅ FIXED
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
            self.audioInput = audioInput
        }

        // Photo output
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }

        // Video output
        let videoOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }

        // Preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        session.startRunning()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Mode Selector
        modeSegmentControl.selectedSegmentIndex = 0
        modeSegmentControl.addTarget(self, action: #selector(modeDidChange(_:)), for: .valueChanged)
        modeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeSegmentControl)

        NSLayoutConstraint.activate([
            modeSegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            modeSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeSegmentControl.widthAnchor.constraint(equalToConstant: 160)
        ])

        // Flash Button
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashButton)

        NSLayoutConstraint.activate([
            flashButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        
        // Gallery Button
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        view.addSubview(galleryButton)
        
        NSLayoutConstraint.activate([
            galleryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            galleryButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])

        // Timer Label
        timerLabel.text = "0:00"
        timerLabel.textColor = .white
        timerLabel.isHidden = true
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: modeSegmentControl.bottomAnchor, constant: 12),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        setupCaptureButton()
    }

    private func setupCaptureButton() {
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        captureButton.addGestureRecognizer(longPress)

        setupProgressRing()
    }

    private func setupProgressRing() {
        let radius: CGFloat = 40

        let path = UIBezierPath(
            arcCenter: CGPoint(x: 35, y: 35),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        progressRingShapeLayer.path = path.cgPath
        progressRingShapeLayer.strokeColor = UIColor.red.cgColor
        progressRingShapeLayer.fillColor = UIColor.clear.cgColor
        progressRingShapeLayer.lineWidth = 3
        progressRingShapeLayer.strokeEnd = 0

        captureButton.layer.addSublayer(progressRingShapeLayer)
    }

    // MARK: - Actions
    @objc private func modeDidChange(_ sender: UISegmentedControl) {
        currentMode = sender.selectedSegmentIndex == 0 ? .photo : .video
        captureButton.backgroundColor = currentMode == .photo ? .white : .red
        
        // Ensure session is running when switching modes
        if let session = captureSession, !session.isRunning {
            session.startRunning()
        }
    }

    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }
    
    @objc private func openGallery() {
        let uploadVC = FlickUploadViewController()
        uploadVC.modalPresentationStyle = .fullScreen
        
        // Dismiss camera and present upload options
        dismiss(animated: true) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(uploadVC, animated: true)
            }
        }
    }

    @objc private func capturePhoto() {
        guard currentMode == .photo, let photoOutput else { return }
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard currentMode == .video else { return }

        if gesture.state == .began {
            startVideoRecording()
        } else if gesture.state == .ended {
            stopVideoRecording()
        }
    }

    private func startVideoRecording() {
        guard let videoOutput else { return }

        let url = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
        videoOutput.startRecording(to: url, recordingDelegate: self)

        timerLabel.isHidden = false
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingProgress()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration) { [weak self] in
            self?.stopVideoRecording()
        }
    }

    private func stopVideoRecording() {
        videoOutput?.stopRecording()
        recordingTimer?.invalidate()
        timerLabel.isHidden = true
        progressRingShapeLayer.strokeEnd = 0
    }

    private func updateRecordingProgress() {
        guard let videoOutput, videoOutput.isRecording else { return }
        let progress = min(videoOutput.recordedDuration.seconds / maxDuration, 1)
        progressRingShapeLayer.strokeEnd = progress
        timerLabel.text = String(format: "0:%02d", Int(videoOutput.recordedDuration.seconds))
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Photo Capture Delegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to process photo")
            return
        }

        let media = DraftMedia(image: image, videoURL: nil, type: .image)
        passMediaToComposer([media])
    }
}

// MARK: - Video Recording Delegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("❌ Video recording error: \(error)")
            return
        }

        // Show options: Post to Feed or Flicks
        showPostOptions(videoURL: outputFileURL)
    }
    
    private func showPostOptions(videoURL: URL) {
        let alert = UIAlertController(
            title: "Post Video",
            message: "Where would you like to post this video?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Post to Feed", style: .default) { [weak self] _ in
            let media = DraftMedia(image: nil, videoURL: videoURL, type: .video)
            self?.passMediaToComposer([media])
        })
        
        alert.addAction(UIAlertAction(title: "Post to Flicks", style: .default) { [weak self] _ in
            self?.postToFlicks(videoURL: videoURL)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Delete temporary video
            try? FileManager.default.removeItem(at: videoURL)
        })
        
        present(alert, animated: true)
    }
    
    private func postToFlicks(videoURL: URL) {
        dismiss(animated: true) { [weak self] in
            let flickComposer = FlickComposerViewController(videoURL: videoURL)
            flickComposer.modalPresentationStyle = .fullScreen
            
            if let parent = self?.presentingViewController {
                parent.present(flickComposer, animated: true)
            }
        }
    }
}

// MARK: - Helper
extension CameraViewController {
    private func passMediaToComposer(_ media: [DraftMedia]) {
        dismiss(animated: true) { [weak self] in
            if let parent = self?.presentingViewController as? HomeDashboardViewController {
                let composer = PostComposerViewController(initialMedia: media)
                composer.delegate = parent
                composer.modalPresentationStyle = .fullScreen
                parent.present(composer, animated: true)
            }
        }
    }
}
