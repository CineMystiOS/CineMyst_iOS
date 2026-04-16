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

// Mentorship areas are now driven from the backend (fetched at runtime)

final class ScheduleSessionViewController: UIViewController {

    private struct AvailabilitySlotRecord: Decodable {
        let start_at: String
        let end_at: String?
    }

    // MARK: - Theme
    private let plum = MentorshipUI.brandPlum
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
    private var selectedDate: Date?
    private var slotButtonDates: [Int: Date] = [:]
    private var nextSlotButtonTag: Int = 4000

    // MARK: - UI (keep references for insertion)
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var mainStack: UIStackView!

    // Mentorship chips
    private let mentorshipTitle = ScheduleSessionViewController.sectionTitle("Mentorship Area")
    private let mentorshipStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        return s
    }()

    private let availableSlotsTitle: UILabel = {
        let l = ScheduleSessionViewController.sectionTitle("Available Slots")
        return l
    }()
    private let availableDatesStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        return s
    }()

    // Info box
    private let infoBox: UIView = {
        let v = UIView()
        v.backgroundColor = MentorshipUI.plumChip
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = MentorshipUI.plumStroke.cgColor
        return v
    }()
    private let infoTitle: UILabel = {
        let l = UILabel()
        l.text = "Session Information"
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = MentorshipUI.brandPlum
        return l
    }()
    private let infoBullets: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 13)
        l.textColor = MentorshipUI.softText
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
        view.backgroundColor = MentorshipUI.pageBackground

        // Move heading into navigation bar so it lines up with the back arrow
        navigationItem.title = "Schedule Session"
        // Use compact title (single-line) so it stays aligned with the back button
        if #available(iOS 14.0, *) { navigationItem.backButtonDisplayMode = .minimal }

        view.tintColor = accentGray
        setupLayout()
        Task {
            await loadMentorshipAreas()
            await loadAvailableSlotCards()
        }
        wireActions()
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
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.contentHorizontalAlignment = .left
        b.contentEdgeInsets = .init(top: 13, left: 16, bottom: 13, right: 16)
        b.layer.cornerRadius = 16
        b.layer.borderWidth = 1
        b.layer.borderColor = MentorshipUI.plumStroke.cgColor
        b.backgroundColor = MentorshipUI.raisedSurface
        b.layer.shadowColor = MentorshipUI.shadow.cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.layer.shadowRadius = 10
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
            b.backgroundColor = MentorshipUI.plumChip
            b.layer.borderColor = plum.cgColor
            b.setTitleColor(plum, for: .normal)
            b.layer.shadowOpacity = 0
        } else {
            b.backgroundColor = MentorshipUI.raisedSurface
            b.layer.borderColor = MentorshipUI.plumStroke.cgColor
            b.setTitleColor(MentorshipUI.mutedText, for: .normal)
            b.layer.shadowOpacity = 1
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
            return alert("Choose a slot", "Please select one available date and time to continue.")
        }
        guard let selectedTimeButton else {
            return alert("Pick a time", "Please choose an available time slot.")
        }

    // Preserve a stable ordering by sorting selected areas alphabetically
    let selectedOrdered = Array(selectedAreas).sorted()
    let areaString = selectedOrdered.joined(separator: ", ")

    let vc = BookingConfirmationViewController()
    vc.mentor = self.mentor
    vc.scheduledDate = chosenDate
    vc.selectedArea = areaString
    vc.selectedTime = selectedTimeButton.currentTitle ?? ""
    vc.bookingAmountCents = 0 // Payment removed
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadAvailableSlotCards() async {
        await MainActor.run {
            self.availableDatesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            self.selectedDate = nil
            self.selectedTimeButton = nil
            self.slotButtonDates.removeAll()
            self.nextSlotButtonTag = 4000
        }

        guard let mentorId = mentor?.id else {
            await MainActor.run {
                self.availableDatesStack.addArrangedSubview(self.makeEmptySlotsLabel(text: "Mentor availability is not available right now"))
            }
            return
        }

        let slots = await fetchAvailabilitySlots(for: mentorId, on: nil)
        let futureSlots = slots.filter { $0 >= Date() }

        await MainActor.run {
            self.renderAvailableSlotCards(futureSlots)
        }
    }

    private func renderAvailableSlotCards(_ slots: [Date]) {
        availableDatesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        selectedTimeButton = nil
        selectedDate = nil
        slotButtonDates.removeAll()
        nextSlotButtonTag = 4000

        guard !slots.isEmpty else {
            availableDatesStack.addArrangedSubview(makeEmptySlotsLabel(text: "No available slots right now"))
            return
        }

        let grouped = Dictionary(grouping: slots) { Calendar.current.startOfDay(for: $0) }
        let orderedDays = grouped.keys.sorted()

        for day in orderedDays {
            guard let daySlots = grouped[day]?.sorted() else { continue }
            availableDatesStack.addArrangedSubview(makeDateCard(for: day, slots: daySlots))
        }
    }

    private func makeDateCard(for day: Date, slots: [Date]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.shadowRadius = 14

        let calendarBadge = UIView()
        calendarBadge.translatesAutoresizingMaskIntoConstraints = false
        calendarBadge.backgroundColor = plum.withAlphaComponent(0.08)
        calendarBadge.layer.cornerRadius = 16

        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        calendarIcon.tintColor = plum
        calendarIcon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM"
        title.text = dateFormatter.string(from: day)

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .systemFont(ofSize: 12, weight: .medium)
        subtitle.textColor = .secondaryLabel
        subtitle.text = "\(slots.count) slot\(slots.count == 1 ? "" : "s") available"

        let countPill = UIView()
        countPill.translatesAutoresizingMaskIntoConstraints = false
        countPill.backgroundColor = UIColor.secondarySystemBackground
        countPill.layer.cornerRadius = 13

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = plum
        countLabel.text = slots.count == 1 ? "1 slot" : "\(slots.count) slots"

        let chipsStack = UIStackView()
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.alignment = .leading

        let labelsStack = UIStackView(arrangedSubviews: [title, subtitle])
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical
        labelsStack.alignment = .leading
        labelsStack.spacing = 2

        let headerStack = UIStackView(arrangedSubviews: [calendarBadge, labelsStack, UIView(), countPill])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 12

        let chipsContainer = UIView()
        chipsContainer.translatesAutoresizingMaskIntoConstraints = false
        chipsContainer.addSubview(chipsStack)

        NSLayoutConstraint.activate([
            chipsStack.topAnchor.constraint(equalTo: chipsContainer.topAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsContainer.leadingAnchor),
            chipsStack.trailingAnchor.constraint(lessThanOrEqualTo: chipsContainer.trailingAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsContainer.bottomAnchor)
        ])

        for slot in slots {
            let button = UIButton(type: .system)
            button.setTitle(DateFormatter.localizedString(from: slot, dateStyle: .none, timeStyle: .short), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.setTitleColor(accentGray, for: .normal)
            button.backgroundColor = UIColor.secondarySystemBackground
            button.layer.cornerRadius = 17
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.contentEdgeInsets = .init(top: 9, left: 14, bottom: 9, right: 14)
            button.tag = nextSlotButtonTag
            slotButtonDates[nextSlotButtonTag] = slot
            nextSlotButtonTag += 1
            button.addTarget(self, action: #selector(selectTime(_:)), for: .touchUpInside)
            chipsStack.addArrangedSubview(button)
        }

        calendarBadge.addSubview(calendarIcon)
        countPill.addSubview(countLabel)
        card.addSubview(headerStack)
        card.addSubview(chipsContainer)

        NSLayoutConstraint.activate([
            calendarBadge.widthAnchor.constraint(equalToConstant: 32),
            calendarBadge.heightAnchor.constraint(equalToConstant: 32),

            calendarIcon.centerXAnchor.constraint(equalTo: calendarBadge.centerXAnchor),
            calendarIcon.centerYAnchor.constraint(equalTo: calendarBadge.centerYAnchor),
            calendarIcon.widthAnchor.constraint(equalToConstant: 16),
            calendarIcon.heightAnchor.constraint(equalToConstant: 16),

            countLabel.topAnchor.constraint(equalTo: countPill.topAnchor, constant: 6),
            countLabel.leadingAnchor.constraint(equalTo: countPill.leadingAnchor, constant: 10),
            countLabel.trailingAnchor.constraint(equalTo: countPill.trailingAnchor, constant: -10),
            countLabel.bottomAnchor.constraint(equalTo: countPill.bottomAnchor, constant: -6),

            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            headerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            chipsContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            chipsContainer.leadingAnchor.constraint(equalTo: headerStack.leadingAnchor),
            chipsContainer.trailingAnchor.constraint(equalTo: headerStack.trailingAnchor),
            chipsContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func makeEmptySlotsLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    private func fetchAvailabilitySlots(for mentorId: String, on date: Date?) async -> [Date] {
        do {
            let res = try await supabase.database
                .from("mentor_availability_slots")
                .select("start_at, end_at")
                .eq("mentor_id", value: mentorId)
                .eq("is_active", value: true)
                .order("start_at", ascending: true)
                .execute()

            let decoded = try JSONDecoder().decode([AvailabilitySlotRecord].self, from: res.data)
            return decoded.compactMap { Self.parseISODate($0.start_at) }
                .filter { slotDate in
                    guard let date else { return true }
                    return Calendar.current.isDate(slotDate, inSameDayAs: date)
                }
                .sorted()
        } catch {
            print("[ScheduleSession] fetchAvailabilitySlots error: \(error)")
            return []
        }
    }

    @objc private func selectTime(_ sender: UIButton) {
        if let prev = selectedTimeButton {
            prev.backgroundColor = .systemBackground
            prev.setTitleColor(accentGray, for: .normal)
            prev.layer.borderColor = UIColor.separator.cgColor
        }
        selectedTimeButton = sender
        sender.backgroundColor = plum
        sender.setTitleColor(.white, for: .normal)
        sender.layer.borderColor = plum.cgColor
        selectedDate = slotButtonDates[sender.tag]
    }

    private static func parseISODate(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
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

        // Main content stack: NOTE we removed the Attach Materials UI per request
        mainStack = UIStackView(arrangedSubviews: [
            UIView(height: 8),
            mentorshipTitle,
            mentorshipStack,
            UIView(height: 12),
            availableSlotsTitle,
            availableDatesStack,
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

// Spacer helper
private extension UIView {
    convenience init(height: CGFloat) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
