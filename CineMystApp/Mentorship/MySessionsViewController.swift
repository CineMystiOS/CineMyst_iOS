//
//  MySessionViewController.swift
//  CineMystApp
//
//  Updated: hide tab bar while displayed; canceled card matches Figma (red "Canceled", no services/note row).
//

import UIKit

// MARK: - Models
enum SessionStatus {
    case upcoming
    case completed
    case canceled
}

struct SessionModel {
    let mentorName: String
    let role: String
    let date: Date
    let imageName: String?
    let rating: Double
    let services: [String]
    let note: String?
    let status: SessionStatus
}

// MARK: - SessionCardView
final class SessionCardView: UIView {

    var onReviewTapped: (() -> Void)?

    private let shadowContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        return v
    }()

    private let contentContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.98, alpha: 1)
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = true
        return v
    }()

    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()
    private let ratingLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        addSubview(shadowContainer)
        shadowContainer.addSubview(contentContainer)

        [avatar, nameLabel, roleLabel, dateLabel, statusLabel, ratingLabel, actionButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview($0)
        }

        avatar.layer.cornerRadius = 10
        avatar.clipsToBounds = true
        avatar.backgroundColor = .systemGray5
        avatar.contentMode = .scaleAspectFill

        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        roleLabel.font = .systemFont(ofSize: 13)
        roleLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        actionButton.setTitle("Give review", for: .normal)
        actionButton.backgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 16
        actionButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(handleReviewTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            shadowContainer.topAnchor.constraint(equalTo: topAnchor),
            shadowContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentContainer.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            avatar.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 16),
            avatar.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            avatar.widthAnchor.constraint(equalToConstant: 76),
            avatar.heightAnchor.constraint(equalToConstant: 76),

            nameLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),

            ratingLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: avatar.leadingAnchor, constant: -12),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            dateLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),

            actionButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 32),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])
    }

    @objc private func handleReviewTapped() {
        onReviewTapped?()
    }

    func configure(with model: SessionModel) {
        nameLabel.text = model.mentorName
        roleLabel.text = model.role

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        dateLabel.text = df.string(from: model.date)

        ratingLabel.text = String(format: "%.1f", model.rating)

        switch model.status {
        case .completed:
            statusLabel.text = "Completed"
            statusLabel.textColor = .systemGreen
            actionButton.isHidden = false
        case .canceled:
            statusLabel.text = "Canceled"
            statusLabel.textColor = .systemRed
            actionButton.isHidden = true
        case .upcoming:
            statusLabel.isHidden = true
            actionButton.isHidden = true
        }

        avatar.image = UIImage(named: model.imageName ?? "")
    }
}

// MARK: - MySessionViewController
final class MySessionViewController: UIViewController {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sessionSegment = UISegmentedControl(items: ["Upcoming", "Past", "Canceled"])
    private let sessionsStack = UIStackView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var upcomingSessions: [SessionModel] = []
    private var pastSessions: [SessionModel] = []
    private var canceledSessions: [SessionModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupData()
        sessionSegment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    private func setupUI() {
        titleLabel.text = "My Sessions"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        sessionSegment.selectedSegmentIndex = 0
        sessionSegment.backgroundColor = .systemGray5
        sessionSegment.selectedSegmentTintColor = .white

        sessionsStack.axis = .vertical
        sessionsStack.spacing = 18

        [scrollView, contentView, titleLabel, subtitleLabel, sessionSegment, sessionsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(sessionSegment)
        contentView.addSubview(sessionsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            sessionSegment.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            sessionSegment.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            sessionSegment.heightAnchor.constraint(equalToConstant: 40),

            sessionsStack.topAnchor.constraint(equalTo: sessionSegment.bottomAnchor, constant: 18),
            sessionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sessionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sessionsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupData() {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: now)!

        // ✅ ONLY ONE UPCOMING SESSION
        upcomingSessions = [
            SessionModel(
                mentorName: "Manya Patel",
                role: "Actor",
                date: now,
                imageName: "Image",
                rating: 4.9,
                services: [],
                note: nil,
                status: .upcoming
            )
        ]

        pastSessions = []       // empty → shows "No past sessions"
        canceledSessions = []   // empty → shows "No canceled sessions"

        buildSessionsUI(for: .upcoming)
    }

    private func buildSessionsUI(for status: SessionStatus) {

        sessionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let source: [SessionModel]

        switch status {
        case .upcoming:
            subtitleLabel.text = "Track your upcoming sessions"
            source = upcomingSessions

        case .completed:
            subtitleLabel.text = "Track your past sessions"
            source = pastSessions

        case .canceled:
            subtitleLabel.text = "Track your canceled sessions"
            source = canceledSessions
        }

        // ✅ Past & Canceled empty state ONLY
        if source.isEmpty && status != .upcoming {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.text = (status == .completed) ? "No past sessions" : "No canceled sessions"
            sessionsStack.addArrangedSubview(label)
            return
        }

        // ✅ Render cards (Upcoming WILL SHOW now)
        for s in source {
            let card = SessionCardView()
            card.configure(with: s)

            sessionsStack.addArrangedSubview(card)
            card.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
                card.leadingAnchor.constraint(equalTo: sessionsStack.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: sessionsStack.trailingAnchor)
            ])
        }
    }

    @objc private func segmentChanged(_ s: UISegmentedControl) {
        switch s.selectedSegmentIndex {
        case 0: buildSessionsUI(for: .upcoming)
        case 1: buildSessionsUI(for: .completed)
        case 2: buildSessionsUI(for: .canceled)
        default: break
        }
        scrollView.setContentOffset(.zero, animated: true)
    }
}
