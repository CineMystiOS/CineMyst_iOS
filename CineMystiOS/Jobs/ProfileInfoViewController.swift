//
//  ProfileInfoViewController.swift
//  CineMystApp
//

import UIKit
import Supabase

class ProfileInfoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Selection data sources
    private let companyTypes = ["Production Company", "Post-Production", "Studio", "Network", "Independent", "Freelance"]
    private let experienceYears = ["0-2 years", "3-5 years", "6-10 years", "11-15 years", "16-20 years", "20+ years"]
    private let contractTypes = ["Full-time employee", "Part-time employee", "Freelance/Contract", "Project Based", "Day Rate", "Weekly Rate"]
    private let budgetRanges = ["Under ₹ 500/day", "₹ 500-₹ 1000/day", "₹ 1000-₹ 2000/day", "₹ 2000-₹ 3500/day", "₹ 3500-₹ 5000/day", "₹ 5000+/day"]
    
    // Store selected values
    private var selectedCompanyType: String?
    private var selectedExperience: String?
    private var selectedContract: String?
    private var selectedBudget: String?
    private var selectedAdditionalLocation: String?
    
    // Multi-select sets for pills
    private var selectedSpecializations = Set<String>()
    private var selectedUnions = Set<String>()
    
    // Store text field references
    private var professionalTitleTextField: UITextField?
    private var productionHouseTextField: UITextField?
    private var primaryLocationTextField: UITextField?
    private var websiteTextField: UITextField?
    private var imdbProfileTextField: UITextField?

    // MARK: - Helpers (UI builders)
    private func sectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.darkGray.withAlphaComponent(0.85)
        return label
    }

    private func inputField(title: String, placeholder: String) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray

        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor.systemGray6
        tf.layer.cornerRadius = 8
        tf.setPaddingLeft(12)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Store reference based on title
        if title == "Professional Title *" {
            professionalTitleTextField = tf
        } else if title == "Production House *" {
            productionHouseTextField = tf
        } else if title == "Primary Location *" {
            primaryLocationTextField = tf
        } else if title == "Website/Portfolio" {
            websiteTextField = tf
        } else if title == "IMDb Profile" {
            imdbProfileTextField = tf
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, tf])
        stack.axis = .vertical
        stack.spacing = 6

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // Each selection cell's value label will have tag = 1000 + containerTag
    private func selectionCell(title: String, value: String, tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 8
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        container.tag = tag

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = .gray
        // unique predictable tag for value label
        valueLabel.tag = 1000 + tag

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .gray

        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel, chevron])
        row.axis = .horizontal
        row.alignment = .center

        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectionCellTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        return container
    }

    // MARK: - Actions for selection cells
    @objc private func selectionCellTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        
        var title = ""
        var options: [String] = []
        
        switch tag {
        case 1:
            title = "Company Type"
            options = companyTypes
        case 2:
            title = "Years of Experience"
            options = experienceYears
        case 3:
            title = "Preferred Contract"
            options = contractTypes
        case 4:
            title = "Budget Range"
            options = budgetRanges
        case 5:
            // Additional Locations: show a text entry alert (freeform input)
            let alert = UIAlertController(title: "Additional Location", message: "Enter location (city, area, etc.)", preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "e.g. Mumbai"
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
                guard let text = alert.textFields?.first?.text,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                self?.updateSelection(tag: tag, value: text)
            }))
            present(alert, animated: true)
            return
        default:
            return
        }
        
        showBottomPicker(title: title, options: options, tag: tag)
    }

    private func showBottomPicker(title: String, options: [String], tag: Int) {
        let pickerVC = BottomPickerViewController(title: title, options: options) { [weak self] selectedOption in
            self?.updateSelection(tag: tag, value: selectedOption)
        }
        
        pickerVC.modalPresentationStyle = .pageSheet
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(pickerVC, animated: true)
    }

    private func updateSelection(tag: Int, value: String) {
        // The value label was assigned tag = 1000 + containerTag
        let valueTag = 1000 + tag
        if let valueLabel = view.viewWithTag(valueTag) as? UILabel {
            valueLabel.text = value
            valueLabel.textColor = .darkGray
        } else {
            // fallback: try container traversal (shouldn't normally be needed)
            if let container = view.viewWithTag(tag) {
                for sub in container.subviews {
                    if let stack = sub as? UIStackView {
                        for arranged in stack.arrangedSubviews {
                            if let lbl = arranged as? UILabel, lbl.tag == valueTag {
                                lbl.text = value
                                lbl.textColor = .darkGray
                                break
                            }
                        }
                    }
                }
            }
        }
        
        // Store the selected value
        switch tag {
        case 1: selectedCompanyType = value
        case 2: selectedExperience = value
        case 3: selectedContract = value
        case 4: selectedBudget = value
        case 5: selectedAdditionalLocation = value
        default: break
        }
    }

    // MARK: - Verification card + action buttons
    private let verificationCard: UIView = {
        let card = UIView()
        card.backgroundColor = UIColor.systemGray6
        card.layer.cornerRadius = 14
        card.clipsToBounds = true

        let icon = UIImageView(image: UIImage(systemName: "shield.fill"))
        icon.tintColor = .darkGray

        let title = UILabel()
        title.text = "Professional Verification"
        title.font = UIFont.boldSystemFont(ofSize: 15)

        let desc = UILabel()
        desc.text = "Your profile will be reviewed for verification. Verified profiles get priority visibility and build trust with talent. This helps maintain our community's professional standards."
        desc.font = UIFont.systemFont(ofSize: 13)
        desc.numberOfLines = 0
        desc.textColor = .gray

        let bullet = UILabel()
        bullet.text = "• Review typically takes 24–48 hours"
        bullet.font = UIFont.systemFont(ofSize: 13)
        bullet.textColor = .gray

        let textStack = UIStackView(arrangedSubviews: [title, desc, bullet])
        textStack.axis = .vertical
        textStack.spacing = 4

        card.addSubview(icon)
        card.addSubview(textStack)

        icon.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),

            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }()

    private let nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Next   →", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        b.backgroundColor = UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1)
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    private let skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Skip for now", for: .normal)
        b.setTitleColor(.gray, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Setup navigation bar
        title = "Profile Information"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1),
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        setupScroll()
        buildLayout()
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide tab bar only
        tabBarController?.tabBar.isHidden = true
        
        // Load existing profile data if available
        Task {
            await loadExistingProfile()
        }
    }
    private func loadExistingProfile() async {
        do {
            guard let userId = supabase.auth.currentUser?.id else { return }
            
            // Fetch casting profile
            let castingProfile: CastingProfileRecord = try await supabase
                .from("casting_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Fetch main profile for location
            let profile: ProfileRecord = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                // Populate text fields
                professionalTitleTextField?.text = castingProfile.specificRole
                productionHouseTextField?.text = castingProfile.companyName
                primaryLocationTextField?.text = profile.locationCity
                
                // Populate specializations
                selectedSpecializations = Set(castingProfile.castingTypes)
                
                // Populate contract type from profile
                if let contract = profile.employmentStatus {
                    selectedContract = contract
                }
                
                print("✅ Loaded existing profile data")
                
                // Rebuild the UI to reflect loaded data
                contentView.subviews.forEach { $0.removeFromSuperview() }
                buildLayout()
            }
        } catch {
            print("ℹ️ No existing profile found (creating new): \(error)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore tab bar only
        tabBarController?.tabBar.isHidden = false
    }

    @objc private func nextTapped() {
        // Save profile info to database first
        Task {
            do {
                try await saveDirectorProfile()
                await MainActor.run {
                    // Check if we came from TaskDetailsViewController (already in navigation stack)
                    if navigationController?.viewControllers.contains(where: { $0 is TaskDetailsViewController }) == true {
                        // Pop back to TaskDetailsViewController
                        navigationController?.popViewController(animated: true)
                    } else {
                        // Otherwise navigate to PostJobViewController
                        let vc = PostJobViewController()
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                print("❌ Error saving director profile: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveDirectorProfile() async throws {
        // Get current user ID
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Extract form values from stored references
        let professionalTitle = professionalTitleTextField?.text ?? ""
        let productionHouse = productionHouseTextField?.text ?? ""
        let primaryLocation = primaryLocationTextField?.text ?? ""
        let website = websiteTextField?.text ?? ""
        let imdbProfile = imdbProfileTextField?.text ?? ""
        
        // Use casting_profiles table since director_profiles doesn't exist
        // Map director profile fields to casting profile structure
        let castingProfile = CastingProfileRecordForSave(
            id: userId.uuidString,
            specificRole: professionalTitle.isEmpty ? nil : professionalTitle,
            companyName: productionHouse.isEmpty ? nil : productionHouse,
            castingTypes: Array(selectedSpecializations), // Use specializations as casting types
            castingRadius: nil, // Not applicable for directors
            contactPreference: nil
        )
        
        // Save to casting_profiles table (upsert to update if exists)
        try await supabase
            .from("casting_profiles")
            .upsert(castingProfile)
            .execute()
        
        // Also save/update the main profile with location info
        // This ensures location is available for job posting
        // Use "casting_professional" as the role since "director" is not a valid role in the database
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())
        
        let profile = ProfileRecordForSave(
            id: userId.uuidString,
            username: nil,
            fullName: nil,
            dateOfBirth: nil,
            profilePictureUrl: nil,
            avatarUrl: nil,
            role: "casting_professional", // Use casting_professional as directors are a type of casting professional
            employmentStatus: selectedContract,
            locationState: nil,
            postalCode: nil,
            locationCity: primaryLocation.isEmpty ? nil : primaryLocation,
            bio: nil,
            phoneNumber: nil,
            websiteUrl: nil,
            isVerified: false,
            connectionCount: 0,
            onboardingCompleted: true,  // Director profile is considered onboarding complete
            lastActiveAt: now,
            bannerUrl: nil  // ✅ ADD THIS LINE
        )
        
        try await supabase
            .from("profiles")
            .upsert(profile)
            .execute()
        
        print("✅ Director profile saved successfully to casting_profiles and profiles tables")
    }
    
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Pills (specializations / unions)
    /// Create a horizontally-scrolling row of pill buttons. When tapped they toggle their selected state,
    /// change background/text color, and update the corresponding selected set on the view controller.
    private func makeHorizontalTagRow(_ tags: [String], isSpecialization: Bool) -> UIView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])

        for text in tags {
            let pill = UIButton(type: .system)
            pill.setTitle("  \(text)  ", for: .normal)
            pill.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            pill.setTitleColor(.black, for: .normal)
            pill.backgroundColor = UIColor(white: 0.92, alpha: 1)
            pill.layer.cornerRadius = 18
            pill.clipsToBounds = true
            pill.heightAnchor.constraint(equalToConstant: 36).isActive = true

            // Use accessibilityIdentifier to mark which set to update
            pill.accessibilityIdentifier = isSpecialization ? "spec" : "union"
            // store the text in accessibilityLabel so we can read it in the selector
            pill.accessibilityLabel = text

            pill.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)

            // if it's already selected in our sets, mark visually
            if isSpecialization && selectedSpecializations.contains(text) {
                pill.backgroundColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
                pill.setTitleColor(.white, for: .normal)
            } else if !isSpecialization && selectedUnions.contains(text) {
                pill.backgroundColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
                pill.setTitleColor(.white, for: .normal)
            }

            stack.addArrangedSubview(pill)
        }

        scroll.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return scroll
    }

    @objc private func pillTapped(_ sender: UIButton) {
        guard let text = sender.accessibilityLabel else { return }
        let isSpec = (sender.accessibilityIdentifier == "spec")
        if isSpec {
            if selectedSpecializations.contains(text) {
                // deselect
                selectedSpecializations.remove(text)
                sender.backgroundColor = UIColor(white: 0.92, alpha: 1)
                sender.setTitleColor(.black, for: .normal)
            } else {
                selectedSpecializations.insert(text)
                sender.backgroundColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
                sender.setTitleColor(.white, for: .normal)
            }
        } else {
            if selectedUnions.contains(text) {
                selectedUnions.remove(text)
                sender.backgroundColor = UIColor(white: 0.92, alpha: 1)
                sender.setTitleColor(.black, for: .normal)
            } else {
                selectedUnions.insert(text)
                sender.backgroundColor = UIColor(red: 67/255, green: 0/255, blue: 34/255, alpha: 1)
                sender.setTitleColor(.white, for: .normal)
            }
        }
        // If you need to persist selection immediately, call your save/update API here.
    }

    // MARK: - Layout / Scroll
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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

    private func buildLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        stack.addArrangedSubview(sectionHeader("Basic Information"))
        stack.addArrangedSubview(inputField(title: "Professional Title *", placeholder: "e.g. Producer, Production Manager, Studio"))

        stack.addArrangedSubview(sectionHeader("Company Details"))
        stack.addArrangedSubview(inputField(title: "Production House *", placeholder: "Your production company name"))
        stack.addArrangedSubview(selectionCell(title: "Company Type", value: "Select company", tag: 1))
        stack.addArrangedSubview(selectionCell(title: "Years of Experience", value: "Select experience", tag: 2))

        stack.addArrangedSubview(sectionHeader("Location and Reach"))
        stack.addArrangedSubview(inputField(title: "Primary Location *", placeholder: "Your production company name"))
        stack.addArrangedSubview(selectionCell(title: "Additional Locations", value: "Add location", tag: 5))

        stack.addArrangedSubview(sectionHeader("Professional Expertise"))

        let specLabel = UILabel()
        specLabel.text = "Specializations"
        specLabel.font = UIFont.boldSystemFont(ofSize: 18)
        stack.addArrangedSubview(specLabel)

        // Specializations pills (selectable)
        let specRow = makeHorizontalTagRow(["Feature Films", "TV Series", "Commercials", "Documentary"], isSpecialization: true)
        stack.addArrangedSubview(specRow)

        let unionLabel = UILabel()
        unionLabel.text = "Union Affiliations"
        unionLabel.font = UIFont.boldSystemFont(ofSize: 14)
        stack.addArrangedSubview(unionLabel)

        // Unions pills (selectable)
        let unionRow = makeHorizontalTagRow(["DGA", "PGA", "CSA", "IATSE", "WGA"], isSpecialization: false)
        stack.addArrangedSubview(unionRow)

        stack.addArrangedSubview(sectionHeader("Professional Links"))
        stack.addArrangedSubview(inputField(title: "Website/Portfolio", placeholder: "https://your-website.com"))
        stack.addArrangedSubview(inputField(title: "IMDb Profile", placeholder: "https://imdb.com/name/..."))
        stack.addArrangedSubview(selectionCell(title: "Preferred Contract", value: "Select contract", tag: 3))
        stack.addArrangedSubview(selectionCell(title: "Budget Range", value: "Select budget range", tag: 4))

        stack.addArrangedSubview(verificationCard)
        stack.addArrangedSubview(nextButton)
        stack.addArrangedSubview(skipButton)
    }
}

// MARK: - Bottom Picker View Controller
class BottomPickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let pickerTitle: String
    private let options: [String]
    private let onSelection: (String) -> Void
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.rowHeight = 50
        return table
    }()
    
    private var selectedIndex: Int?
    
    init(title: String, options: [String], onSelection: @escaping (String) -> Void) {
        self.pickerTitle = title
        self.options = options
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        titleLabel.text = pickerTitle
        
        setupViews()
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupViews() {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        headerView.addSubview(cancelButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(doneButton)
        
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add separator line
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        headerView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        if let index = selectedIndex {
            onSelection(options[index])
        }
        dismiss(animated: true)
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.selectionStyle = .none
        
        if indexPath.row == selectedIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

// MARK: - TextField Padding Extension
extension UITextField {
    func setPaddingLeft(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 44))
        leftView = padding
        leftViewMode = .always
    }
}

// MARK: - Director Profile Record
struct DirectorProfileRecord: Codable {
    let id: String
    let professionalTitle: String?
    let productionHouse: String?
    let companyType: String?
    let experienceYears: String?
    let primaryLocation: String?
    let additionalLocations: String?
    let specializations: [String]
    let unionAffiliations: [String]
    let website: String?
    let imdbProfile: String?
    let preferredContract: String?
    let budgetRange: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case professionalTitle = "professional_title"
        case productionHouse = "production_house"
        case companyType = "company_type"
        case experienceYears = "experience_years"
        case primaryLocation = "primary_location"
        case additionalLocations = "additional_locations"
        case specializations
        case unionAffiliations = "union_affiliations"
        case website
        case imdbProfile = "imdb_profile"
        case preferredContract = "preferred_contract"
        case budgetRange = "budget_range"
    }
}
