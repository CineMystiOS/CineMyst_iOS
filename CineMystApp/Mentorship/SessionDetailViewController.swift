//
// SessionDetailViewController.swift
// Shows full details for a booked session
//

import UIKit

final class SessionDetailViewController: UIViewController {

    // The session to display (must be set by the caller)
    var session: SessionM!

    // Theme color
    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: UI elements
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    // Large local title (we keep it in the view; nav bar left button handles back)
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "My Session"
        l.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

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

    // Section heading helper
    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private let sessionTypeRow = DetailRowView(iconName: "calendar.badge.clock", title: "1-hour session", subtitle: "")
    private let meetingRow = DetailRowView(iconName: "video", title: "Virtual Meeting", subtitle: "Link shared on your mail id")
    private let areaRow = DetailRowView(iconName: "mappin.and.ellipse", title: "Mentorship Area", subtitle: "")

    // Both buttons now use the same filled style so backgrounds match
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
        cfg.baseBackgroundColor = plum   // same background color as Reschedule
        cfg.baseForegroundColor = .white
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return b
    }()

    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Hide default back (the nav controller's back) and provide a single custom left item:
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
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show tab bar again
        tabBarController?.tabBar.isHidden = false
    }

    private func populate() {
        let img = UIImage(named: session.mentorImageName) ?? UIImage(named: "Image")
        imageView.image = img
        nameLabel.text = session.mentorName
        roleLabel.text = session.mentorRole ?? ""
        if let ratingLabel = ratingStack.arrangedSubviews[1] as? UILabel {
            ratingLabel.text = "4.8"
        }
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .short
        sessionTypeRow.subtitleLabel.text = df.string(from: session.date)
    }

    private func setupLayout() {
        // top system title is handled by navigation bar left item; keep big title inside view
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        // scroll + content stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
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

        // name / role / rating horizontal
        let metaStack = UIStackView(arrangedSubviews: [nameLabel, UIView(), ratingStack])
        metaStack.axis = .horizontal
        metaStack.alignment = .center
        metaStack.translatesAutoresizingMaskIntoConstraints = false

        // session header
        let sessionHeader = sectionHeader("Session Details")

        // mentorship area tags — make equal width
        let tag1 = TagView(title: "Acting")
        let tag2 = TagView(title: "Dubbing")

        let tagStack = UIStackView(arrangedSubviews: [tag1, tag2])
        tagStack.axis = .horizontal
        tagStack.spacing = 12
        tagStack.distribution = .fillEqually   // <- equal widths
        tagStack.translatesAutoresizingMaskIntoConstraints = false

        // buttons row
        let buttonsRow = UIStackView(arrangedSubviews: [rescheduleButton, cancelButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false

        // assemble
        content.addArrangedSubview(imageContainer)
        content.addArrangedSubview(metaStack)
        content.setCustomSpacing(8, after: metaStack)
        content.addArrangedSubview(sessionHeader)
        content.addArrangedSubview(sessionTypeRow)
        content.addArrangedSubview(meetingRow)
        content.addArrangedSubview(areaRow)
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
        let rescheduleVC = RescheduleViewController(session: session)
        rescheduleVC.onReschedule = { [weak self] newDate, slot in
            guard let self = self else { return }
            // Update session in SessionStore (demo: create a new Session object)
            let updated = SessionM(
                id: self.session.id,
                mentorId: self.session.mentorId,
                mentorName: self.session.mentorName,
                mentorRole: self.session.mentorRole,
                date: newDate,
                createdAt: self.session.createdAt,
                mentorImageName: self.session.mentorImageName
            )
            // Replace existing session: simple approach -> remove old and add updated
            SessionStore.shared.remove(id: self.session.id)
            SessionStore.shared.add(updated)

            // Optionally show confirmation
            let a = UIAlertController(title: "Rescheduled", message: "Your session was moved to \(slot) on \(DateFormatter.localizedString(from: newDate, dateStyle: .medium, timeStyle: .short))", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(a, animated: true)
        }

        // push or present
        navigationController?.pushViewController(rescheduleVC, animated: true)
    }


    @objc private func didTapCancel() {
        let ac = UIAlertController(title: "Cancel Session", message: "Are you sure you want to cancel this session?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes, cancel", style: .destructive, handler: { _ in
            SessionStore.shared.remove(id: self.session.id)
            self.navigationController?.popViewController(animated: true)
        }))
        ac.addAction(UIAlertAction(title: "No", style: .cancel))
        present(ac, animated: true)
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
