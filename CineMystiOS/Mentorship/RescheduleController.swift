//
// RescheduleViewController.swift
// CineMystApp
//
// Fixed: present confirmation from top-most controller and dismiss any existing alert before showing the custom card.
//

import UIKit

final class RescheduleViewController: UIViewController {

    // MARK: Public
    let session: SessionM
    /// called when user confirms reschedule: (newDate, selectedSlot)
    var onReschedule: ((Date, String) -> Void)?

    // MARK: Theme
    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Reschedule"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Select a new available date"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chooseDateButton: UIButton = {
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Choose date"
        cfg.baseForegroundColor = .label
        let b = UIButton(configuration: cfg)
        b.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let chosenDateLabel: UILabel = {
        let l = UILabel()
        l.text = "No date selected"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let slotsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Available Time Slots"
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let slotsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.alignment = .center
        s.distribution = .fillProportionally
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isHidden = true
        return s
    }()

    private let rescheduleButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Reschedule"
        cfg.cornerStyle = .capsule
        cfg.baseBackgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        cfg.baseForegroundColor = .white
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.isEnabled = false
        b.alpha = 0.55
        return b
    }()

    // internal state
    private var selectedDate: Date?
    private var selectedSlot: String?

    // MARK: init
    init(session: SessionM, onReschedule: ((Date, String) -> Void)? = nil) {
        self.session = session
        self.onReschedule = onReschedule
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        chooseDateButton.addTarget(self, action: #selector(chooseDateTapped), for: .touchUpInside)
        rescheduleButton.addTarget(self, action: #selector(rescheduleTapped), for: .touchUpInside)

        navigationItem.largeTitleDisplayMode = .never
    }

    // Hide tab bar while visible (if pushed)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    // Restore tab bar when leaving
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: layout
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(chooseDateButton)
        view.addSubview(chosenDateLabel)
        view.addSubview(slotsTitleLabel)
        view.addSubview(slotsStack)
        view.addSubview(rescheduleButton)

        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            chooseDateButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            chooseDateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            chooseDateButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pad),

            chosenDateLabel.centerYAnchor.constraint(equalTo: chooseDateButton.centerYAnchor),
            chosenDateLabel.leadingAnchor.constraint(equalTo: chooseDateButton.trailingAnchor, constant: 12),
            chosenDateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pad),

            slotsTitleLabel.topAnchor.constraint(equalTo: chooseDateButton.bottomAnchor, constant: 26),
            slotsTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            slotsStack.topAnchor.constraint(equalTo: slotsTitleLabel.bottomAnchor, constant: 12),
            slotsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            slotsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            slotsStack.heightAnchor.constraint(equalToConstant: 44),

            rescheduleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            rescheduleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            rescheduleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
    }

    // MARK: user actions
    @objc private func chooseDateTapped() {
        // date picker action sheet (wheels)
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)

        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        picker.translatesAutoresizingMaskIntoConstraints = false

        alert.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -8),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 6),
            picker.heightAnchor.constraint(equalToConstant: 216)
        ])

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let chosen = picker.date
            self.applyChosenDate(chosen)
        }))

        if let pop = alert.popoverPresentationController {
            pop.sourceView = chooseDateButton
            pop.sourceRect = chooseDateButton.bounds
            pop.permittedArrowDirections = .any
        }

        present(alert, animated: true)
    }

    private func applyChosenDate(_ date: Date) {
        selectedDate = date

        let df = DateFormatter()
        df.dateStyle = .medium
        chosenDateLabel.text = df.string(from: date)

        let slots = availableSlots(for: date)

        // clear previous and show slots
        slotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        slotsTitleLabel.isHidden = false
        slotsStack.isHidden = false

        for slot in slots {
            let btn = makePlainSlotButton(title: slot)
            slotsStack.addArrangedSubview(btn)
            btn.setContentHuggingPriority(.required, for: .horizontal)
        }

        selectedSlot = nil
        updateRescheduleButtonState()
    }

    private func makePlainSlotButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.label, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(slotTapped(_:)), for: .touchUpInside)
        return b
    }

    @objc private func slotTapped(_ sender: UIButton) {
        for case let btn as UIButton in slotsStack.arrangedSubviews {
            btn.backgroundColor = .clear
            btn.setTitleColor(.label, for: .normal)
            btn.layer.borderColor = UIColor.systemGray4.cgColor
        }

        sender.backgroundColor = plum
        sender.setTitleColor(.white, for: .normal)
        sender.layer.borderColor = UIColor.clear.cgColor

        selectedSlot = sender.title(for: .normal)
        updateRescheduleButtonState()
    }

    private func updateRescheduleButtonState() {
        let enabled = (selectedDate != nil && selectedSlot != nil)
        rescheduleButton.isEnabled = enabled
        UIView.animate(withDuration: 0.12) {
            self.rescheduleButton.alpha = enabled ? 1.0 : 0.55
        }
    }

    /// Helper: find top-most view controller in current window scene
    private func topMostController() -> UIViewController? {
        // Find key window
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
            let keyWindow = windowScene?.windows.first(where: { $0.isKeyWindow })
            var top = keyWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        } else {
            var top = UIApplication.shared.keyWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
    }

    /// UPDATED: When user taps Reschedule — update model via callback, show the custom confirmation card,
    /// but present it properly (dismiss any presented alert first).
    @objc private func rescheduleTapped() {
        guard let date = selectedDate, let slot = selectedSlot else { return }

        // combine date/time slot into a Date for convenience
        let newDate = combine(date: date, timeSlot: slot)

        // let caller update store / UI
        onReschedule?(newDate, slot)

        // Build the confirmation message
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let message = "Your session was moved to \(slot) on \(df.string(from: newDate))"

        // Prepare confirmation VC
        let conf = RescheduleConfirmationViewController()
        conf.titleText = "Rescheduled"
        conf.messageText = message

        // When Done tapped on the card, navigate back to PostBookingMentorshipViewController (or mentorship tab)
        conf.onDone = { [weak self] in
            guard let self = self else { return }

            // Try to find an existing PostBookingMentorshipViewController in the nav stack
            if let nav = self.navigationController {
                if let target = nav.viewControllers.first(where: { $0 is PostBookingMentorshipViewController }) {
                    nav.popToViewController(target, animated: true)
                    return
                }

                // Not found in stack — try to select Mentorship tab if available
                if let tab = self.tabBarController, let vcs = tab.viewControllers {
                    for (idx, c) in vcs.enumerated() {
                        if let navc = c as? UINavigationController,
                           navc.viewControllers.contains(where: { $0 is PostBookingMentorshipViewController }) {
                            tab.selectedIndex = idx
                            (vcs[idx] as? UINavigationController)?.popToRootViewController(animated: true)
                            return
                        }
                    }
                    // fallback: choose likely mentorship index (change if different)
                    if vcs.indices.contains(3) {
                        tab.selectedIndex = 3
                    }
                }
            } else {
                // Not inside a navigation controller: try to select mentorship tab directly
                if let tab = self.tabBarController, tab.viewControllers?.indices.contains(3) == true {
                    tab.selectedIndex = 3
                }
            }
        }

        // Present from the actual top-most controller. If that controller is already presenting something (e.g. an alert),
        // dismiss that first and then present the confirmation card.
        DispatchQueue.main.async {
            guard let presenter = self.topMostController() else {
                // fallback to self if we couldn't determine top
                self.present(conf, animated: true)
                return
            }

            if let presented = presenter.presentedViewController {
                // Dismiss the currently presented VC (likely a UIAlertController) and then present our card.
                presented.dismiss(animated: true) {
                    // Give the runloop a breath to avoid "already presenting" races.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        presenter.present(conf, animated: true)
                    }
                }
            } else {
                presenter.present(conf, animated: true)
            }
        }
    }

    // MARK: Helpers
    private func availableSlots(for date: Date) -> [String] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1, 7: return ["10:00 AM", "12:00 PM", "2:00 PM"]
        case 2, 4: return ["11:00 AM", "1:00 PM", "3:00 PM"]
        default: return ["9:00 AM", "11:30 AM", "4:00 PM"]
        }
    }

    private func combine(date: Date, timeSlot: String) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)

        let f = DateFormatter()
        f.dateFormat = "h:mma"
        let tm = timeSlot.replacingOccurrences(of: " ", with: "")
        if let timeOnly = f.date(from: tm) {
            let timeComps = Calendar.current.dateComponents([.hour, .minute], from: timeOnly)
            var final = DateComponents()
            final.year = comps.year
            final.month = comps.month
            final.day = comps.day
            final.hour = timeComps.hour
            final.minute = timeComps.minute
            return Calendar.current.date(from: final) ?? date
        }
        return date
    }
}
