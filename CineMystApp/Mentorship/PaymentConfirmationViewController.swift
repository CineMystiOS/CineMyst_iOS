//
// PaymentConfirmationViewController.swift
// Creates a Session on Done. Uses mentor.imageName when available (falls back to demo "Image").
// Updated: dismisses before replacing Mentorship tab and uses robust tab-finding logic.
//

import UIKit

final class PaymentConfirmationViewController: UIViewController {

    // optional callback
    var onDone: (() -> Void)?

    // data passed by caller (may be nil)
    var mentor: Mentor?
    var scheduledDate: Date?

    // no static demo mentors; if a mentor isn't passed, fetch one from backend

    // UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.45)
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let checkBox: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.94, green: 0.9, blue: 0.98, alpha: 1)
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let checkImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = UIColor(red: 0.4, green: 0.15, blue: 0.31, alpha: 1)
        iv.contentMode = .center
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your payment has been done!"
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "We've sent you a confirmation mail."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let doneButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.cornerStyle = .capsule
        c.title = "Done"
        c.baseBackgroundColor = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1)
        c.baseForegroundColor = .white
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
        cardView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).concatenating(CGAffineTransform(translationX: 0, y: 20))
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
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        cardView.addSubview(checkBox)
        checkBox.addSubview(checkImage)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(doneButton)

        NSLayoutConstraint.activate([
            checkBox.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            checkBox.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 48),
            checkBox.heightAnchor.constraint(equalToConstant: 48),

            checkImage.centerXAnchor.constraint(equalTo: checkBox.centerXAnchor),
            checkImage.centerYAnchor.constraint(equalTo: checkBox.centerYAnchor),
            checkImage.widthAnchor.constraint(equalToConstant: 18),
            checkImage.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: checkBox.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            doneButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            doneButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 48),
            doneButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -48),
            doneButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
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

        // create session including mentor image name (fallback to "Image")
        let session = SessionM(
            id: UUID().uuidString,
            mentorId: usedMentor.name,
            mentorName: usedMentor.name,
            mentorRole: usedMentor.role,
            date: usedDate,
            createdAt: Date(),
            mentorImageName: usedMentor.imageName ?? "Image"
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
        

    @objc private func dimTapped(_ g: UITapGestureRecognizer) { didTapDone() }

    // Helper that replaces the Mentorship tab root and selects it, preserving its tabBarItem
    private func replaceMentorshipTabWithPostBookingScreen() {
        let postBookingVC = PostBookingMentorshipViewController()
        let newNav = UINavigationController(rootViewController: postBookingVC)

        guard let tabBar = findTabBarController() else {
            print("[PaymentConfirmation] no UITabBarController found — presenting PostBooking modally")
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: postBookingVC)
                nav.modalPresentationStyle = .fullScreen
                // present on topmost/root
                UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
            }
            return
        }

        guard var tabs = tabBar.viewControllers else {
            print("[PaymentConfirmation] tabBar.viewControllers nil — presenting modally")
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: postBookingVC)
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
            postBookingVC.reloadSessions()
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
