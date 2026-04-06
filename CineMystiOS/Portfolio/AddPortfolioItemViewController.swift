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
    private var uploadedMediaUrl: String?
    private var uploadedMediaIsVideo = false
    
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
        config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            displaySelectedImage(image)
            uploadImageToSupabase(image)
        } else if let mediaURL = info[.mediaURL] as? URL {
            displaySelectedVideo(from: mediaURL)
            uploadVideoToSupabase(fileURL: mediaURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - PHPickerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        defer { picker.dismiss(animated: true) }
        
        guard let result = results.first else { return }

        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    self.displaySelectedVideo(from: url)
                }
                self.uploadVideoToSupabase(fileURL: url)
            }
            return
        }

        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
            if let url = url, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.selectedImage = image
                    self.displaySelectedImage(image)
                    self.uploadImageToSupabase(image)
                }
            }
        }
    }
    
    // MARK: - Image Upload
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
    
    private func uploadImageToSupabase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "Error", message: "Failed to process image")
            return
        }
        
        Task {
            do {
                let fileName = "portfolio_\(UUID().uuidString).jpg"
                
                try await supabase
                    .storage
                    .from("portfolio-media")
                    .upload(fileName, data: imageData)
                
                // Get public URL
                let publicUrl = try supabase
                    .storage
                    .from("portfolio-media")
                    .getPublicURL(path: fileName)
                
                DispatchQueue.main.async {
                    self.uploadedImageUrl = publicUrl.absoluteString
                    self.uploadedMediaUrl = publicUrl.absoluteString
                    self.uploadedMediaIsVideo = false
                    self.uploadProgressLabel.text = "✅ Image uploaded successfully"
                }
                
                print("✅ Image uploaded: \(publicUrl)")
            } catch {
                DispatchQueue.main.async {
                    self.uploadProgressLabel.text = "❌ Upload failed"
                    self.imagePreview.isHidden = true
                    self.uploadButton.isHidden = false
                    self.showAlert(title: "Upload Error", message: error.localizedDescription)
                }
                print("❌ Upload error: \(error)")
            }
        }
    }

    private func uploadVideoToSupabase(fileURL: URL) {
        Task {
            do {
                let videoData = try Data(contentsOf: fileURL)
                let fileExtension = fileURL.pathExtension.isEmpty ? "mov" : fileURL.pathExtension
                let fileName = "portfolio_\(UUID().uuidString).\(fileExtension)"

                try await supabase
                    .storage
                    .from("portfolio-media")
                    .upload(fileName, data: videoData)

                let publicUrl = try supabase
                    .storage
                    .from("portfolio-media")
                    .getPublicURL(path: fileName)

                DispatchQueue.main.async {
                    self.uploadedImageUrl = nil
                    self.uploadedMediaUrl = publicUrl.absoluteString
                    self.uploadedMediaIsVideo = true
                    self.uploadProgressLabel.text = "✅ Video uploaded successfully"
                }

                print("✅ Video uploaded: \(publicUrl)")
            } catch {
                DispatchQueue.main.async {
                    self.uploadProgressLabel.text = "❌ Upload failed"
                    self.imagePreview.isHidden = true
                    self.uploadButton.isHidden = false
                    self.imagePreview.contentMode = .scaleAspectFill
                    self.showAlert(title: "Upload Error", message: error.localizedDescription)
                }
                print("❌ Video upload error: \(error)")
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
            posterUrl: uploadedMediaIsVideo ? nil : uploadedImageUrl,
            mediaUrls: uploadedMediaUrl.map { [$0] }
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
