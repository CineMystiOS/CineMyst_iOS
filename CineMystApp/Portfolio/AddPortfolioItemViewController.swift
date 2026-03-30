//
//  AddPortfolioItemViewController.swift
//  CineMystApp
//
//  Created by Devanshi on 03/02/26.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

class AddPortfolioItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Properties
    var portfolioId: String = ""
    var itemType: PortfolioItemType = .film
    var onItemAdded: ((PortfolioItem) -> Void)?
    private var selectedImage: UIImage?
    private var uploadedImageUrl: String?
    
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
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupScrollView()
        setupUI()
        layoutUI()
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
        imageContainer.backgroundColor = .systemGray6
        imageContainer.layer.cornerRadius = 12
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Image Preview
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 12
        imagePreview.isHidden = true
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        
        // Upload Button
        uploadButton.setTitle("📱 Upload Photo or Video", for: .normal)
        uploadButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 10
        uploadButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        uploadButton.addTarget(self, action: #selector(uploadImageTapped), for: .touchUpInside)
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Upload Progress Label
        uploadProgressLabel.text = "No image selected"
        uploadProgressLabel.font = .systemFont(ofSize: 13)
        uploadProgressLabel.textColor = .secondaryLabel
        uploadProgressLabel.textAlignment = .center
        uploadProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        imageContainer.addSubview(imagePreview)
        imageContainer.addSubview(uploadButton)
        imageContainer.addSubview(uploadProgressLabel)
        
        // Title
        titleField.placeholder = "Title (e.g., Veer-Zaara)"
        titleField.borderStyle = .roundedRect
        titleField.font = .systemFont(ofSize: 16)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        
        // Year
        yearField.placeholder = "Year (e.g., 2023)"
        yearField.borderStyle = .roundedRect
        yearField.font = .systemFont(ofSize: 16)
        yearField.keyboardType = .numberPad
        yearField.translatesAutoresizingMaskIntoConstraints = false
        
        // Role
        roleField.placeholder = "Your Role (e.g., Lead Actor)"
        roleField.borderStyle = .roundedRect
        roleField.font = .systemFont(ofSize: 16)
        roleField.translatesAutoresizingMaskIntoConstraints = false
        
        // Production Company
        productionField.placeholder = "Production Company"
        productionField.borderStyle = .roundedRect
        productionField.font = .systemFont(ofSize: 16)
        productionField.translatesAutoresizingMaskIntoConstraints = false
        
        // Genre
        genreField.placeholder = "Genre (e.g., Drama, Comedy)"
        genreField.borderStyle = .roundedRect
        genreField.font = .systemFont(ofSize: 16)
        genreField.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionView.font = .systemFont(ofSize: 16)
        descriptionView.layer.borderColor = UIColor.systemGray3.cgColor
        descriptionView.layer.borderWidth = 1
        descriptionView.layer.cornerRadius = 6
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Save Button
        saveButton.setTitle("Add \(itemType.displayName)", for: .normal)
        saveButton.backgroundColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.3, green: 0.1, blue: 0.2, alpha: 1.0)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
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
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - PHPickerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        defer { picker.dismiss(animated: true) }
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
            if let url = url, let imageData = try? Data(contentsOf: url) {
                if let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.selectedImage = image
                        self.displaySelectedImage(image)
                        self.uploadImageToSupabase(image)
                    }
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
                    .from("portfolio_images")
                    .upload(fileName, data: imageData)
                
                // Get public URL
                let publicUrl = try supabase
                    .storage
                    .from("portfolio_images")
                    .getPublicURL(path: fileName)
                
                DispatchQueue.main.async {
                    self.uploadedImageUrl = publicUrl.absoluteString
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
        
        saveButton.isEnabled = false
        
        Task {
            do {
                let item = try await PortfolioManager.shared.addPortfolioItem(
                    portfolioId: portfolioId,
                    type: itemType,
                    year: year,
                    title: title,
                    subtitle: nil,
                    role: roleField.text?.isEmpty ?? true ? nil : roleField.text,
                    productionCompany: productionField.text?.isEmpty ?? true ? nil : productionField.text,
                    genre: genreField.text?.isEmpty ?? true ? nil : genreField.text,
                    durationMinutes: nil,
                    description: descriptionView.text?.isEmpty ?? true ? nil : descriptionView.text,
                    posterUrl: uploadedImageUrl,
                    trailerUrl: nil,
                    mediaUrls: nil
                )
                
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.onItemAdded?(item)
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.showAlert(title: "Error", message: "Failed to save item: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
