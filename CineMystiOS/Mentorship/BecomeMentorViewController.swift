//
//  BecomeMentorViewController.swift
//  ProgrammaticMentorship
//
//  Full BecomeMentor + area selector + helpers (single-file)
//

import UIKit
import PhotosUI
import Supabase
import QuartzCore

// MARK: - BecomeMentorViewController
final class BecomeMentorViewController: UITableViewController {

    // MARK: - Form Model
    private struct Form {
        var fullName: String?
        var professionalTitle: String?
        var about: String?
        var years: String?
        var organisation: String?
        var city: String?
        var country: String?
        var mentorshipAreas: [String: String] = [:]
        var languages: String?
        var avatarImage: UIImage?
        var slots: [Date] = []
    }

    private var form = Form()
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowTop = UIView()
    private let ambientGlowBottom = UIView()

    // MARK: - UI Identifiers
    private enum ID {
        static let textField = "TextFieldCell"
        static let textView = "TextViewCell"
        static let button = "ButtonCell"
        static let picker = "PickerCell"
        static let avatar = "AvatarCell"
    }

    private enum Section: Int, CaseIterable {
        case basicInfo = 0, location, expertise, availability, attach
    }

    // MARK: - Brand color
    private let brandColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: - Submit Button
    private lazy var submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Submit", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = CineMystTheme.brandPlum
        b.layer.cornerRadius = 16
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        b.layer.shadowColor = CineMystTheme.deepPlum.cgColor
        b.layer.shadowOpacity = 0.18
        b.layer.shadowRadius = 18
        b.layer.shadowOffset = CGSize(width: 0, height: 10)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        return b
    }()

    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Become a Mentor"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()
        setupTheme()

        // Prefill mentor form from the logged-in user's existing profile
        Task { await prefillProfileFromUserAccount() }

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: ID.textField)
        tableView.register(TextViewCell.self, forCellReuseIdentifier: ID.textView)
        tableView.register(ActionRowCell.self, forCellReuseIdentifier: ID.button)
        tableView.register(PickerCell.self, forCellReuseIdentifier: ID.picker)
        tableView.register(AvatarCell.self, forCellReuseIdentifier: ID.avatar)

        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 14

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 96))
        footer.backgroundColor = .clear
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(submitButton)

        NSLayoutConstraint.activate([
            submitButton.leadingAnchor.constraint(equalTo: footer.layoutMarginsGuide.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: footer.layoutMarginsGuide.trailingAnchor),
            submitButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        tableView.tableFooterView = footer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowTop.layer.cornerRadius = ambientGlowTop.bounds.width / 2
        ambientGlowBottom.layer.cornerRadius = ambientGlowBottom.bounds.width / 2
    }

    private func setupTheme() {
        navigationController?.navigationBar.tintColor = CineMystTheme.brandPlum
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: CineMystTheme.ink,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }

    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1).cgColor,
            CineMystTheme.plumMist.cgColor,
            UIColor(red: 0.936, green: 0.892, blue: 0.917, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.45, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)

        ambientGlowTop.backgroundColor = CineMystTheme.brandPlum.withAlphaComponent(0.12)
        ambientGlowTop.layer.shadowColor = CineMystTheme.brandPlum.cgColor
        ambientGlowTop.layer.shadowOpacity = 0.18
        ambientGlowTop.layer.shadowRadius = 80
        ambientGlowTop.layer.shadowOffset = .zero

        ambientGlowBottom.backgroundColor = CineMystTheme.deepPlumMid.withAlphaComponent(0.08)
        ambientGlowBottom.layer.shadowColor = CineMystTheme.deepPlumMid.cgColor
        ambientGlowBottom.layer.shadowOpacity = 0.16
        ambientGlowBottom.layer.shadowRadius = 90
        ambientGlowBottom.layer.shadowOffset = .zero

        [ambientGlowTop, ambientGlowBottom].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ambientGlowTop.widthAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.heightAnchor.constraint(equalToConstant: 220),
            ambientGlowTop.topAnchor.constraint(equalTo: view.topAnchor, constant: -50),
            ambientGlowTop.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 70),

            ambientGlowBottom.widthAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.heightAnchor.constraint(equalToConstant: 240),
            ambientGlowBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -90),
            ambientGlowBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 50)
        ])
    }

    // MARK: - Prefill helpers
    private func dictFrom(_ raw: Any?) -> [String: Any]? {
        guard let raw = raw else { return nil }
        if let d = raw as? [String: Any] { return d }
        if let data = raw as? Data {
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        if let s = raw as? String, let data = s.data(using: .utf8) {
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        return nil
    }

    @MainActor
    private func prefillProfileFromUserAccount() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            let res = try await supabase
                .from("profiles")
                .select("full_name, username, profile_picture_url, avatar_url, location_city, location_state")
                .eq("id", value: userId)
                .single()
                .execute()

            if let dict = dictFrom(res.data) {
                let fullName = (dict["full_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let username = (dict["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let profilePictureURL = (dict["profile_picture_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let avatarURL = (dict["avatar_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let locationCity = (dict["location_city"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let locationState = (dict["location_state"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let emailPrefix = session.user.email?.split(separator: "@").first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)

                let candidates: [String?] = [fullName, username, emailPrefix]
                let resolvedName = candidates.compactMap { candidate -> String? in
                    guard let candidate, !candidate.isEmpty else { return nil }
                    return candidate
                }.first

                if let resolvedName,
                   (form.fullName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                    self.form.fullName = resolvedName
                }

                if (form.city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
                   let locationCity,
                   !locationCity.isEmpty {
                    self.form.city = locationCity
                }

                if (form.country?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
                   let locationState,
                   !locationState.isEmpty {
                    self.form.country = locationState
                }

                if form.avatarImage == nil {
                    let imageURLString = [profilePictureURL, avatarURL]
                        .compactMap { value -> String? in
                            guard let value, !value.isEmpty else { return nil }
                            return value
                        }
                        .first

                    if let imageURLString,
                       let url = URL(string: imageURLString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                self.form.avatarImage = image
                            }
                        } catch {
                            print("[BecomeMentor] prefill avatar failed: \(error)")
                        }
                    }
                }

                tableView.reloadData()
            }
        } catch {
            print("[BecomeMentor] prefill profile failed: \(error)")
        }
    }

    // MARK: - Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .basicInfo: return "Basic Information"
        case .location: return "Location"
        case .expertise: return "Professional Expertise"
        case .availability: return "Your Availability"
        case .attach: return "Attach Picture"
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.tintColor = .clear
        header.contentView.backgroundColor = .clear
        header.textLabel?.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.74)
        header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
    }

    // MARK: - Row Count
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .basicInfo: return 5
        case .location: return 2
        case .expertise: return 1 + form.mentorshipAreas.count
        case .availability: return 1 + form.slots.count
        case .attach: return 1
        }
    }

    // MARK: - Cell Creation
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch Section(rawValue: indexPath.section)! {

        // ----------------------
        // BASIC INFO
        // ----------------------
        case .basicInfo:
            switch indexPath.row {

            case 0:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.textField,
                    for: indexPath
                ) as! TextFieldCell
                cell.configure(placeholder: "Full name",
                               text: form.fullName) { self.form.fullName = $0 }
                return cell

            case 1:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.textField,
                    for: indexPath
                ) as! TextFieldCell
                cell.configure(placeholder: "Professional title",
                               text: form.professionalTitle) { self.form.professionalTitle = $0 }
                return cell

            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: ID.textField, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "About you", text: form.about) { self.form.about = $0 }
                return cell

            case 3:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.button,
                    for: indexPath) as! ActionRowCell
                cell.configure(
                    title: form.years ?? "Experience",
                    subtitle: nil,
                    titleColor: CineMystTheme.brandPlum,
                    subtitleColor: CineMystTheme.ink.withAlphaComponent(0.58),
                    showChevron: true
                )
                return cell

            case 4:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.textField,
                    for: indexPath
                ) as! TextFieldCell
                cell.configure(placeholder: "Organisation",
                               text: form.organisation) { self.form.organisation = $0 }
                return cell

            default:
                return UITableViewCell()
            }

        // ----------------------
        // LOCATION
        // ----------------------
        case .location:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.textField,
                for: indexPath
            ) as! TextFieldCell

            if indexPath.row == 0 {
                cell.configure(placeholder: "City", text: form.city) {
                    self.form.city = $0
                }
            } else {
                cell.configure(placeholder: "Country", text: form.country) {
                    self.form.country = $0
                }
            }
            return cell

        // ----------------------
        // EXPERTISE
        // ----------------------
        case .expertise:

            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.button,
                    for: indexPath
                ) as! ActionRowCell
                cell.configure(
                    title: "Select Mentorship Area(s)",
                    subtitle: form.mentorshipAreas.isEmpty ? "No areas selected" : "\(form.mentorshipAreas.count) selected",
                    titleColor: CineMystTheme.brandPlum,
                    subtitleColor: CineMystTheme.ink.withAlphaComponent(0.58),
                    showChevron: true
                )
                return cell
            }

            let areaIndex = indexPath.row - 1
            let area = Array(form.mentorshipAreas.keys.sorted())[areaIndex]
            let price = form.mentorshipAreas[area] ?? "Set price"

            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.button,
                for: indexPath
            ) as! ActionRowCell
            cell.configure(
                title: area,
                subtitle: price,
                titleColor: CineMystTheme.ink,
                subtitleColor: CineMystTheme.brandPlum,
                showChevron: true
            )
            return cell

        // ----------------------
        // AVAILABILITY
        // ----------------------
        case .availability:

            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.button,
                    for: indexPath
                ) as! ActionRowCell
                cell.configure(
                    title: "Add Slot",
                    subtitle: nil,
                    titleColor: CineMystTheme.brandPlum,
                    subtitleColor: CineMystTheme.ink.withAlphaComponent(0.58),
                    showChevron: true
                )
                return cell
            }

            let idx = indexPath.row - 1
            let slotDate = form.slots[idx]

            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.button,
                for: indexPath
            ) as! ActionRowCell

            cell.configure(
                title: formattedSlot(slotDate),
                subtitle: nil,
                titleColor: CineMystTheme.ink,
                subtitleColor: CineMystTheme.ink.withAlphaComponent(0.58),
                showChevron: false
            )
            cell.selectionStyle = .none
            return cell

        // ----------------------
        // ATTACH AVATAR
        // ----------------------
        case .attach:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.avatar,
                for: indexPath
            ) as! AvatarCell

            cell.configure(image: form.avatarImage) { [weak self] in
                self?.presentPhotoPicker()
            }
            return cell
        }
    }

    // MARK: - Row Selection
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .basicInfo:
            if indexPath.row == 3 { presentYearsActionSheet() }

        case .expertise:
            if indexPath.row == 0 {
                presentAreaSelector()
            } else {
                let areaIndex = indexPath.row - 1
                let area = Array(form.mentorshipAreas.keys.sorted())[areaIndex]
                presentPriceSelector(for: area)
            }

        case .availability:
            if indexPath.row == 0 {
                presentAddSlot()
            }

        case .attach:
            presentPhotoPicker()

        default: break
        }
    }

    // MARK: - Swipe to Delete (Area + Slots)
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }

        switch Section(rawValue: indexPath.section)! {

        case .availability:
            if indexPath.row > 0 {
                let idx = indexPath.row - 1
                form.slots.remove(at: idx)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }

        case .expertise:
            if indexPath.row > 0 {
                let idx = indexPath.row - 1
                let key = Array(form.mentorshipAreas.keys.sorted())[idx]
                form.mentorshipAreas.removeValue(forKey: key)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }

        default: break
        }
    }

    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {

        let sec = Section(rawValue: indexPath.section)!

        if (sec == .availability && indexPath.row > 0)
            || (sec == .expertise && indexPath.row > 0) {
            return .delete
        }
        return .none
    }

    // MARK: - Add Slot Sheet
    private func presentAddSlot() {
        let vc = AddSlotViewController(initialDate: Date(), brand: brandColor)

        // Annotate closure parameter type so compiler always knows it
        vc.completion = { [weak self] (date: Date) in
            guard let self = self else { return }

            if !self.form.slots.contains(where: {
                Calendar.current.isDate($0, equalTo: date, toGranularity: .minute)
            }) {
                self.form.slots.append(date)
                self.form.slots.sort()
                self.tableView.reloadSections([Section.availability.rawValue], with: .automatic)
            }
        }

        // present as sheet with nav controller so it looks native
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        vc.preferredContentSize = CGSize(width: view.bounds.width, height: 520)

        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.preferredCornerRadius = 14
            }
        }

        present(nav, animated: true)
    }

    private func formattedSlot(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: d)
    }

    // MARK: - Area Selector presentation (sheet)
    private func presentAreaSelector() {
        let vc = AreaSelectionViewController(selected: Array(form.mentorshipAreas.keys))

        // annotate closure parameter type
        vc.completion = { [weak self] (selected: [String]) in
            guard let self = self else { return }

            // Add new areas with empty price if missing
            selected.forEach { if self.form.mentorshipAreas[$0] == nil { self.form.mentorshipAreas[$0] = "" } }

            // Remove unselected
            let removed = Set(self.form.mentorshipAreas.keys).subtracting(selected)
            removed.forEach { self.form.mentorshipAreas.removeValue(forKey: $0) }

            self.tableView.reloadSections([Section.expertise.rawValue], with: .automatic)
        }

        // Wrap in nav controller so we keep Cancel/Done bar items
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        vc.preferredContentSize = CGSize(width: view.bounds.width, height: 420)

        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.preferredCornerRadius = 14
            }
        }

        present(nav, animated: true)
    }

    // MARK: - Price Sheet
    private func presentPriceSelector(for area: String) {
        let ac = UIAlertController(title: "Price for \"\(area)\"",
                                   message: "Choose a price",
                                   preferredStyle: .actionSheet)

        let prices = ["₹ 300/hour","₹ 500/hour","₹ 700/hour","₹ 1k/hour","₹ 1.5k/hour","₹ 2k/hour","Custom..."]

        for p in prices {
            ac.addAction(UIAlertAction(title: p, style: .default) { _ in
                if p == "Custom..." {
                    self.presentCustomPriceInput(for: area)
                } else {
                    self.form.mentorshipAreas[area] = p
                    self.tableView.reloadSections([Section.expertise.rawValue], with: .automatic)
                }
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func presentCustomPriceInput(for area: String) {
        let ac = UIAlertController(title: "Custom price", message: nil, preferredStyle: .alert)
        ac.addTextField { $0.placeholder = "₹ 250/hour" }
        ac.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            if let text = ac.textFields?.first?.text, !text.isEmpty {
                self.form.mentorshipAreas[area] = text
                self.tableView.reloadSections([Section.expertise.rawValue], with: .automatic)
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    // MARK: - Experience Sheet
    private func presentYearsActionSheet() {
        let ac = UIAlertController(title: "Years of Experience", message: nil, preferredStyle: .actionSheet)
        ["<1", "1–3", "3–5", "5+"].forEach { item in
            ac.addAction(UIAlertAction(title: item, style: .default) { _ in
                self.form.years = item
                self.tableView.reloadSections([Section.basicInfo.rawValue], with: .automatic)
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    // MARK: - Photo Picker
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Submit
    @objc private func didTapSubmit() {
        guard let name = form.fullName, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(title: "Missing name", message: "Please enter your full name.")
            return
        }
        guard !form.mentorshipAreas.isEmpty else {
            showAlert(title: "No mentorship area", message: "Select at least one area.")
            return
        }
        guard form.mentorshipAreas.values.allSatisfy({ !$0.isEmpty }) else {
            showAlert(title: "Price missing", message: "Set a price for each area.")
            return
        }

        // save to backend then navigate
        Task { await submitToBackendAndNavigate() }
    }

    private func setSubmitting(_ submitting: Bool) {
        DispatchQueue.main.async {
            self.submitButton.isEnabled = !submitting
            self.submitButton.alpha = submitting ? 0.7 : 1.0
        }
    }

    private func submitToBackendAndNavigate() async {
        setSubmitting(true)
        defer { setSubmitting(false) }

        let userId: String
        do {
            let session = try await supabase.auth.session
            userId = session.user.id.uuidString
        } catch {
            await MainActor.run {
                self.showAlert(title: "Session error", message: "Please sign in again and try submitting your mentor profile.")
            }
            return
        }

        // Build payload as a concrete Encodable struct (Supabase client expects Encodable)
        let areas = Array(form.mentorshipAreas.keys)

        // Flatten metadata into [String:String] — prices are encoded as JSON string under "prices_json"
        var metadataFlat: [String: String] = [:]
        if !form.mentorshipAreas.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: form.mentorshipAreas), let s = String(data: data, encoding: .utf8) {
                metadataFlat["prices_json"] = s
            }
        }
        if let years = form.years { metadataFlat["years"] = years }
        if let org = form.organisation { metadataFlat["organisation"] = org }
        if let langs = form.languages { metadataFlat["languages"] = langs }
        if let city = form.city { metadataFlat["city"] = city }
        if let country = form.country { metadataFlat["country"] = country }
        
        // Persist selected availability slots as ISO8601 strings in metadata so the backend
        // receives the mentor's availability. Stored under key `availability_slots_json`.
        if !form.slots.isEmpty {
            let iso = ISO8601DateFormatter()
            let slotsStrings = form.slots.map { iso.string(from: $0) }
            if let data = try? JSONSerialization.data(withJSONObject: slotsStrings),
               let s = String(data: data, encoding: .utf8) {
                metadataFlat["availability_slots_json"] = s
            }
        }

        // Helper: map human-friendly years string to an integer yoe value
        func mapYearsToYOE(_ years: String?) -> Int? {
            guard let y = years?.trimmingCharacters(in: .whitespacesAndNewlines), !y.isEmpty else { return nil }
            switch y {
            case "<1": return 0
            case "1–3", "1-3", "1 to 3": return 1
            case "3–5", "3-5": return 3
            case "5+": return 5
            default:
                // try to extract any leading integer
                let digits = y.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(digits)
            }
        }

        func normalizedMoneyValue(from prices: [String: String]) -> Double? {
            let values = prices.values.compactMap { raw -> Double? in
                let lower = raw.lowercased()
                let multiplier: Double = lower.contains("k") ? 1000.0 : 1.0
                let digits = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
                guard let value = Double(digits) else { return nil }
                return value * multiplier
            }
            return values.filter { $0 > 0 }.min()
        }

        struct MentorInsert: Encodable {
            let user_id: String
            let display_name: String
            let name: String
            let role: String
            let about: String
            let mentorship_areas: [String]
            let metadata: [String: String]?
            let rating: Double
            let rating_count: Int
            let yoe: Int?
            let money: Double?
            let session: Int
            let profile_picture_url: String?
        }

        struct MentorProfileRecord: Decodable {
            let id: String
            let profile_picture_url: String?
            let rating: Double?
            let rating_count: Int?
            let session: Int?
        }

        let uploadedProfilePictureURL = await uploadMentorImageIfNeeded(userId: userId, image: form.avatarImage)
        let defaultMoney = normalizedMoneyValue(from: form.mentorshipAreas)

        let profilePayload = MentorInsert(
            user_id: userId,
            display_name: form.fullName ?? "",
            name: form.fullName ?? "",
            role: form.professionalTitle ?? "",
            about: form.about ?? "",
            mentorship_areas: areas,
            metadata: metadataFlat.isEmpty ? nil : metadataFlat,
            rating: 4.0,
            rating_count: 0,
            yoe: mapYearsToYOE(form.years),
            money: defaultMoney,
            session: 0,
            profile_picture_url: uploadedProfilePictureURL
        )

        do {
            let existingRes = try await supabase.database
                .from("mentor_profiles")
                .select("id, profile_picture_url")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()

            let existingProfiles = try JSONDecoder().decode([MentorProfileRecord].self, from: existingRes.data)
            let existingProfile = existingProfiles.first
            let finalProfilePictureURL = uploadedProfilePictureURL ?? existingProfile?.profile_picture_url

            let finalPayload = MentorInsert(
                user_id: profilePayload.user_id,
                display_name: profilePayload.display_name,
                name: profilePayload.name,
                role: profilePayload.role,
                about: profilePayload.about,
                mentorship_areas: profilePayload.mentorship_areas,
                metadata: profilePayload.metadata,
                rating: existingProfile?.rating ?? profilePayload.rating,
                rating_count: existingProfile?.rating_count ?? 0,
                yoe: profilePayload.yoe,
                money: profilePayload.money,
                session: existingProfile?.session ?? 0,
                profile_picture_url: finalProfilePictureURL
            )

            let mentorId: String
            if let existingProfile {
                _ = try await supabase.database
                    .from("mentor_profiles")
                    .update(finalPayload)
                    .eq("id", value: existingProfile.id)
                    .execute()
                mentorId = existingProfile.id
            } else {
                let res = try await supabase.database
                    .from("mentor_profiles")
                    .insert(finalPayload)
                    .select("id")
                    .single()
                    .execute()

                let inserted = try JSONDecoder().decode(MentorProfileRecord.self, from: res.data)
                mentorId = inserted.id
            }

            UserDefaults.standard.set(true, forKey: "mentor_profile_exists_\(userId)")
            UserDefaults.standard.set([mentorId], forKey: "mentor_profile_ids_\(userId)")

            var profileUpdates: [String: String] = [:]
            if let fullName = form.fullName, !fullName.isEmpty {
                profileUpdates["full_name"] = fullName
            }
            if let finalProfilePictureURL, !finalProfilePictureURL.isEmpty {
                profileUpdates["profile_picture_url"] = finalProfilePictureURL
            }
            if !profileUpdates.isEmpty {
                try? await supabase.database
                    .from("profiles")
                    .update(profileUpdates)
                    .eq("id", value: userId)
                    .execute()
            }

            do {
                try await supabase.database
                    .from("mentor_availability_slots")
                    .delete()
                    .eq("mentor_id", value: mentorId)
                    .execute()

                if !form.slots.isEmpty {
                    let iso = ISO8601DateFormatter()
                    struct AvailabilityInsert: Encodable {
                        let mentor_id: String
                        let start_at: String
                        let end_at: String
                        let is_recurring: Bool
                        let recurrence_rule: String?
                        let is_active: Bool
                    }

                    let availInserts: [AvailabilityInsert] = form.slots.map { slot in
                        let start = iso.string(from: slot)
                        let end = iso.string(from: slot.addingTimeInterval(60 * 60))
                        return AvailabilityInsert(
                            mentor_id: mentorId,
                            start_at: start,
                            end_at: end,
                            is_recurring: false,
                            recurrence_rule: nil,
                            is_active: true
                        )
                    }

                    _ = try await supabase.database
                        .from("mentor_availability_slots")
                        .insert(availInserts)
                        .execute()
                }
            } catch {
                print("❌ Failed to save availability slots: \(error)")
                await MainActor.run {
                    showAlert(title: "Submitted with warnings",
                              message: "Profile saved but availability could not be saved. Please try again.")
                }
            }

            await MainActor.run {
                self.presentMentorCelebration()
            }
        } catch {
            await MainActor.run {
                showAlert(title: "Save failed", message: String(describing: error))
            }
        }
    }


    private func uploadMentorImageIfNeeded(userId: String, image: UIImage?) async -> String? {
        guard let image else { return nil }
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return nil }

        let filePath = "\(userId)/mentor_profile.jpg"

        do {
            try await supabase.storage
                .from("profile-pictures")
                .upload(
                    path: filePath,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )

            let publicURL = try supabase.storage
                .from("profile-pictures")
                .getPublicURL(path: filePath)

            print("[BecomeMentor] uploaded mentor image: \(publicURL.absoluteString)")
            return publicURL.absoluteString
        } catch {
            print("[BecomeMentor] image upload failed: \(error)")
            return nil
        }
    }

    @MainActor
    private func presentMentorCelebration() {
        let celebration = MentorCelebrationViewController(
            titleText: "Woww, you're a mentor now!",
            messageText: "Help people with your guidance and start creating meaningful sessions."
        )
        celebration.onContinue = { [weak self] in
            self?.navigateToMentorshipHome()
        }
        present(celebration, animated: true)
    }

    @MainActor
    private func navigateToMentorshipHome() {
        if let tabBar = self.tabBarController {
            let mentorshipIndex = 3
            if mentorshipIndex < (tabBar.viewControllers?.count ?? 0),
               let mentorNav = tabBar.viewControllers?[mentorshipIndex] as? UINavigationController {
                let home = MentorshipHomeViewController()
                home.initialSegmentIndex = 1
                mentorNav.setViewControllers([home], animated: true)
                tabBar.selectedIndex = mentorshipIndex
                return
            }
            if let vcs = tabBar.viewControllers {
                for (idx, vc) in vcs.enumerated() {
                    if let nav = vc as? UINavigationController {
                        let home = MentorshipHomeViewController()
                        home.initialSegmentIndex = 1
                        nav.setViewControllers([home], animated: true)
                        tabBar.selectedIndex = idx
                        return
                    }
                }
            }
        }
        if let nav = self.navigationController {
            let home = MentorshipHomeViewController()
            home.initialSegmentIndex = 1
            nav.setViewControllers([home], animated: true)
            return
        }
        let home = MentorshipHomeViewController()
        home.initialSegmentIndex = 1
        let modal = UINavigationController(rootViewController: home)
        modal.modalPresentationStyle = .fullScreen
        self.present(modal, animated: true, completion: nil)
    }
}

// MARK: - PHPicker Delegate
extension BecomeMentorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let item = results.first else { return }

        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async {
                    if let img = obj as? UIImage {
                        self.form.avatarImage = img
                        self.tableView.reloadSections([Section.attach.rawValue], with: .automatic)
                    }
                }
            }
        }
    }
}

// MARK: - AreaSelectionViewController (native iOS style)
// (same as before)
final class AreaSelectionViewController: UITableViewController {

    private let topAreas = ["Acting", "Communication", "Directing", "Dubbing"]
    private var customAreas: [String] = []
    private var selected: Set<String>
    var completion: (([String]) -> Void)?

    init(selected: [String]) {
        self.selected = Set(selected)
        super.init(style: .insetGrouped)
        title = "Mentorship Area"

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))

        navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "areaCell")
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 54

        // if initial selection contains items outside topAreas, treat them as customAreas
        let initialCustom = selected.subtracting(topAreas)
        if !initialCustom.isEmpty {
            customAreas = Array(initialCustom)
        }
    }

    // rows = topAreas + customAreas + 1 (Add custom row)
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topAreas.count + customAreas.count + 1
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let topCount = topAreas.count
        // top builtin areas
        if indexPath.row < topCount {
            let area = topAreas[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "areaCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = area
            config.textProperties.font = UIFont.systemFont(ofSize: 17)
            cell.contentConfiguration = config
            cell.accessoryType = selected.contains(area) ? .checkmark : .none
            cell.selectionStyle = .default
            return cell
        }

        // custom areas rows
        let customStart = topCount
        if indexPath.row < customStart + customAreas.count {
            let area = customAreas[indexPath.row - customStart]
            let cell = tableView.dequeueReusableCell(withIdentifier: "areaCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = area
            config.textProperties.font = UIFont.systemFont(ofSize: 17)
            cell.contentConfiguration = config
            cell.accessoryType = selected.contains(area) ? .checkmark : .none
            cell.selectionStyle = .default
            return cell
        }

        // final row: "Add custom..."
        let cell = tableView.dequeueReusableCell(withIdentifier: "areaCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = "Add custom..."
        config.textProperties.font = UIFont.systemFont(ofSize: 17)
        // <- changed from .systemPurple to a system grey-friendly color so it matches the rest of the UI
        config.textProperties.color = .secondaryLabel
        cell.contentConfiguration = config
        cell.accessoryType = .none
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let topCount = topAreas.count
        let customStart = topCount
        let addRowIndex = topCount + customAreas.count

        // builtin area tapped
        if indexPath.row < topCount {
            let area = topAreas[indexPath.row]
            toggleSelection(for: area)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        // existing custom area tapped
        if indexPath.row < addRowIndex {
            let area = customAreas[indexPath.row - customStart]
            toggleSelection(for: area)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        // "Add custom..." tapped -> show alert with text field
        if indexPath.row == addRowIndex {
            presentAddCustomAlert()
        }
    }

    private func toggleSelection(for area: String) {
        if selected.contains(area) {
            selected.remove(area)
        } else {
            selected.insert(area)
        }
    }

    private func presentAddCustomAlert() {
        let ac = UIAlertController(title: "Add custom area", message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "e.g. Casting"
            tf.autocapitalizationType = .words
        }
        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self, let txt = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !txt.isEmpty else { return }

            // avoid duplicates (case-insensitive)
            let lower = txt.lowercased()
            if self.topAreas.contains(where: { $0.lowercased() == lower }) ||
               self.customAreas.contains(where: { $0.lowercased() == lower }) {
                // duplicate: ignore for now (could show a warning)
                return
            }

            // append custom area, select it, and insert the row before the Add row
            self.customAreas.append(txt)
            self.selected.insert(txt)
            let insertedIndex = IndexPath(row: self.topAreas.count + self.customAreas.count - 1, section: 0)
            self.tableView.insertRows(at: [insertedIndex], with: .automatic)

            // scroll to the newly added item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.tableView.scrollToRow(at: insertedIndex, at: .middle, animated: true)
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    @objc private func doneTapped() {
        completion?(Array(selected))
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - AddSlotViewController (CUSTOM CALENDAR)
final class AddSlotViewController: UIViewController {

    // public completion to return chosen Date
    var completion: ((Date) -> Void)?

    private let brandColor: UIColor
    private var currentMonth: Date
    private var selectedDate: Date
    private var calendar = Calendar.current

    // Collection sizing helpers
    private var collectionViewHeightConstraint: NSLayoutConstraint?
    private let dayCellHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 8

    // UI
    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private let timePicker: UIDatePicker = {
        let tp = UIDatePicker()
        tp.datePickerMode = .time
        if #available(iOS 13.4, *) {
            tp.preferredDatePickerStyle = .compact
        }
        tp.translatesAutoresizingMaskIntoConstraints = false
        return tp
    }()
    private lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Slot", for: .normal)
        b.backgroundColor = brandColor
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    // init with brand color and optional initial date
    init(initialDate: Date = Date(), brand: UIColor) {
        self.brandColor = brand
        self.currentMonth = calendar.startOfMonth(for: initialDate)
        self.selectedDate = initialDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Availability"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))

        setupHeader()
        setupCollection()
        setupLayout()
        timePicker.tintColor = brandColor

        // initial height calculation & layout
        updateCollectionHeight()
    }

    private func setupHeader() {
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        monthLabel.textAlignment = .left
        monthLabel.text = monthTitle(for: currentMonth)

        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = UIFont.systemFont(ofSize: 26)
        prevButton.setTitleColor(brandColor, for: .normal)
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 26)
        nextButton.setTitleColor(brandColor, for: .normal)
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
    }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = rowSpacing
        layout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: DayCell.reuseID)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    private func setupLayout() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)

        header.addSubview(monthLabel)
        header.addSubview(prevButton)
        header.addSubview(nextButton)

        container.addSubview(collectionView)

        // weekday labels row
        let weekdayStack = UIStackView()
        weekdayStack.translatesAutoresizingMaskIntoConstraints = false
        weekdayStack.axis = .horizontal
        weekdayStack.distribution = .fillEqually

        // Use calendar's shortWeekdaySymbols (locale aware)
        let symbols = calendar.shortWeekdaySymbols.map { $0.uppercased() }
        for s in symbols {
            let l = UILabel()
            l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            l.textColor = .secondaryLabel
            l.textAlignment = .center
            l.text = s
            weekdayStack.addArrangedSubview(l)
        }
        container.addSubview(weekdayStack)

        // timeRow
        let timeRow = UIView()
        timeRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(timeRow)
        timeRow.addSubview(timePicker)

        container.addSubview(addButton)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            monthLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -12),
            prevButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            weekdayStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            weekdayStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            weekdayStack.topAnchor.constraint(equalTo: header.bottomAnchor),

            // collectionView top/leading/trailing (height will be set by constraint)
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 6),

            timeRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            timeRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timeRow.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 12),
            timeRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            timePicker.trailingAnchor.constraint(equalTo: timeRow.trailingAnchor),
            timePicker.centerYAnchor.constraint(equalTo: timeRow.centerYAnchor),

            addButton.topAnchor.constraint(equalTo: timeRow.bottomAnchor, constant: 28),
            addButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addButton.heightAnchor.constraint(equalToConstant: 52),

            addButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        // create & store the height constraint (value will be updated)
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 200)
        collectionViewHeightConstraint?.isActive = true
    }

    // month title helper
    private func monthTitle(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date)
    }

    @objc private func prevMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        monthLabel.text = monthTitle(for: currentMonth)
        updateCollectionHeight()
    }

    @objc private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        monthLabel.text = monthTitle(for: currentMonth)
        updateCollectionHeight()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func addTapped() {
        // Compose selectedDate (date-only) with chosen time
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)
        var comps = DateComponents()
        comps.year = dateComponents.year
        comps.month = dateComponents.month
        comps.day = dateComponents.day
        comps.hour = timeComponents.hour
        comps.minute = timeComponents.minute
        let final = calendar.date(from: comps) ?? selectedDate
        completion?(final)
        dismiss(animated: true)
    }

    // compute how many rows (weeks) needed for the current month
    private func monthRows(for month: Date) -> Int {
        let firstOfMonth = month
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) // 1=Sun
        let blanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let days = calendar.range(of: .day, in: .month, for: month)!.count
        let totalSlots = blanks + days
        return Int(ceil(Double(totalSlots) / 7.0))
    }

    private func updateCollectionHeight() {
        let rows = monthRows(for: currentMonth)
        let totalHeight = CGFloat(rows) * dayCellHeight + CGFloat(max(0, rows - 1)) * rowSpacing + collectionView.contentInset.top + collectionView.contentInset.bottom
        collectionViewHeightConstraint?.constant = totalHeight
        collectionView.reloadData()
        view.layoutIfNeeded()
    }
}

// MARK: - Collection View (calendar grid)
extension AddSlotViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // We show a 7-column grid for the month.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of slots = leading blanks + days in month
        let firstOfMonth = currentMonth
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) // 1 = Sun
        let leadingBlanks = weekdayOfFirst - calendar.firstWeekday
        // normalize to 0..6
        let blanks = (leadingBlanks + 7) % 7
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        return blanks + range.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.reuseID, for: indexPath) as! DayCell

        // compute day for this index
        let firstOfMonth = currentMonth
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let blanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayIndex = indexPath.item - blanks + 1

        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        if dayIndex >= 1 && dayIndex <= range.count {
            var comps = calendar.dateComponents([.year, .month], from: currentMonth)
            comps.day = dayIndex
            let date = calendar.date(from: comps)!
            cell.configure(day: dayIndex, isSelected: calendar.isDate(date, inSameDayAs: selectedDate), brand: brandColor, isInMonth: true)
        } else {
            cell.configureEmpty()
        }

        return cell
    }

    // cell size - divide width into 7 columns with some spacing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let available = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let w = floor(available / 7.0)
        return CGSize(width: w, height: dayCellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // compute day for this index
        let firstOfMonth = currentMonth
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let blanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayIndex = indexPath.item - blanks + 1
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!

        guard dayIndex >= 1 && dayIndex <= range.count else { return }

        var comps = calendar.dateComponents([.year, .month], from: currentMonth)
        comps.day = dayIndex
        if let date = calendar.date(from: comps) {
            // set selected and reload visible cells — this provides immediate, consistent filled styling
            selectedDate = date
            collectionView.reloadData()
        }
    }
}

// MARK: - Day cell
private final class DayCell: UICollectionViewCell {

    static let reuseID = "DayCell"

    private let dayLabel = UILabel()
    private let circleView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(circleView)
        contentView.addSubview(dayLabel)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints = false

        dayLabel.textAlignment = .center
        dayLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 36),
            circleView.heightAnchor.constraint(equalToConstant: 36),

            dayLabel.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])

        circleView.layer.cornerRadius = 18
        circleView.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int, isSelected: Bool, brand: UIColor, isInMonth: Bool) {
        dayLabel.text = "\(day)"
        dayLabel.textColor = isInMonth ? .label : .secondaryLabel

        if isSelected {
            circleView.backgroundColor = brand
            dayLabel.textColor = .white
            circleView.isHidden = false
        } else {
            circleView.backgroundColor = .clear
            circleView.isHidden = true
            dayLabel.textColor = .label
        }
    }

    func configureEmpty() {
        dayLabel.text = ""
        circleView.isHidden = true
    }
}

// MARK: - Calendar helpers
private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = self.dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = paddingView
        leftViewMode = .always
    }

    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        rightView = paddingView
        rightViewMode = .always
    }
}

// MARK: - Minimal cells (TextFieldCell, TextViewCell, PickerCell, AvatarCell)
final class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    private let textField: UITextField = {
        let tf = UITextField()
        tf.clearButtonMode = .whileEditing
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.92)
        tf.layer.cornerRadius = 14
        tf.layer.borderWidth = 1
        tf.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        tf.textColor = CineMystTheme.ink
        tf.tintColor = CineMystTheme.brandPlum
        return tf
    }()
    private var changeHandler: ((String?) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 6),
            textField.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -6),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
        textField.delegate = self
        selectionStyle = .none
        backgroundColor = .clear
        textField.setLeftPaddingPoints(14)
        textField.setRightPaddingPoints(14)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(placeholder: String, text: String?, onChange: @escaping (String?) -> Void) {
        textField.placeholder = placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: CineMystTheme.brandPlum.withAlphaComponent(0.42)]
        )
        textField.text = text
        changeHandler = onChange
    }
    func textFieldDidEndEditing(_ textField: UITextField) { changeHandler?(textField.text) }
}

final class TextViewCell: UITableViewCell, UITextViewDelegate {
    private let textView = UITextView()
    private var changeHandler: ((String?) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.layer.cornerRadius = 14
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.92)
        textView.tintColor = CineMystTheme.brandPlum
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
        textView.delegate = self
        selectionStyle = .none
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(text: String?, placeholder: String = "", onChange: @escaping (String?) -> Void) {
        changeHandler = onChange
        if let t = text, !t.isEmpty { textView.text = t; textView.textColor = CineMystTheme.ink }
        else { textView.text = placeholder; textView.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.42) }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor != CineMystTheme.ink { textView.text = ""; textView.textColor = CineMystTheme.ink }
    }
    func textViewDidEndEditing(_ textView: UITextView) { changeHandler?(textView.text) }
}

final class PickerCell: UITableViewCell {
    private var datePicker: UIDatePicker?
    private var handler: ((Date) -> Void)?
    func configureAsDatePicker(mode: UIDatePicker.Mode, date: Date, onChange: @escaping (Date) -> Void) {
        handler = onChange
        if datePicker == nil {
            let dp = UIDatePicker()
            dp.datePickerMode = mode
            if #available(iOS 13.4, *) { dp.preferredDatePickerStyle = .inline }
            dp.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(dp)
            NSLayoutConstraint.activate([
                dp.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                dp.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                dp.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
                dp.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
            ])
            dp.tintColor = CineMystTheme.brandPlum
            dp.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
            datePicker = dp
        }
        datePicker?.date = date
        backgroundColor = .clear
    }
    @objc private func valueChanged(_ dp: UIDatePicker) { handler?(dp.date) }
}

final class ActionRowCell: UITableViewCell {
    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        view.layer.masksToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        return stack
    }()

    private let chevronView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "chevron.right"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.42)
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        view.contentMode = .scaleAspectFit
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .default

        let selected = UIView()
        selected.backgroundColor = CineMystTheme.plumMist.withAlphaComponent(0.85)
        selected.layer.cornerRadius = 16
        selected.layer.masksToBounds = true
        selectedBackgroundView = selected

        contentView.addSubview(cardView)
        cardView.addSubview(textStack)
        cardView.addSubview(chevronView)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -6),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
            chevronView.heightAnchor.constraint(equalToConstant: 16),

            textStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String?, titleColor: UIColor, subtitleColor: UIColor, showChevron: Bool) {
        titleLabel.text = title
        titleLabel.textColor = titleColor
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.isHidden = (subtitle?.isEmpty ?? true)
        chevronView.isHidden = !showChevron
        textStack.spacing = subtitleLabel.isHidden ? 0 : 4
    }
}

final class AvatarCell: UITableViewCell {
    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.10).cgColor
        view.layer.masksToBounds = true
        return view
    }()

    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabelView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = CineMystTheme.ink
        return label
    }()

    private let subtitleLabelView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        return label
    }()

    private let chevronView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "chevron.right"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.42)
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        view.contentMode = .scaleAspectFit
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(previewImageView)
        cardView.addSubview(titleLabelView)
        cardView.addSubview(subtitleLabelView)
        cardView.addSubview(chevronView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -6),

            previewImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            previewImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            previewImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            previewImageView.widthAnchor.constraint(equalToConstant: 60),
            previewImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabelView.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 14),
            titleLabelView.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -12),
            titleLabelView.topAnchor.constraint(equalTo: previewImageView.topAnchor, constant: 6),

            subtitleLabelView.leadingAnchor.constraint(equalTo: titleLabelView.leadingAnchor),
            subtitleLabelView.trailingAnchor.constraint(equalTo: titleLabelView.trailingAnchor),
            subtitleLabelView.topAnchor.constraint(equalTo: titleLabelView.bottomAnchor, constant: 4),

            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
            chevronView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(image: UIImage?, onTap: @escaping () -> Void) {
        if let img = image {
            previewImageView.image = img
            previewImageView.tintColor = nil
            titleLabelView.text = "Using your profile photo"
            subtitleLabelView.text = "Tap to replace it for your mentor profile"
        } else {
            previewImageView.image = UIImage(systemName: "person.crop.circle.fill")
            previewImageView.tintColor = CineMystTheme.brandPlum.withAlphaComponent(0.45)
            titleLabelView.text = "Upload profile photo"
            subtitleLabelView.text = "Choose the picture you want mentees to see"
        }
    }
}

final class MentorCelebrationViewController: UIViewController {
    var onContinue: (() -> Void)?

    private let titleText: String
    private let messageText: String

    private let dimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.alpha = 0
        return view
    }()

    private let cardView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 28
        view.layer.masksToBounds = true
        return view
    }()

    private let glowView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 0.12)
        return view
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        view.layer.cornerRadius = 34
        return view
    }()

    private let badgeIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "sparkles"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = titleText
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = messageText
        return label
    }()

    private let continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Let’s go"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let emitterLayer = CAEmitterLayer()

    init(titleText: String, messageText: String) {
        self.titleText = titleText
        self.messageText = messageText
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(dimView)
        view.addSubview(cardView)
        cardView.contentView.addSubview(glowView)
        cardView.contentView.addSubview(badgeView)
        badgeView.addSubview(badgeIcon)
        cardView.contentView.addSubview(titleLabel)
        cardView.contentView.addSubview(messageLabel)
        cardView.contentView.addSubview(continueButton)

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            glowView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            glowView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            glowView.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor),
            glowView.heightAnchor.constraint(equalToConstant: 120),

            badgeView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor, constant: 28),
            badgeView.centerXAnchor.constraint(equalTo: cardView.contentView.centerXAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 68),
            badgeView.heightAnchor.constraint(equalToConstant: 68),

            badgeIcon.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeIcon.widthAnchor.constraint(equalToConstant: 28),
            badgeIcon.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -24),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            continueButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 28),
            continueButton.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -28),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.bottomAnchor.constraint(equalTo: cardView.contentView.bottomAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runEntranceAnimation()
        fireConfetti()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitterLayer.emitterSize = CGSize(width: view.bounds.width, height: 2)
    }

    private func runEntranceAnimation() {
        cardView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88).concatenating(CGAffineTransform(translationX: 0, y: 24))
        cardView.alpha = 0
        UIView.animate(withDuration: 0.22) {
            self.dimView.alpha = 1
        }
        UIView.animate(withDuration: 0.52,
                       delay: 0.02,
                       usingSpringWithDamping: 0.78,
                       initialSpringVelocity: 0.72,
                       options: [.curveEaseOut]) {
            self.cardView.transform = .identity
            self.cardView.alpha = 1
        }
    }

    private func fireConfetti() {
        let colors: [UIColor] = [
            UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1),
            UIColor.systemPink,
            UIColor.systemYellow,
            UIColor.systemOrange
        ]

        emitterLayer.emitterShape = .line
        emitterLayer.birthRate = 1
        emitterLayer.beginTime = CACurrentMediaTime()

        emitterLayer.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 5
            cell.lifetime = 5.0
            cell.velocity = 180
            cell.velocityRange = 90
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 6
            cell.spin = 3.5
            cell.spinRange = 4
            cell.scale = 0.45
            cell.scaleRange = 0.18
            cell.color = color.cgColor
            cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
            return cell
        }

        view.layer.insertSublayer(emitterLayer, above: dimView.layer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.emitterLayer.birthRate = 0
        }
    }

    @objc private func continueTapped() {
        dismiss(animated: true) {
            self.onContinue?()
        }
    }
}
