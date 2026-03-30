//
//  BecomeMentorViewController.swift
//  ProgrammaticMentorship
//
//  Full BecomeMentor + area selector + helpers (single-file)
//

import UIKit
import PhotosUI
import Supabase

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
        b.backgroundColor = brandColor
        b.layer.cornerRadius = 12
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        return b
    }()

    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Become a Mentor"
        navigationItem.largeTitleDisplayMode = .never

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: ID.textField)
        tableView.register(TextViewCell.self, forCellReuseIdentifier: ID.textView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ID.button)
        tableView.register(PickerCell.self, forCellReuseIdentifier: ID.picker)
        tableView.register(AvatarCell.self, forCellReuseIdentifier: ID.avatar)

        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .interactive

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 96))
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
                    for: indexPath)
                var config = cell.defaultContentConfiguration()
                config.text = form.years ?? "Experience"
                config.textProperties.color = .systemBlue
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
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
                )
                var config = cell.defaultContentConfiguration()
                config.text = "Select Mentorship Area(s)"
                config.secondaryText = form.mentorshipAreas.isEmpty
                    ? "No areas selected"
                    : "\(form.mentorshipAreas.count) selected"
                config.textProperties.color = .systemBlue
                cell.contentConfiguration = config
                return cell
            }

            let areaIndex = indexPath.row - 1
            let area = Array(form.mentorshipAreas.keys.sorted())[areaIndex]
            let price = form.mentorshipAreas[area] ?? "Set price"

            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.button,
                for: indexPath
            )
            var config = cell.defaultContentConfiguration()
            config.text = area
            config.secondaryText = price
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell

        // ----------------------
        // AVAILABILITY
        // ----------------------
        case .availability:

            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ID.button,
                    for: indexPath
                )
                var config = cell.defaultContentConfiguration()
                config.text = "Add Slot"
                config.textProperties.color = .systemBlue
                cell.contentConfiguration = config
                return cell
            }

            let idx = indexPath.row - 1
            let slotDate = form.slots[idx]

            let cell = tableView.dequeueReusableCell(
                withIdentifier: ID.button,
                for: indexPath
            )

            var config = cell.defaultContentConfiguration()
            config.text = formattedSlot(slotDate)
            config.textProperties.color = .label
            cell.selectionStyle = .none
            cell.contentConfiguration = config
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

        struct MentorInsert: Encodable {
            let display_name: String
            let name: String
            let role: String
            let about: String
            let mentorship_areas: [String]
            let metadata: [String: String]?
            let rating: Double
            let rating_count: Int
            let yoe: Int?
        }

        let insertItem = MentorInsert(
            display_name: form.fullName ?? "",
            name: form.fullName ?? "",
            role: form.professionalTitle ?? "",
            about: form.about ?? "",
            mentorship_areas: areas,
            metadata: metadataFlat.isEmpty ? nil : metadataFlat,
            rating: 0.0,
            rating_count: 0,
            yoe: mapYearsToYOE(form.years)
        )

        do {
            let res = try await supabase.database
                .from("mentor_profiles")
                .insert(insertItem)
                .select()
                .execute()

            // Ensure the insert returned rows (some SDKs embed errors instead of throwing).
            var returnedRows: [Any] = []
            if let rows = try? MentorsProvider.rowsArray(from: res.data) {
                returnedRows = rows
            }
            if returnedRows.isEmpty {
                await MainActor.run {
                    showAlert(title: "Save failed", message: "No rows returned from insert.")
                }
                return
            }

            // Success: navigate same as before
            await MainActor.run {
                showAlert(title: "Submitted", message: "Your profile has been submitted.") { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        // Create mentor panel
                        let mentorPanel = MentorPanelViewController()
                        if let tabBar = self.tabBarController {
                            let mentorshipIndex = 3
                            if mentorshipIndex < (tabBar.viewControllers?.count ?? 0),
                               let mentorNav = tabBar.viewControllers?[mentorshipIndex] as? UINavigationController {
                                let home = MentorshipHomeViewController()
                                mentorNav.setViewControllers([home, mentorPanel], animated: true)
                                tabBar.selectedIndex = mentorshipIndex
                                return
                            }
                            if let vcs = tabBar.viewControllers {
                                for (idx, vc) in vcs.enumerated() {
                                    if let nav = vc as? UINavigationController {
                                        nav.pushViewController(mentorPanel, animated: true)
                                        tabBar.selectedIndex = idx
                                        return
                                    }
                                }
                            }
                        }
                        if let nav = self.navigationController {
                            nav.pushViewController(mentorPanel, animated: true)
                            return
                        }
                        let modal = UINavigationController(rootViewController: mentorPanel)
                        modal.modalPresentationStyle = .fullScreen
                        self.present(modal, animated: true, completion: nil)
                    }
                }
            }
        } catch {
            await MainActor.run {
                showAlert(title: "Save failed", message: String(describing: error))
            }
        }
    }

    private func showAlert(title: String,
                           message: String,
                           completion: (() -> Void)? = nil) {

        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(ac, animated: true)
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

// MARK: - Minimal cells (TextFieldCell, TextViewCell, PickerCell, AvatarCell)
final class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    private let textField: UITextField = {
        let tf = UITextField()
        tf.clearButtonMode = .whileEditing
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.translatesAutoresizingMaskIntoConstraints = false
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
            textField.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -6)
        ])
        textField.delegate = self
        selectionStyle = .none
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(placeholder: String, text: String?, onChange: @escaping (String?) -> Void) {
        textField.placeholder = placeholder
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
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.backgroundColor = .secondarySystemBackground
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
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(text: String?, placeholder: String = "", onChange: @escaping (String?) -> Void) {
        changeHandler = onChange
        if let t = text, !t.isEmpty { textView.text = t; textView.textColor = .label }
        else { textView.text = placeholder; textView.textColor = .secondaryLabel }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .secondaryLabel { textView.text = ""; textView.textColor = .label }
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
            dp.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
            datePicker = dp
        }
        datePicker?.date = date
    }
    @objc private func valueChanged(_ dp: UIDatePicker) { handler?(dp.date) }
}

final class AvatarCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        if let img = imageView {
            img.translatesAutoresizingMaskIntoConstraints = false
            img.contentMode = .scaleAspectFill
            img.layer.cornerRadius = 20
            img.clipsToBounds = true
            NSLayoutConstraint.activate([ img.widthAnchor.constraint(equalToConstant: 40), img.heightAnchor.constraint(equalToConstant: 40) ])
        }
        textLabel?.font = .preferredFont(forTextStyle: .body)
        accessoryType = .disclosureIndicator
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(image: UIImage?, onTap: @escaping () -> Void) {
        if let img = image { imageView?.image = img; textLabel?.text = "Change photo" }
        else { imageView?.image = UIImage(systemName: "person.crop.circle.fill"); imageView?.tintColor = .systemGray3; textLabel?.text = "Upload profile photo"; textLabel?.textColor = .secondaryLabel }
    }
}
