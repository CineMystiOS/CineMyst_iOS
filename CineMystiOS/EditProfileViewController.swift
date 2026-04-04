import UIKit
import Supabase

// MARK: - Delegate
protocol EditProfileDelegate: AnyObject {
    func editProfileDidSave()
}

class EditProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // MARK: - Form Fields
    private let fullNameField = UITextField()
    private let usernameField = UITextField()
    private let bioTextView = UITextView()
    private let phoneField = UITextField()
    private let emailField = UITextField()
    private let locationField = UITextField()
    private let stateField = UITextField()
    private let skillsField = UITextField()
    private let experienceField = UITextField()
    
    private let saveButton = UIButton(type: .system)

    weak var delegate: EditProfileDelegate?
    private var profileData: UserProfileData?
    private let userId: UUID
    private var selectedProfileImage: UIImage? // Holds the pending image
    
    init(userId: UUID, profileData: UserProfileData? = nil) {
        self.userId = userId
        self.profileData = profileData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupUI()
        setupLayout()
        populateFields()
        prefillEmailFromSessionIfNeeded()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = ActorProfileDS.deepPlum
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // MARK: - Personal Information
        let personalHeader = createSectionHeader("Personal Information")
        contentStack.addArrangedSubview(personalHeader)
        
        fullNameField.placeholder = "Full Name"
        fullNameField.borderStyle = .roundedRect
        fullNameField.font = UIFont.systemFont(ofSize: 14)
        fullNameField.translatesAutoresizingMaskIntoConstraints = false
        fullNameField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(fullNameField)
        
        usernameField.placeholder = "Username"
        usernameField.borderStyle = .roundedRect
        usernameField.font = UIFont.systemFont(ofSize: 14)
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        usernameField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(usernameField)
        
        emailField.placeholder = "Email"
        emailField.borderStyle = .roundedRect
        emailField.font = UIFont.systemFont(ofSize: 14)
        emailField.keyboardType = .emailAddress
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(emailField)
        
        phoneField.placeholder = "Phone Number"
        phoneField.borderStyle = .roundedRect
        phoneField.font = UIFont.systemFont(ofSize: 14)
        phoneField.keyboardType = .phonePad
        phoneField.translatesAutoresizingMaskIntoConstraints = false
        phoneField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(phoneField)
        
        // MARK: - Bio
        let bioHeader = createSectionHeader("Bio")
        contentStack.addArrangedSubview(bioHeader)
        
        bioTextView.font = UIFont.systemFont(ofSize: 14)
        bioTextView.layer.borderColor = UIColor.lightGray.cgColor
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.cornerRadius = 8
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        bioTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        contentStack.addArrangedSubview(bioTextView)
        
        // MARK: - Location Section
        let locationHeader = createSectionHeader("Location")
        contentStack.addArrangedSubview(locationHeader)
        
        locationField.placeholder = "City"
        locationField.borderStyle = .roundedRect
        locationField.font = UIFont.systemFont(ofSize: 14)
        locationField.translatesAutoresizingMaskIntoConstraints = false
        locationField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(locationField)
        
        stateField.placeholder = "State"
        stateField.borderStyle = .roundedRect
        stateField.font = UIFont.systemFont(ofSize: 14)
        stateField.translatesAutoresizingMaskIntoConstraints = false
        stateField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(stateField)
        
        // MARK: - Professional Information
        let profHeader = createSectionHeader("Professional Information")
        contentStack.addArrangedSubview(profHeader)
        
        skillsField.placeholder = "Skills (comma separated)"
        skillsField.borderStyle = .roundedRect
        skillsField.font = UIFont.systemFont(ofSize: 14)
        skillsField.translatesAutoresizingMaskIntoConstraints = false
        skillsField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(skillsField)
        
        experienceField.placeholder = "Years of Experience"
        experienceField.borderStyle = .roundedRect
        experienceField.font = UIFont.systemFont(ofSize: 14)
        experienceField.keyboardType = .numberPad
        experienceField.translatesAutoresizingMaskIntoConstraints = false
        experienceField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(experienceField)
        
        // MARK: - Save Button
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = ActorProfileDS.deepPlum
        saveButton.layer.cornerRadius = 12
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        contentStack.addArrangedSubview(saveButton)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(spacer)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16),
            contentStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = ActorProfileDS.deepPlum
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func populateFields() {
        guard let data = profileData else { return }

        fullNameField.text = data.profile.fullName
        usernameField.text = data.profile.username
        bioTextView.text = data.profile.bio
        emailField.text = data.profile.email
        phoneField.text = data.profile.phoneNumber

        if let location = data.profile.location {
            let parts = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            locationField.text = parts.indices.contains(0) ? parts[0] : ""
            stateField.text = parts.indices.contains(1) ? parts[1] : ""
        }

        if let skills = data.artistProfile?.skills {
            skillsField.text = skills.joined(separator: ", ")
        }

        if let experience = data.artistProfile?.yearsOfExperience {
            experienceField.text = "\(experience)"
        }
    }

    private func prefillEmailFromSessionIfNeeded() {
        Task {
            guard emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true else { return }
            guard let session = try? await AuthManager.shared.currentSession() else { return }
            let email = session.user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !email.isEmpty else { return }

            await MainActor.run {
                if self.emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                    self.emailField.text = email
                }
            }
        }
    }
    
    @objc private func changeProfilePicture() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func saveChanges() {
        print("💾 Saving profile changes...")

        // Show a loading indicator on the button
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)

        Task {
            do {
                // 0. Upload image if selected
                var uploadedUrl: String? = nil
                if let imageToUpload = self.selectedProfileImage, let imageData = imageToUpload.jpegData(compressionQuality: 0.8) {
                    print("📤 Uploading new profile picture...")
                    await MainActor.run { self.saveButton.setTitle("Uploading Image...", for: .normal) }
                    
                    let fileName = "\(userId.uuidString)/profile_\(UUID().uuidString).jpg"
                    
                    try await supabase.storage
                        .from("profile-pictures")
                        .upload(
                            path: fileName,
                            file: imageData,
                            options: FileOptions(cacheControl: "3600", contentType: "image/jpeg")
                        )
                    
                    uploadedUrl = try supabase.storage
                        .from("profile-pictures")
                        .getPublicURL(path: fileName).absoluteString
                    
                    print("✅ Image uploaded to: \(uploadedUrl ?? "nil")")
                }
                
                await MainActor.run { self.saveButton.setTitle("Saving Profile...", for: .normal) }

                // 1. Update profiles table using Encodable struct
                let profileUpdate = ProfileUpdate(
                    full_name: fullNameField.text ?? "",
                    bio: bioTextView.text ?? "",
                    location_city: locationField.text ?? "",
                    location_state: stateField.text ?? "",
                    email: emailField.text ?? "",
                    phone_number: phoneField.text ?? "",
                    updated_at: ISO8601DateFormatter().string(from: Date()),
                    profile_picture_url: uploadedUrl
                )

                let profilesResult = try await supabase
                    .from("profiles")
                    .update(profileUpdate)
                    .eq("id", value: userId.uuidString)
                    .select()
                    .execute()

                // Log raw response — if RLS blocks it, this will be [] (empty array)
                let profilesRaw = String(data: profilesResult.data, encoding: .utf8) ?? "nil"
                print("📦 profiles update response: \(profilesRaw)")
                if profilesRaw == "[]" || profilesRaw == "null" {
                    throw NSError(domain: "ProfileUpdate", code: 404, userInfo: [NSLocalizedDescriptionKey: "Update failed: No matching profile found or RLS blocked the update."])
                }
                print("✅ Profiles table updated — userId: \(userId.uuidString)")

                // 2. Update artist_profiles table
                let rawSkills = skillsField.text ?? ""
                let skills = rawSkills
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                let yearsExp = Int(experienceField.text ?? "")

                let artistUpdate = ArtistProfileUpdate(
                    id: userId.uuidString,
                    skills: skills,
                    years_of_experience: yearsExp
                )

                let artistResult = try await supabase
                    .from("artist_profiles")
                    .upsert(artistUpdate)
                    .select()
                    .execute()

                let artistRaw = String(data: artistResult.data, encoding: .utf8) ?? "nil"
                print("📦 artist_profiles upsert response: \(artistRaw)")
                print("✅ Artist profiles table updated")

                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save Changes", for: .normal)
                    
                    // Notify parent to reload BEFORE dismissing
                    self.delegate?.editProfileDidSave()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save Changes", for: .normal)
                    print("❌ Error saving profile: \(error)")
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - Image Picker Delegate
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            selectedProfileImage = image
        }
        picker.dismiss(animated: true)
    }
}
