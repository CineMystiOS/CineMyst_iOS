//
//  ScheduleSessionViewController.swift
//  CineMystApp
//
//  Updated: picker sheet toolbar aligned directly under grabber (no large gap).
//           Mentorship area now allows multiple selection.
//           Removed attach materials section and moved heading into navigation bar
//           Align "Available Time" to match other section titles.
//
//  Screenshot for reference:
//  /mnt/data/83855070-6969-4990-9a71-eac19924fdc5.png
//

import UIKit
import UniformTypeIdentifiers
import ObjectiveC

// Mentorship areas are now driven from the backend (fetched at runtime)

final class ScheduleSessionViewController: UIViewController {

    // MARK: - Theme
    private let plum = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1.0)
    private let accentGray = UIColor(white: 0.4, alpha: 1.0)

    // MARK: - State
    /// Allow multiple selection now - areas are dynamic strings (names)
    private var fetchedAreas: [String] = []
    private var selectedAreas: Set<String> = []
    /// If set by the caller, only these areas will be shown (from the mentor's profile)
    public var allowedAreas: [String]? = nil
    /// Optional mentor passed from the detail screen so downstream flows can use it
    public var mentor: Mentor? = nil
    private var selectedTimeButton: UIButton?
    /// Date will be nil until user explicitly picks a date via the sheet
    private var selectedDate: Date?

    // MARK: - UI (keep references for insertion)
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var mainStack: UIStackView!               // main content stack (we'll insert into this)
    private var headerRow: UIView!                    // header row (date header + chevron), used as insertion anchor

    // Mentorship chips
    private let mentorshipTitle = ScheduleSessionViewController.sectionTitle("Mentorship Area")
    private let mentorshipStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        return s
    }()

    // Choose Date header + chevron (compact)
    private let chooseDateTitle = ScheduleSessionViewController.sectionTitle("Choose Date")

    private lazy var dateHeaderButton: UIButton = {
        let b = UIButton(type: .system)
        b.contentHorizontalAlignment = .left
        b.tintColor = .label
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.label, for: .normal)
        b.addTarget(self, action: #selector(presentDatePickerSheet), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var headerChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // Available times — created now but NOT added to the mainStack until date is chosen
    private let availableTitle: UILabel = {
        let l = ScheduleSessionViewController.sectionTitle("Available Time")
        l.isHidden = false // we'll manage visibility by presence in stack
        l.alpha = 0.0
        return l
    }()
    private let timeSlotsScroll: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alpha = 0.0
        return sv
    }()
    private let timeSlotsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 12
        s.distribution = .fillProportionally
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Info box
    private let infoBox: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        v.layer.cornerRadius = 14
        return v
    }()
    private let infoTitle: UILabel = {
        let l = UILabel()
        l.text = "Session Information"
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .systemBlue
        return l
    }()
    private let infoBullets: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemBlue
        l.text = """
• Google Meet link will be sent to your email
• Cancellation allowed up to 24 hours before
"""
        return l
    }()

    // Bottom book button
    private let bookButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Book Session"
        c.cornerStyle = .capsule
        c.baseForegroundColor = .white
        let b = UIButton(configuration: c)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        // Move heading into navigation bar so it lines up with the back arrow
        navigationItem.title = "Schedule Session"
        // Use compact title (single-line) so it stays aligned with the back button
        if #available(iOS 14.0, *) { navigationItem.backButtonDisplayMode = .minimal }

        view.tintColor = accentGray
        setupLayout()
    Task { await loadMentorshipAreas() }
        wireActions()

        // start with no date chosen -> no timeSlots in the stack
        updateDateHeaderTitle()
    }

    private func loadMentorshipAreas() async {
        // If the caller provided allowed areas (from the mentor detail), use them directly.
        if let allowed = allowedAreas, !allowed.isEmpty {
            let sorted = allowed.sorted()
            DispatchQueue.main.async {
                self.fetchedAreas = sorted
                self.buildMentorshipChips()
            }
            return
        }

        // fetch mentors and extract unique areas (fallback)
        let mentors = await MentorsProvider.fetchAll()
        var areasSet: Set<String> = []
        for m in mentors {
            if let a = m.mentorshipAreas {
                for item in a { areasSet.insert(item) }
            }
        }
        let sorted = Array(areasSet).sorted()
        DispatchQueue.main.async {
            self.fetchedAreas = sorted
            self.buildMentorshipChips()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide tabbar & floating button while inside scheduling flow
        tabBarController?.tabBar.isHidden = true

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // restore
        tabBarController?.tabBar.isHidden = false

    }

    // MARK: - Mentorship chips
    private func buildMentorshipChips() {
        mentorshipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (idx, area) in fetchedAreas.enumerated() {
            let btn = makeChipButton(title: area)
            btn.tag = 1000 + idx // offset to avoid collisions
            // reflect any previously selected areas (if restoring state)
            if selectedAreas.contains(area) { setChip(btn, selected: true) }
            mentorshipStack.addArrangedSubview(btn)
        }
    }

    private func makeChipButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15)
        b.setTitleColor(accentGray, for: .normal)
        b.contentHorizontalAlignment = .left
        b.contentEdgeInsets = .init(top: 10, left: 14, bottom: 10, right: 14)
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.separator.cgColor
        b.addTarget(self, action: #selector(chooseMentorship(_:)), for: .touchUpInside)
        return b
    }

    @objc private func chooseMentorship(_ sender: UIButton) {
        // Toggle selection for multi-select behavior
        let isCurrentlySelected = sender.backgroundColor == plum.withAlphaComponent(0.10)
        let idx = sender.tag - 1000
        guard idx >= 0 && idx < fetchedAreas.count else { return }
        let area = fetchedAreas[idx]
        if isCurrentlySelected {
            // deselect
            setChip(sender, selected: false)
            selectedAreas.remove(area)
        } else {
            // select (do NOT clear other selections)
            setChip(sender, selected: true)
            selectedAreas.insert(area)
        }
    }

    private func setChip(_ b: UIButton, selected: Bool) {
        if selected {
            b.backgroundColor = plum.withAlphaComponent(0.10)
            b.layer.borderColor = plum.cgColor
            b.setTitleColor(plum, for: .normal)
        } else {
            b.backgroundColor = .clear
            b.layer.borderColor = UIColor.separator.cgColor
            b.setTitleColor(accentGray, for: .normal)
        }
    }


    // MARK: - Actions wiring
    private func wireActions() {
        bookButton.addTarget(self, action: #selector(didTapFinalBook), for: .touchUpInside)
    }

    @objc private func didTapFinalBook() {
        guard !selectedAreas.isEmpty else {
            return alert("Choose mentorship area", "Please select at least one mentorship area to continue.")
        }
        guard let chosenDate = selectedDate else {
            return alert("Choose a date", "Please select a date to view and choose available times.")
        }
        guard let selectedTimeButton else {
            return alert("Pick a time", "Please choose an available time slot.")
        }

    // Preserve a stable ordering by sorting selected areas alphabetically
    let selectedOrdered = Array(selectedAreas).sorted()
    let areaString = selectedOrdered.joined(separator: ", ")

    let vc = PaymentViewController(area: areaString, date: chosenDate, time: selectedTimeButton.currentTitle ?? "")
    vc.mentor = self.mentor
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Present date picker sheet
    @objc private func presentDatePickerSheet() {
        // Build container VC
        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = .systemBackground
        pickerVC.modalPresentationStyle = .pageSheet

        // DatePicker
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        if #available(iOS 13.4, *) { picker.preferredDatePickerStyle = .wheels } // or .inline if you prefer
        picker.minimumDate = Date()
        picker.date = selectedDate ?? Date()
        picker.translatesAutoresizingMaskIntoConstraints = false

        // Toolbar with Cancel / Done
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        // keep toolbar non-translucent so it visually matches sheet background
        toolbar.isTranslucent = false

        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didCancelDatePicker(_:)))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didFinishDatePicker(_:)))
        toolbar.setItems([cancel, flexible, done], animated: false)

        // Attach subviews
        pickerVC.view.addSubview(toolbar)
        pickerVC.view.addSubview(picker)

        // Layout:
        // Pin toolbar directly to the view's top (so it sits visually under the grabber).
        // Fix picker height and pin it below toolbar to eliminate extra vertical padding.
        let toolbarHeight: CGFloat = 44
        // standard wheel UIDatePicker height is typically ~216 on iPhone for .wheels style
        // keep as constant so sheet matches it exactly and no extra bottom padding remains
        let pickerHeight: CGFloat = 216

        NSLayoutConstraint.activate([
            // toolbar pinned to absolute top of the sheet's content view
            toolbar.topAnchor.constraint(equalTo: pickerVC.view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight),

            // picker pinned immediately under toolbar and set to fixed height
            picker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            picker.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: pickerHeight),

            // ensure the content view's bottom is aligned to the picker's bottom so sheet height is exact
            picker.bottomAnchor.constraint(equalTo: pickerVC.view.bottomAnchor)
        ])

        // Keep a reference to the picker so Done/Cancel handlers can access it easily.
        objc_setAssociatedObject(pickerVC, &AssociatedKeys.pickerKey, picker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // present as sheet (iOS 15+ deterministic detents)
        if let sheet = pickerVC.sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = false

            // Prefer an exact detent on iOS 16+ using custom detent when available
            if #available(iOS 16.0, *) {
                let targetHeight = toolbarHeight + pickerHeight
                let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("picker-detent")) { _ in
                    return targetHeight
                }
                sheet.detents = [customDetent]
            } else {
                // fallback for iOS 15: use medium/large but set preferredContentSize so the system attempts to size tightly
                pickerVC.preferredContentSize = CGSize(width: view.bounds.width, height: toolbarHeight + pickerHeight)
                sheet.detents = [.medium(), .large()]
            }
        } else {
            // fallback: set preferredContentSize
            pickerVC.preferredContentSize = CGSize(width: view.bounds.width, height: toolbarHeight + pickerHeight)
        }

        present(pickerVC, animated: true, completion: nil)
    }


    // Cancel tapped: just dismiss
    @objc private func didCancelDatePicker(_ sender: Any) {
        dismissPresentedDatePicker()
    }

    // Done tapped: grab the picker from the presented VC and update state
    @objc private func didFinishDatePicker(_ sender: Any) {
        guard let presented = presentedViewController,
              let picker = objc_getAssociatedObject(presented, &AssociatedKeys.pickerKey) as? UIDatePicker else {
            dismissPresentedDatePicker()
            return
        }
        // user explicitly picked a date — record it and reveal time slots by inserting views
        selectedDate = picker.date
        updateDateHeaderTitle()
        showTimeSlots(for: picker.date)
        addTimeSlotsSectionIfNeeded(animated: true)
        dismissPresentedDatePicker()
    }

    private func dismissPresentedDatePicker() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Date header title update
    private func updateDateHeaderTitle() {
        if let chosen = selectedDate {
            // show a readable month/year (matching earlier design)
            let fmt = DateFormatter()
            fmt.dateFormat = "LLLL yyyy"
            let monthTitle = fmt.string(from: chosen)
            dateHeaderButton.setTitle("\(monthTitle)  ›", for: .normal)
        } else {
            // when not chosen yet, invite the user
            dateHeaderButton.setTitle("Select a date  ›", for: .normal)
        }
    }

    // MARK: - Time slots
    private func showTimeSlots(for date: Date) {
        // clear previous slots
        timeSlotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        selectedTimeButton = nil

        let slots = generatedSlots(for: date)
        for s in slots {
            let b = UIButton(type: .system)
            b.setTitle(s, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 14)
            b.setTitleColor(accentGray, for: .normal)
            b.layer.cornerRadius = 16
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.separator.cgColor
            b.contentEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 12)
            b.addTarget(self, action: #selector(selectTime(_:)), for: .touchUpInside)
            timeSlotsStack.addArrangedSubview(b)
        }
    }

    @objc private func selectTime(_ sender: UIButton) {
        if let prev = selectedTimeButton {
            prev.backgroundColor = .clear
            prev.setTitleColor(accentGray, for: .normal)
            prev.layer.borderColor = UIColor.separator.cgColor
        }
        selectedTimeButton = sender
        sender.backgroundColor = plum
        sender.setTitleColor(.white, for: .normal)
        sender.layer.borderColor = plum.cgColor
    }

    private func generatedSlots(for date: Date) -> [String] {
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday == 1 || weekday == 7) ? ["10:00 am", "1:00 pm", "3:00 pm"] : ["9:00 am", "11:00 am"]
    }

    // Insert the availableTitle + timeSlotsScroll into the main stack right under headerRow.
    // If already present, do nothing. Animate insertion for a smooth effect.
    private func addTimeSlotsSectionIfNeeded(animated: Bool) {
        // if availableTitle is already present in stack, do nothing
        if mainStack.arrangedSubviews.contains(where: { $0 === availableTitle }) {
            // already added
            // ensure the scroll has layout (in case it was added earlier)
            return
        }

        // find index of headerRow to insert after it
        guard let headerIndex = mainStack.arrangedSubviews.firstIndex(where: { $0 === headerRow }) else {
            // fallback: append at end (with spacer)
            mainStack.addArrangedSubview(UIView(height: 12))
            mainStack.addArrangedSubview(availableTitle)
            mainStack.addArrangedSubview(timeSlotsScroll)
            return
        }

        // prepare timeSlotsScroll content if not already done
        if timeSlotsScroll.superview == nil {
            timeSlotsScroll.addSubview(timeSlotsStack)
            NSLayoutConstraint.activate([
                timeSlotsStack.topAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.topAnchor),
                timeSlotsStack.bottomAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.bottomAnchor),
                timeSlotsStack.leadingAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.leadingAnchor, constant: 8),
                timeSlotsStack.trailingAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.trailingAnchor, constant: -8),
                timeSlotsStack.heightAnchor.constraint(equalTo: timeSlotsScroll.frameLayoutGuide.heightAnchor)
            ])
        }

        // Insert a fixed spacer, then availableTitle, then timeSlotsScroll.
        // This guarantees consistent vertical gap between the headerRow and the Available Time section.
        let spacer = UIView(height: 12)

        let insertIndex = headerIndex + 1
        mainStack.insertArrangedSubview(spacer, at: insertIndex)
        mainStack.insertArrangedSubview(availableTitle, at: insertIndex + 1)
        mainStack.insertArrangedSubview(timeSlotsScroll, at: insertIndex + 2)

        // Ensure availableTitle and timeSlotsScroll align to the same leading/trailing as other section titles
        availableTitle.translatesAutoresizingMaskIntoConstraints = false
        timeSlotsScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            availableTitle.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            availableTitle.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),

            timeSlotsScroll.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            timeSlotsScroll.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            // give the horizontal time slots a reasonable fixed height so the stack sizes predictably
            timeSlotsScroll.heightAnchor.constraint(equalToConstant: 46)
        ])

        // set initial alpha to 0 and then animate to 1
        availableTitle.alpha = 0.0
        timeSlotsScroll.alpha = 0.0
        timeSlotsScroll.isHidden = false

        if animated {
            UIView.animate(withDuration: 0.28) {
                self.availableTitle.alpha = 1.0
                self.timeSlotsScroll.alpha = 1.0
                self.view.layoutIfNeeded()
            }
        } else {
            availableTitle.alpha = 1.0
            timeSlotsScroll.alpha = 1.0
            view.layoutIfNeeded()
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        // Bottom button
        view.addSubview(bookButton)
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bookButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bookButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bookButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        bookButton.configuration?.baseBackgroundColor = plum

        // ScrollView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bookButton.topAnchor, constant: -12)
        ])

        // Content view
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Info box internals
        infoBox.addSubview(infoTitle)
        infoBox.addSubview(infoBullets)
        infoTitle.translatesAutoresizingMaskIntoConstraints = false
        infoBullets.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoTitle.topAnchor.constraint(equalTo: infoBox.topAnchor, constant: 12),
            infoTitle.leadingAnchor.constraint(equalTo: infoBox.leadingAnchor, constant: 12),
            infoBullets.topAnchor.constraint(equalTo: infoTitle.bottomAnchor, constant: 6),
            infoBullets.leadingAnchor.constraint(equalTo: infoBox.leadingAnchor, constant: 12),
            infoBullets.trailingAnchor.constraint(equalTo: infoBox.trailingAnchor, constant: -12),
            infoBullets.bottomAnchor.constraint(equalTo: infoBox.bottomAnchor, constant: -12)
        ])

        // Build headerRow (store as property so we can insert after it later)
        headerRow = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(dateHeaderButton)
        headerRow.addSubview(headerChevron)
        NSLayoutConstraint.activate([
            dateHeaderButton.topAnchor.constraint(equalTo: headerRow.topAnchor),
            dateHeaderButton.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor),
            dateHeaderButton.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            dateHeaderButton.trailingAnchor.constraint(equalTo: headerChevron.leadingAnchor, constant: -8),

            headerChevron.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            headerChevron.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor, constant: -4),
            headerChevron.widthAnchor.constraint(equalToConstant: 14)
        ])

        // Add a tap recognizer to headerRow as a fallback and increase hit area
        let headerTap = UITapGestureRecognizer(target: self, action: #selector(presentDatePickerSheet))
        headerRow.addGestureRecognizer(headerTap)

        // Time slots scroll content (we set constraints now but don't add the scroll to the stack yet)
        timeSlotsScroll.addSubview(timeSlotsStack)
        NSLayoutConstraint.activate([
            timeSlotsStack.topAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.topAnchor),
            timeSlotsStack.bottomAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.bottomAnchor),
            timeSlotsStack.leadingAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.leadingAnchor, constant: 8),
            timeSlotsStack.trailingAnchor.constraint(equalTo: timeSlotsScroll.contentLayoutGuide.trailingAnchor, constant: -8),
            timeSlotsStack.heightAnchor.constraint(equalTo: timeSlotsScroll.frameLayoutGuide.heightAnchor)
        ])

        // Main content stack: NOTE we removed the Attach Materials UI per request
        mainStack = UIStackView(arrangedSubviews: [
            UIView(height: 8),
            mentorshipTitle,
            mentorshipStack,
            UIView(height: 12),
            chooseDateTitle,
            headerRow,
            UIView(height: 8),
            // availableTitle and timeSlotsScroll WILL be inserted later after headerRow
            UIView(height: 16),
            infoBox
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 10

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            infoBox.heightAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])
    }

    // MARK: - Helpers
    private static func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = UIColor(white: 0.15, alpha: 1.0)
        return l
    }

    private func alert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Associated object key for attaching picker to the presented VC
private struct AssociatedKeys {
    static var pickerKey = "schedule_picker_key"
}

// Spacer helper
private extension UIView {
    convenience init(height: CGFloat) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
