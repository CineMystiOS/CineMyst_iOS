//
//  SessionDetailViewController.swift
//  Shows full details for a booked session or call (keeps Reschedule + Cancel)
//

import UIKit

final class MentorSessionDetailViewController: UIViewController {

    // Either one may be set by caller. We treat Call by converting to Session for reschedule flow.
    var session: SessionM?
    var call: Call?

    // Theme color
    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: UI elements
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 14
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .systemGray5
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let ratingStack: UIStackView = {
        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = .systemBlue
        star.translatesAutoresizingMaskIntoConstraints = false
        star.widthAnchor.constraint(equalToConstant: 14).isActive = true
        star.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.text = "4.9"
        label.translatesAutoresizingMaskIntoConstraints = false

        let s = UIStackView(arrangedSubviews: [star, label])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private let sessionTypeRow = DetailRowView(iconName: "calendar.badge.clock", title: "Session", subtitle: "")
    private let meetingRow = DetailRowView(iconName: "video", title: "Meeting", subtitle: "Details will be shared")
    private let areaRow = DetailRowView(iconName: "mappin.and.ellipse", title: "Mentorship Area", subtitle: "")

    // Buttons — always Reschedule + Cancel
    private lazy var rescheduleButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.title = "Reschedule"
        cfg.baseBackgroundColor = plum
        cfg.baseForegroundColor = .white
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return b
    }()

    private lazy var cancelButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.title = "Cancel"
        cfg.baseBackgroundColor = plum
        cfg.baseForegroundColor = .white
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return b
    }()

    // Optional status label (can show call status if available)
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Ensure navigation bar is visible and configure large title style.
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // Configure large title appearance to match the other screen
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor.label
        ]

        // Initial title — updated again in populate()
        navigationItem.title = "My Session"

        // Keep custom chevron (leftBarButtonItem) — title will align with it
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )

        setupLayout()
        populate()

        rescheduleButton.addTarget(self, action: #selector(didTapReschedule), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        // Re-assert prefersLargeTitles on appear (helps if other screens change it)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: populate
    private func populate() {
        // Prefer session if provided; otherwise use call (converted view)
        if let s = session {
            navigationItem.title = "My Session"
            imageView.image = UIImage(named: s.mentorImageName) ?? UIImage(named: "Image")
            nameLabel.text = s.mentorName
            roleLabel.text = s.mentorRole ?? ""
            if let ratingLabel = ratingStack.arrangedSubviews[1] as? UILabel {
                ratingLabel.text = "4.8"
            }
            let df = DateFormatter()
            df.dateStyle = .full
            df.timeStyle = .short
            sessionTypeRow.subtitleLabel.text = df.string(from: s.date)
            meetingRow.subtitleLabel.text = "Link shared on your mail id"
            areaRow.subtitleLabel.text = "Acting, Audition prep" // placeholder
            statusLabel.text = "" // no call status
        } else if let c = call {
            // Show call info but keep the same UI and same buttons (Reschedule + Cancel)
            navigationItem.title = "Call"
            imageView.image = UIImage(named: c.avatarName) ?? UIImage(named: "Image")
            nameLabel.text = c.mentorName
            roleLabel.text = c.mentorRole
            let df = DateFormatter()
            df.dateStyle = .full
            df.timeStyle = .short
            sessionTypeRow.subtitleLabel.text = df.string(from: c.date)
            meetingRow.subtitleLabel.text = "Virtual call — link will be available"
            areaRow.subtitleLabel.text = c.services.joined(separator: ", ")
            statusLabel.text = c.status.text
            statusLabel.textColor = c.status.textColor
            if let ratingLabel = ratingStack.arrangedSubviews[1] as? UILabel {
                ratingLabel.text = "4.8"
            }
        } else {
            // fallback placeholders
            navigationItem.title = "Details"
            imageView.image = UIImage(named: "Image")
            nameLabel.text = "—"
            roleLabel.text = ""
            sessionTypeRow.subtitleLabel.text = ""
            meetingRow.subtitleLabel.text = ""
            areaRow.subtitleLabel.text = ""
            statusLabel.text = ""
            rescheduleButton.isHidden = true
            cancelButton.isHidden = true
        }
    }

    // Helper: convert current call into a Session object for reschedule flow
    private func sessionFromCall(_ c: Call) -> SessionM {
        return SessionM(
            id: c.id,
            mentorId: "",                       // if you have mentorId on Call, use it
            mentorName: c.mentorName,
            mentorRole: c.mentorRole,
            date: c.date,
            createdAt: Date(),
            mentorImageName: c.avatarName
        )
    }

    // MARK: layout
    private func setupLayout() {
        // Scroll + content stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(content)

        // Top anchor: use safeArea top — large nav title is accounted for by safe area.
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])

        // hero image container
        let imageContainer = UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 170)
        ])
        imageContainer.layer.cornerRadius = 14
        imageContainer.clipsToBounds = true

        let metaStack = UIStackView(arrangedSubviews: [nameLabel, UIView(), ratingStack])
        metaStack.axis = .horizontal
        metaStack.alignment = .center
        metaStack.translatesAutoresizingMaskIntoConstraints = false

        let sessionHeader = sectionHeader("Session Details")
        let tag1 = TagView(title: "Acting")
        let tag2 = TagView(title: "Dubbing")
        let tagStack = UIStackView(arrangedSubviews: [tag1, tag2])
        tagStack.axis = .horizontal
        tagStack.spacing = 12
        tagStack.distribution = .fillEqually
        tagStack.translatesAutoresizingMaskIntoConstraints = false

        let buttonsRow = UIStackView(arrangedSubviews: [rescheduleButton, cancelButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false

        content.addArrangedSubview(imageContainer)
        content.addArrangedSubview(metaStack)
        content.setCustomSpacing(8, after: metaStack)
        content.addArrangedSubview(sessionHeader)
        content.addArrangedSubview(sessionTypeRow)
        content.addArrangedSubview(meetingRow)
        content.addArrangedSubview(areaRow)
        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(tagStack)

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        content.addArrangedSubview(spacer)

        content.addArrangedSubview(buttonsRow)
    }

    // MARK: actions
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapReschedule() {
        // If session exists, reschedule that. If only call exists, convert to session and reschedule.
        if let s = session {
            let rescheduleVC = RescheduleViewController(session: s)
            rescheduleVC.onReschedule = { [weak self] newDate, slot in
                guard let self = self else { return }
                let updated = SessionM(
                    id: s.id,
                    mentorId: s.mentorId,
                    mentorName: s.mentorName,
                    mentorRole: s.mentorRole,
                    date: newDate,
                    createdAt: s.createdAt,
                    mentorImageName: s.mentorImageName
                )
                SessionStore.shared.remove(id: s.id)
                SessionStore.shared.add(updated)
                let a = UIAlertController(title: "Rescheduled", message: "Your session was moved to \(slot) on \(DateFormatter.localizedString(from: newDate, dateStyle: .medium, timeStyle: .short))", preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(a, animated: true)
            }
            navigationController?.pushViewController(rescheduleVC, animated: true)
        } else if let c = call {
            // convert call -> session and reschedule that
            let s = sessionFromCall(c)
            let rescheduleVC = RescheduleViewController(session: s)
            rescheduleVC.onReschedule = { [weak self] newDate, slot in
                guard let self = self else { return }
                let updated = SessionM(
                    id: s.id,
                    mentorId: s.mentorId,
                    mentorName: s.mentorName,
                    mentorRole: s.mentorRole,
                    date: newDate,
                    createdAt: s.createdAt,
                    mentorImageName: s.mentorImageName
                )
                // add to SessionStore as new session
                SessionStore.shared.add(updated)
                let a = UIAlertController(title: "Rescheduled", message: "Your call was converted to a session at \(slot) on \(DateFormatter.localizedString(from: newDate, dateStyle: .medium, timeStyle: .short))", preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(a, animated: true)
            }
            navigationController?.pushViewController(rescheduleVC, animated: true)
        }
    }

    @objc private func didTapCancel() {
        // For sessions: remove from SessionStore (as before).
        // For calls: confirm and pop (or implement call-store removal later).
        if let s = session {
            let ac = UIAlertController(title: "Cancel Session", message: "Are you sure you want to cancel this session?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes, cancel", style: .destructive, handler: { _ in
                SessionStore.shared.remove(id: s.id)
                self.navigationController?.popViewController(animated: true)
            }))
            ac.addAction(UIAlertAction(title: "No", style: .cancel))
            present(ac, animated: true)
        } else if let c = call {
            let ac = UIAlertController(title: "Cancel Booking", message: "Are you sure you want to cancel this booking?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes, cancel", style: .destructive, handler: { _ in
                // if you have a CallStore, update it here. For now just pop.
                self.navigationController?.popViewController(animated: true)
            }))
            ac.addAction(UIAlertAction(title: "No", style: .cancel))
            present(ac, animated: true)
        }
    }
}

// MARK: helper views

private final class DetailRowView: UIView {
    private let iconView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    init(iconName: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = .secondaryLabel
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.text = subtitle
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class TagView: UIView {
    private let label = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .clear

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
