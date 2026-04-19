//
//  AddPortfolioItemViewController.swift
//  CineMystApp
//
//  Created by Devanshi on 03/02/26.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import Supabase

private enum PDS {
    static let gradStart  = UIColor(red: 0.07, green: 0.04, blue: 0.18, alpha: 1)
    static let gradEnd    = UIColor(red: 0.28, green: 0.08, blue: 0.28, alpha: 1)
    static let accent     = UIColor(red: 0.95, green: 0.42, blue: 0.47, alpha: 1)
    static let glass      = UIColor.white.withAlphaComponent(0.06)
    static let glassBorder = UIColor.white.withAlphaComponent(0.12)
}

class AddPortfolioItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Properties
    var portfolioId: String = ""
    var itemType: PortfolioItemType = .film
    var onItemAdded: ((PortfolioItemData) -> Void)?
    private var selectedImage: UIImage?
    private var uploadedImageUrl: String?
    private var uploadedMediaUrls: [String] = []
    private var isUploading = false
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Image upload section
    private let imageContainer = UIView()
    private let imagePreview = UIImageView()
    private let uploadButton = UIButton(type: .system)
    private let uploadProgressLabel = UILabel()
    
    private let titleField = UITextField()
    private let yearField = UITextField()
    private let roleField = UITextField()
    private let productionField = UITextField()
    private let genreField = UITextField()
    private let descriptionView = UITextView()
    
    private let saveButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        
        setupNavigationBar()
        setupScrollView()
        setupUI()
        layoutUI()
    }

    private func setupGradient() {
        let grad = CAGradientLayer()
        grad.colors = [PDS.gradStart.cgColor, PDS.gradEnd.cgColor]
        grad.frame = view.bounds
        view.layer.insertSublayer(grad, at: 0)
    }
    
    // MARK: - Setup Navigation
    private func setupNavigationBar() {
        navigationItem.title = "Add \(itemType.displayName)"
        navigationItem.backButtonTitle = ""
    }
    
    // MARK: - Setup UI
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupUI() {
        // Image Container
        imageContainer.backgroundColor = PDS.glass
        imageContainer.layer.cornerRadius = 20
        imageContainer.layer.borderWidth = 1
        imageContainer.layer.borderColor = PDS.glassBorder.cgColor
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Image Preview
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 20
        imagePreview.isHidden = true
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        
        // Upload Button
        uploadButton.setTitle("📱 UPLOAD MEDIA", for: .normal)
        uploadButton.backgroundColor = .white.withAlphaComponent(0.08)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 12
        uploadButton.layer.borderWidth = 1
        uploadButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        uploadButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        uploadButton.addTarget(self, action: #selector(uploadImageTapped), for: .touchUpInside)
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Upload Progress Label
        uploadProgressLabel.text = "Tap to select poster or reel"
        uploadProgressLabel.font = .systemFont(ofSize: 12)
        uploadProgressLabel.textColor = .white.withAlphaComponent(0.5)
        uploadProgressLabel.textAlignment = .center
        uploadProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        imageContainer.addSubview(imagePreview)
        imageContainer.addSubview(uploadButton)
        imageContainer.addSubview(uploadProgressLabel)
        
        func styleField(_ f: UITextField, placeholder: String) {
            f.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)])
            f.textColor = .white
            f.backgroundColor = PDS.glass
            f.layer.cornerRadius = 12
            f.layer.borderWidth = 1
            f.layer.borderColor = PDS.glassBorder.cgColor
            f.font = .systemFont(ofSize: 15)
            f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 44))
            f.leftViewMode = .always
            f.translatesAutoresizingMaskIntoConstraints = false
        }

        styleField(titleField, placeholder: "TITLE (E.G. VEER-ZAARA)")
        styleField(yearField, placeholder: "YEAR (E.G. 2023)")
        styleField(roleField, placeholder: "YOUR ROLE (E.G. LEAD ACTOR)")
        styleField(productionField, placeholder: "PRODUCTION COMPANY")
        styleField(genreField, placeholder: "GENRE (E.G. DRAMA, COMEDY)")
        
        // Description
        descriptionView.font = .systemFont(ofSize: 15)
        descriptionView.textColor = .white
        descriptionView.backgroundColor = PDS.glass
        descriptionView.layer.cornerRadius = 12
        descriptionView.layer.borderWidth = 1
        descriptionView.layer.borderColor = PDS.glassBorder.cgColor
        descriptionView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Save Button
        saveButton.setTitle("ADD \(itemType.displayName.uppercased())", for: .normal)
        saveButton.backgroundColor = PDS.accent
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 25
        saveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        saveButton.addTarget(self, action: #selector(saveItem), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        [imageContainer, titleField, yearField, roleField, productionField, genreField, descriptionView, saveButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func layoutUI() {
        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageContainer.heightAnchor.constraint(equalToConstant: 200),
            
            imagePreview.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imagePreview.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            
            uploadButton.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            uploadButton.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 44),
            uploadButton.widthAnchor.constraint(equalToConstant: 200),
            
            uploadProgressLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 12),
            uploadProgressLabel.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor, constant: 16),
            uploadProgressLabel.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: -16),
            
            titleField.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 24),
            titleField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: 44),
            
            yearField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            yearField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            yearField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            yearField.heightAnchor.constraint(equalToConstant: 44),
            
            roleField.topAnchor.constraint(equalTo: yearField.bottomAnchor, constant: 16),
            roleField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            roleField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            roleField.heightAnchor.constraint(equalToConstant: 44),
            
            productionField.topAnchor.constraint(equalTo: roleField.bottomAnchor, constant: 16),
            productionField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productionField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            productionField.heightAnchor.constraint(equalToConstant: 44),
            
            genreField.topAnchor.constraint(equalTo: productionField.bottomAnchor, constant: 16),
            genreField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            genreField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            genreField.heightAnchor.constraint(equalToConstant: 44),
            
            descriptionView.topAnchor.constraint(equalTo: genreField.bottomAnchor, constant: 16),
            descriptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionView.heightAnchor.constraint(equalToConstant: 120),
            
            saveButton.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Image Upload Actions
    @objc private func uploadImageTapped() {
        let actionSheet = UIAlertController(title: "Upload Image/Video", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            self.openCamera()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Photo Gallery", style: .default) { _ in
            self.openPhotoGallery()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Error", message: "Camera not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openPhotoGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0 allows unlimited multiple selection
        config.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerDelegate (Camera)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        
        self.uploadButton.isHidden = true
        self.saveButton.isEnabled = false
        self.uploadProgressLabel.text = "Uploading camera media..."
        self.isUploading = true
        
        Task {
            var url: String?
            if let image = info[.originalImage] as? UIImage {
                await MainActor.run { self.displaySelectedImage(image) }
                url = try? await uploadImageAsync(image)
                if let u = url { self.uploadedImageUrl = u }
            } else if let mediaURL = info[.mediaURL] as? URL {
                await MainActor.run { self.displaySelectedVideo(from: mediaURL) }
                let tempDir = FileManager.default.temporaryDirectory
                let destinationURL = tempDir.appendingPathComponent("temp_\(UUID().uuidString).\(mediaURL.pathExtension.isEmpty ? "mov" : mediaURL.pathExtension)")
                try? FileManager.default.copyItem(at: mediaURL, to: destinationURL)
                url = try? await uploadVideoAsync(fileURL: destinationURL)
            }
            
            await MainActor.run {
                if let url = url {
                    self.uploadedMediaUrls.append(url)
                    self.uploadProgressLabel.text = "✅ File uploaded successfully"
                } else {
                    self.uploadProgressLabel.text = "❌ Upload failed"
                }
                self.saveButton.isEnabled = true
                self.isUploading = false
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - PHPickerDelegate (Multi-Gallery)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        defer { picker.dismiss(animated: true) }
        guard !results.isEmpty else { return }
        
        self.uploadButton.isHidden = true
        self.saveButton.isEnabled = false
        self.uploadProgressLabel.text = "Preparing \(results.count) files..."
        self.isUploading = true
        
        Task {
            var successfulUrls: [String] = []
            
            for (index, result) in results.enumerated() {
                await MainActor.run { self.uploadProgressLabel.text = "Uploading... (\(index + 1)/\(results.count))" }
                
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    if let url = try? await loadFileRepresentation(from: result.itemProvider, type: UTType.movie.identifier) {
                        if index == 0 { await MainActor.run { self.displaySelectedVideo(from: url) } }
                        if let uploadedUrl = try? await uploadVideoAsync(fileURL: url) {
                            successfulUrls.append(uploadedUrl)
                        }
                    }
                } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let url = try? await loadFileRepresentation(from: result.itemProvider, type: UTType.image.identifier),
                       let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        if index == 0 { await MainActor.run { self.displaySelectedImage(image) } }
                        if let uploadedUrl = try? await uploadImageAsync(image) {
                            successfulUrls.append(uploadedUrl)
                            if index == 0 { self.uploadedImageUrl = uploadedUrl }
                        }
                    }
                }
            }
            
            await MainActor.run {
                self.uploadedMediaUrls.append(contentsOf: successfulUrls)
                if successfulUrls.count == results.count {
                    self.uploadProgressLabel.text = "✅ \(successfulUrls.count) files uploaded successfully"
                } else {
                    self.uploadProgressLabel.text = "⚠️ \(successfulUrls.count)/\(results.count) files uploaded"
                }
                self.saveButton.isEnabled = true
                self.isUploading = false
            }
        }
    }
    
    // MARK: - Async Upload Helpers
    private func loadFileRepresentation(from provider: NSItemProvider, type: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    let tempDir = FileManager.default.temporaryDirectory
                    let destinationURL = tempDir.appendingPathComponent("temp_\(UUID().uuidString).\(url.pathExtension)")
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        continuation.resume(returning: destinationURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "Provider", code: -1))
                }
            }
        }
    }

    private func uploadImageAsync(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw NSError(domain: "Image Error", code: -1) }
        let fileName = "portfolio_\(UUID().uuidString).jpg"
        try await supabase.storage.from("portfolio-media").upload(fileName, data: imageData)
        return try supabase.storage.from("portfolio-media").getPublicURL(path: fileName).absoluteString
    }

    private func uploadVideoAsync(fileURL: URL) async throws -> String {
        let videoData = try Data(contentsOf: fileURL)
        let fileExtension = fileURL.pathExtension.isEmpty ? "mov" : fileURL.pathExtension
        let fileName = "portfolio_\(UUID().uuidString).\(fileExtension)"
        try await supabase.storage.from("portfolio-media").upload(fileName, data: videoData)
        try? FileManager.default.removeItem(at: fileURL)
        return try supabase.storage.from("portfolio-media").getPublicURL(path: fileName).absoluteString
    }
    
    // MARK: - Previews
    private func displaySelectedImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imagePreview.image = image
            self.imagePreview.isHidden = false
            self.uploadButton.isHidden = true
            self.uploadProgressLabel.text = "Uploading..."
        }
    }

    private func displaySelectedVideo(from fileURL: URL) {
        let asset = AVAsset(url: fileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 60)

        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.imagePreview.image = image
                self.imagePreview.isHidden = false
                self.uploadButton.isHidden = true
                self.uploadProgressLabel.text = "Uploading video..."
            }
        } else {
            DispatchQueue.main.async {
                self.imagePreview.image = UIImage(systemName: "play.rectangle.fill")
                self.imagePreview.tintColor = .white.withAlphaComponent(0.85)
                self.imagePreview.contentMode = .scaleAspectFit
                self.imagePreview.isHidden = false
                self.uploadButton.isHidden = true
                self.uploadProgressLabel.text = "Uploading video..."
            }
        }
    }
    

    
    // MARK: - Save Item
    @objc private func saveItem() {
        guard let title = titleField.text, !title.isEmpty else {
            showAlert(title: "Error", message: "Please enter a title")
            return
        }
        
        guard let yearString = yearField.text, let year = Int(yearString), year > 1900 && year <= 2100 else {
            showAlert(title: "Error", message: "Please enter a valid year")
            return
        }
        
        saveButton.isEnabled = false // DECOUPLED: We don't save to database here anymore.
        // We just pass the data back to the caller (PortfolioViewController) 
        // who handles the secure actor_portfolios save.
        let itemData = PortfolioItemData(
            title: title,
            subtitle: .none,
            role: roleField.text?.isEmpty == true ? nil : roleField.text,
            year: year,
            type: itemType.rawValue,
            productionCompany: productionField.text?.isEmpty == true ? nil : productionField.text,
            genre: genreField.text?.isEmpty == true ? nil : genreField.text,
            durationMinutes: .none,
            description: descriptionView.text?.isEmpty == true ? nil : descriptionView.text,
            posterUrl: uploadedImageUrl,
            mediaUrls: uploadedMediaUrls.isEmpty ? nil : uploadedMediaUrls
        )
        
        Task {
            await MainActor.run {
                self.saveButton.isEnabled = true
                self.onItemAdded?(itemData)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
}
