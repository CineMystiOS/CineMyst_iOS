//
// PaymentConfirmationViewController.swift
// Creates a Session on Done. Uses mentor.imageName when available (falls back to demo "Image").
// Updated: dismisses before replacing Mentorship tab and uses robust tab-finding logic.
//

import UIKit
import Supabase

final class PaymentConfirmationViewController: UIViewController {

    // optional callback
    var onDone: (() -> Void)?

    // data passed by caller (may be nil)
    var mentor: Mentor?
    var scheduledDate: Date?
    var selectedArea: String?
    var selectedTime: String?
    var bookingAmountCents: Int?

    // no static demo mentors; if a mentor isn't passed, fetch one from backend

    // UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let v = UIVisualEffectView(effect: blur)
        v.layer.cornerRadius = 28
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardTintView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.62)
        return v
    }()

    private let cardStrokeView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 28
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        v.isUserInteractionEnabled = false
        return v
    }()

    private let topGlowView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.99, alpha: 0.95)
        v.layer.cornerRadius = 18
        return v
    }()

    private let successOrbView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        v.layer.cornerRadius = 26
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 18
        return v
    }()

    private let successIconBackground: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.94, green: 0.89, blue: 0.98, alpha: 1)
        v.layer.cornerRadius = 18
        return v
    }()

    private let checkImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = UIColor(red: 0.4, green: 0.15, blue: 0.31, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let statusPillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.23, green: 0.68, blue: 0.42, alpha: 0.12)
        view.layer.cornerRadius = 12
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Payment Successful"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(red: 0.16, green: 0.52, blue: 0.31, alpha: 1)
        return label
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Booking confirmed"
        l.font = .systemFont(ofSize: 27, weight: .bold)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your session is saved and a confirmation mail is on its way."
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let infoRowView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.78)
        view.layer.cornerRadius = 18
        return view
    }()

    private let amountTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Amount paid"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let amountValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let sessionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Session"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let sessionValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1)
        label.numberOfLines = 2
        label.textAlignment = .right
        return label
    }()

    private let doneButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.cornerStyle = .capsule
        c.title = "View booking"
        c.baseBackgroundColor = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1)
        c.baseForegroundColor = .white
        c.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = .clear
        setupViews()
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped(_:)))
        dimView.addGestureRecognizer(tap)

        print("[PaymentConfirmation] presented mentor=\(String(describing: mentor?.name)) scheduledDate=\(String(describing: scheduledDate))")

        // If mentor not provided, fetch one from backend as a fallback
        if mentor == nil {
            Task {
                let fetched = await MentorsProvider.fetchAll()
                if let first = fetched.first {
                    self.mentor = first
                    print("[PaymentConfirmation] fallback mentor loaded: \(first.name)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    // Simple entrance animation for the modal card
    private func animateIn() {
        cardView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94).concatenating(CGAffineTransform(translationX: 0, y: 24))
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) { self.dimView.alpha = 1.0 }
        UIView.animate(withDuration: 0.32, delay: 0.06, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.8, options: []) {
            self.cardView.transform = .identity
        }
    }

    // Exit animation for the modal card
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.18, animations: {
            self.cardView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).concatenating(CGAffineTransform(translationX: 0, y: 8))
            self.dimView.alpha = 0
            self.cardView.alpha = 0
        }) { _ in completion?() }
    }

    private func setupViews() {
        view.addSubview(dimView)
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 344),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        cardView.contentView.addSubview(cardTintView)
        cardView.contentView.addSubview(topGlowView)
        cardView.contentView.addSubview(successOrbView)
        successOrbView.addSubview(successIconBackground)
        successIconBackground.addSubview(checkImage)
        cardView.contentView.addSubview(statusPillView)
        statusPillView.addSubview(statusLabel)
        cardView.contentView.addSubview(titleLabel)
        cardView.contentView.addSubview(subtitleLabel)
        cardView.contentView.addSubview(infoRowView)
        infoRowView.addSubview(amountTitleLabel)
        infoRowView.addSubview(amountValueLabel)
        infoRowView.addSubview(sessionTitleLabel)
        infoRowView.addSubview(sessionValueLabel)
        cardView.contentView.addSubview(doneButton)
        cardView.contentView.addSubview(cardStrokeView)

        let amountText: String
        if let bookingAmountCents {
            amountText = Self.formatPrice(cents: bookingAmountCents)
        } else {
            amountText = "Paid"
        }
        amountValueLabel.text = amountText
        sessionValueLabel.text = selectedArea?.isEmpty == false ? selectedArea : (mentor?.name ?? "Mentorship session")

        NSLayoutConstraint.activate([
            cardTintView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            cardTintView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            cardTintView.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor),
            cardTintView.bottomAnchor.constraint(equalTo: cardView.contentView.bottomAnchor),

            topGlowView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            topGlowView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            topGlowView.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor),
            topGlowView.heightAnchor.constraint(equalToConstant: 118),

            successOrbView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor, constant: 22),
            successOrbView.centerXAnchor.constraint(equalTo: cardView.contentView.centerXAnchor),
            successOrbView.widthAnchor.constraint(equalToConstant: 52),
            successOrbView.heightAnchor.constraint(equalToConstant: 52),

            successIconBackground.centerXAnchor.constraint(equalTo: successOrbView.centerXAnchor),
            successIconBackground.centerYAnchor.constraint(equalTo: successOrbView.centerYAnchor),
            successIconBackground.widthAnchor.constraint(equalToConstant: 36),
            successIconBackground.heightAnchor.constraint(equalToConstant: 36),

            checkImage.centerXAnchor.constraint(equalTo: successIconBackground.centerXAnchor),
            checkImage.centerYAnchor.constraint(equalTo: successIconBackground.centerYAnchor),
            checkImage.widthAnchor.constraint(equalToConstant: 16),
            checkImage.heightAnchor.constraint(equalToConstant: 16),

            statusPillView.topAnchor.constraint(equalTo: successOrbView.bottomAnchor, constant: 12),
            statusPillView.centerXAnchor.constraint(equalTo: cardView.contentView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: statusPillView.topAnchor, constant: 5),
            statusLabel.leadingAnchor.constraint(equalTo: statusPillView.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: statusPillView.trailingAnchor, constant: -10),
            statusLabel.bottomAnchor.constraint(equalTo: statusPillView.bottomAnchor, constant: -5),

            titleLabel.topAnchor.constraint(equalTo: statusPillView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 26),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -26),

            infoRowView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            infoRowView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 18),
            infoRowView.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -18),

            amountTitleLabel.topAnchor.constraint(equalTo: infoRowView.topAnchor, constant: 14),
            amountTitleLabel.leadingAnchor.constraint(equalTo: infoRowView.leadingAnchor, constant: 14),

            amountValueLabel.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 4),
            amountValueLabel.leadingAnchor.constraint(equalTo: amountTitleLabel.leadingAnchor),
            amountValueLabel.bottomAnchor.constraint(equalTo: infoRowView.bottomAnchor, constant: -14),

            sessionTitleLabel.topAnchor.constraint(equalTo: infoRowView.topAnchor, constant: 14),
            sessionTitleLabel.trailingAnchor.constraint(equalTo: infoRowView.trailingAnchor, constant: -14),

            sessionValueLabel.topAnchor.constraint(equalTo: sessionTitleLabel.bottomAnchor, constant: 4),
            sessionValueLabel.trailingAnchor.constraint(equalTo: sessionTitleLabel.trailingAnchor),
            sessionValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: amountValueLabel.trailingAnchor, constant: 16),
            sessionValueLabel.bottomAnchor.constraint(equalTo: infoRowView.bottomAnchor, constant: -14),

            doneButton.topAnchor.constraint(equalTo: infoRowView.bottomAnchor, constant: 18),
            doneButton.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 22),
            doneButton.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -22),
            doneButton.bottomAnchor.constraint(equalTo: cardView.contentView.bottomAnchor, constant: -22),

            cardStrokeView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            cardStrokeView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            cardStrokeView.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor),
            cardStrokeView.bottomAnchor.constraint(equalTo: cardView.contentView.bottomAnchor)
        ])
    }

    @objc private func didTapDone() {
        // If mentor was passed in, proceed synchronously. If not, fetch one from backend
        if let m = mentor {
            print("[PaymentConfirmation] using provided mentor: \(m.name)")
            Task { await completeBooking(with: m) }
            return
        }

        // mentor not provided — fetch first available mentor from backend and complete
        Task {
            let fetched = await MentorsProvider.fetchAll()
            let used = fetched.first ?? Mentor(id: nil, name: "Unknown", role: "", rating: 0.0, imageName: "Image")
            print("[PaymentConfirmation] fetched fallback mentor: \(used.name)")
            await completeBooking(with: used)
        }
    }

    @MainActor
    private func completeBooking(with usedMentor: Mentor) async {
        // choose date (provided or now)
        let usedDate = scheduledDate ?? Date()
        if scheduledDate == nil { print("[PaymentConfirmation] scheduledDate nil — using now: \(usedDate)") }

        let persistedSession = await persistBookingIfPossible(with: usedMentor, date: usedDate)

        // create session including mentor image name (fallback to "Image")
        let session = SessionM(
            id: persistedSession?.id ?? UUID().uuidString,
            mentorId: usedMentor.id ?? usedMentor.name,
            mentorName: usedMentor.name,
            mentorRole: usedMentor.role,
            date: usedDate,
            createdAt: Date(),
            mentorImageName: usedMentor.imageName ?? "Image",
            mentorImageURL: usedMentor.profilePictureUrl,
            mentorshipArea: selectedArea,
            scheduledTimeText: selectedTime
        )

        SessionStore.shared.add(session)
        print("[PaymentConfirmation] created session id=\(session.id) mentor=\(session.mentorName)")

        // Animate out, then dismiss this modal, then replace the Mentorship tab.
        animateOut { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: false) {
                // replace Mentorship tab with the updated flow
                // replace Mentorship tab by using our helper which searches and swaps
                self.replaceMentorshipTabWithPostBookingScreen()
                self.onDone?()
            }
        }
    }
        // Animate out, then dismiss this modal, then replace the Mentorship tab.
        

    private struct SessionInsertPayload: Encodable {
        let mentor_id: String
        let mentee_id: String
        let scheduled_at: String
        let duration_minutes: Int
        let status: String
        let price_cents: Int?
        let currency: String?
        let notes: String?
    }

    private struct SessionInsertResult: Decodable {
        let id: String
    }

    private struct MentorSessionCountRecord: Decodable {
        let session: Double?
    }

    private static func formatPrice(cents: Int) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }

    private func persistBookingIfPossible(with mentor: Mentor, date: Date) async -> SessionInsertResult? {
        guard let mentorId = mentor.id else {
            print("[PaymentConfirmation] mentor.id missing, skipping DB insert")
            return nil
        }

        do {
            let authSession = try await supabase.auth.session
            let menteeId = authSession.user.id.uuidString

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let payload = SessionInsertPayload(
                mentor_id: mentorId,
                mentee_id: menteeId,
                scheduled_at: formatter.string(from: date),
                duration_minutes: 60,
                status: "scheduled",
                price_cents: bookingAmountCents ?? mentor.priceCents,
                currency: mentor.currency ?? "INR",
                notes: selectedArea
            )

            let response = try await supabase
                .from("mentorship_sessions")
                .insert(payload)
                .select("id")
                .single()
                .execute()

            let result = try JSONDecoder().decode(SessionInsertResult.self, from: response.data)
            await incrementMentorSessionCount(for: mentorId)
            print("[PaymentConfirmation] persisted session id=\(result.id)")
            return result
        } catch {
            print("[PaymentConfirmation] persist booking failed: \(error)")
            return nil
        }
    }

    private func incrementMentorSessionCount(for mentorId: String) async {
        do {
            let res = try await supabase
                .from("mentor_profiles")
                .select("session")
                .eq("id", value: mentorId)
                .single()
                .execute()

            let record = try JSONDecoder().decode(MentorSessionCountRecord.self, from: res.data)
            let current = Int(record.session ?? 0)
            try await supabase
                .from("mentor_profiles")
                .update(["session": current + 1])
                .eq("id", value: mentorId)
                .execute()

            print("[PaymentConfirmation] incremented mentor_profiles.session for mentor_id=\(mentorId) to \(current + 1)")
        } catch {
            print("[PaymentConfirmation] increment mentor session count failed: \(error)")
        }
    }

    @objc private func dimTapped(_ g: UITapGestureRecognizer) { didTapDone() }

    // Helper that replaces the Mentorship tab root and selects it, preserving its tabBarItem
    private func replaceMentorshipTabWithPostBookingScreen() {
        // Replace tab with MentorshipHomeViewController so users land on the home screen after booking
        let homeVC = MentorshipHomeViewController()
        let newNav = UINavigationController(rootViewController: homeVC)

        guard let tabBar = findTabBarController() else {
                print("[PaymentConfirmation] no UITabBarController found — presenting Mentorship home modally")
                DispatchQueue.main.async {
                    let nav = UINavigationController(rootViewController: homeVC)
                    nav.modalPresentationStyle = .fullScreen
                    // present on topmost/root
                    UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
                }
            return
        }

        guard var tabs = tabBar.viewControllers else {
                print("[PaymentConfirmation] tabBar.viewControllers nil — presenting Mentorship home modally")
                DispatchQueue.main.async {
                    let nav = UINavigationController(rootViewController: homeVC)
                    nav.modalPresentationStyle = .fullScreen
                    tabBar.present(nav, animated: true, completion: nil)
                }
            return
        }

        var replaced = false

        // 1) Try direct type match (nav root or child)
        for (index, child) in tabs.enumerated() {
            if let nav = child as? UINavigationController, let root = nav.viewControllers.first {
                if root is MentorshipHomeViewController || String(describing: type(of: root)).lowercased().contains("mentorship") {
                    print("[PaymentConfirmation] replacing tab at index \(index) (nav root match)")
                    newNav.tabBarItem = nav.tabBarItem
                    tabs[index] = newNav
                    tabBar.setViewControllers(tabs, animated: false)
                    tabBar.selectedIndex = index
                    replaced = true
                    break
                }
            } else {
                if child is MentorshipHomeViewController || String(describing: type(of: child)).lowercased().contains("mentorship") {
                    print("[PaymentConfirmation] replacing tab at index \(index) (child match)")
                    newNav.tabBarItem = child.tabBarItem
                    tabs[index] = newNav
                    tabBar.setViewControllers(tabs, animated: false)
                    tabBar.selectedIndex = index
                    replaced = true
                    break
                }
            }
        }

        // 2) Try title-based match
        if !replaced {
            for (index, child) in tabs.enumerated() {
                let title = (child.tabBarItem.title ?? "").lowercased()
                print("[PaymentConfirmation] checking tab \(index) title: \(title)")
                if title.contains("mentor") || title.contains("mentorship") {
                    print("[PaymentConfirmation] replacing tab at index \(index) (title match)")
                    newNav.tabBarItem = child.tabBarItem
                    tabs[index] = newNav
                    tabBar.setViewControllers(tabs, animated: false)
                    tabBar.selectedIndex = index
                    replaced = true
                    break
                }
            }
        }

        // 3) If nothing replaced, append a new Mentorship tab
        if !replaced {
            print("[PaymentConfirmation] no mentorship tab found — appending new tab")
            newNav.tabBarItem = UITabBarItem(title: "Mentorship", image: UIImage(systemName: "person.2.fill"), tag: 99)
            tabs.append(newNav)
            tabBar.setViewControllers(tabs, animated: false)
            tabBar.selectedIndex = tabs.count - 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            homeVC.reloadSessions()
        }
    }

    // MARK: - Helpers to find UITabBarController robustly

    /// Searches connected scenes/windows/root view controllers recursively to find a UITabBarController.
    private func findTabBarController() -> UITabBarController? {
        // Search scenes (iOS 13+)
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                if let t = window.rootViewController as? UITabBarController {
                    return t
                }
                if let found = findTabBarIn(vc: window.rootViewController) {
                    return found
                }
            }
        }
        // Fallback to UIApplication windows
        for window in UIApplication.shared.windows {
            if let t = window.rootViewController as? UITabBarController {
                return t
            }
            if let found = findTabBarIn(vc: window.rootViewController) {
                return found
            }
        }
        return nil
    }

    /// Recursively searches a view controller tree (children + presented) for a UITabBarController.
    private func findTabBarIn(vc: UIViewController?) -> UITabBarController? {
        guard let vc = vc else { return nil }
        if let t = vc as? UITabBarController { return t }
        // Search children
        for child in vc.children {
            if let found = findTabBarIn(vc: child) { return found }
        }
        // Search presented chain
        if let presented = vc.presentedViewController {
            if let found = findTabBarIn(vc: presented) { return found }
        }
        return nil
    }
}
