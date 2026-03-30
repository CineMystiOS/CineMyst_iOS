//
// PostBookingMentorshipViewController.swift
// Shows "My Session" above Mentors; reads sessions from SessionStore.
// Supports switching between Mentee (My Session) and Mentor (Calls)
//

import UIKit
import PhotosUI

// ------------------------
// Simple Call model
// ------------------------
struct Call {
    let id: String
    let mentorName: String
    let mentorRole: String
    let date: Date
    let services: [String]
    let avatarName: String // asset name
    let status: CallStatus

    enum CallStatus {
        case upcoming
        case ended
        var text: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .ended: return "Ended"
            }
        }
        var textColor: UIColor {
            switch self {
            case .upcoming: return UIColor.systemGreen
            case .ended: return UIColor.systemRed
            }
        }
    }
}

// ------------------------
// CallCell (rounded card UI)
// ------------------------
final class CallCell: UITableViewCell {
    static let reuseIdentifier = "CallCell"

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemGray6
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 28
        iv.layer.masksToBounds = true
        iv.widthAnchor.constraint(equalToConstant: 56).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    private let servicesLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        return l
    }()

    private lazy var leadingStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [nameLabel, roleLabel, dateLabel, servicesLabel])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 4
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.addSubview(cardView)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(leadingStack)
        cardView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            leadingStack.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            leadingStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            leadingStack.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            leadingStack.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -12),

            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16)
        ])
    }

    func configure(with call: Call) {
        nameLabel.text = call.mentorName
        roleLabel.text = call.mentorRole

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        dateLabel.text = df.string(from: call.date)

        servicesLabel.text = "Services  " + call.services.joined(separator: " , ")

        statusLabel.text = call.status.text
        statusLabel.textColor = call.status.textColor

        avatarImageView.image = UIImage(named: call.avatarName) ?? UIImage(systemName: "person.crop.circle")
    }
}

// ------------------------
// Call detail placeholder
// ------------------------
final class CallDetailViewController: UIViewController {
    var call: Call?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Call"
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        if let c = call {
            label.text = "\(c.mentorName)\n\(c.mentorRole)\n\(c.status.text)"
        } else {
            label.text = "Call details"
        }
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
}

// ------------------------
// Main view controller (UPDATED)
// ------------------------
final class PostBookingMentorshipViewController: UIViewController {

    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Mentorship"
        l.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Discover & learn from your mentor"
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Mentee", "Mentor"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .white
        sc.backgroundColor = UIColor.systemGray5
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .normal)
        sc.layer.cornerRadius = 18
        sc.layer.masksToBounds = true
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // My Session / Calls header
    private let sessionsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "My Session"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let sessionsSeeAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See all", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private lazy var sessionsTableView: UITableView = {
        let tv = UITableView()
        tv.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tv.register(CallCell.self, forCellReuseIdentifier: CallCell.reuseIdentifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.estimatedRowHeight = 100
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()

    // Empty state for Mentor segment (copied from code2)
    private let emptyIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    // Become Mentor button moved to top-right (like code2)
    private lazy var becomeMentorButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Become Mentor", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.backgroundColor = plum
        b.layer.cornerRadius = 16
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapBecomeMentor), for: .touchUpInside)
        b.alpha = 0.0
        b.isHidden = true
        return b
    }()

    // Mentors (reuse MentorCell)
    private let mentorsLabel: UILabel = {
        let l = UILabel()
        l.text = "Mentors"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let mentorsSeeAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See all", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(MentorCell.self, forCellWithReuseIdentifier: MentorCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        return cv
    }()

    // data
    private var sessions: [SessionM] = []
    private var calls: [Call] = []
    private var mentors: [Mentor] = []

    private var sessionsTableHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        titleLabel.textColor = plum

        setupHierarchy()
        setupConstraints()
        wireDelegates()

        // load initial data
        sessions = SessionStore.shared.all()
        loadSampleCallsIfNeeded()
        updateSessionsLayout()

        // ensure UI matches selected segment at startup
        segmentChanged(segmentControl)

        // Load mentors from backend
        Task {
            let fetched = await MentorsProvider.fetchAll()
            self.mentors = fetched
            self.collectionView.reloadData()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveSessionNotification(_:)), name: .sessionUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .sessionUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSessions()
        updateBecomeMentorVisibility(animated: false)
    }

    private func setupHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(segmentControl)

        view.addSubview(sessionsTitleLabel)
        view.addSubview(sessionsSeeAllButton)
        view.addSubview(sessionsTableView)

        view.addSubview(emptyIcon)
        view.addSubview(emptyLabel)
        view.addSubview(becomeMentorButton)

        view.addSubview(mentorsLabel)
        view.addSubview(mentorsSeeAllButton)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            segmentControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            segmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentControl.widthAnchor.constraint(equalToConstant: 220),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            sessionsTitleLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 18),
            sessionsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            sessionsSeeAllButton.centerYAnchor.constraint(equalTo: sessionsTitleLabel.centerYAnchor),
            sessionsSeeAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            sessionsTableView.topAnchor.constraint(equalTo: sessionsTitleLabel.bottomAnchor, constant: 12),
            sessionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sessionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // empty state (centered under segmentControl)
            emptyIcon.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 26),
            emptyIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 10),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad + 8),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(pad + 8)),

            mentorsLabel.topAnchor.constraint(equalTo: sessionsTableView.bottomAnchor, constant: 22),
            mentorsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            mentorsSeeAllButton.centerYAnchor.constraint(equalTo: mentorsLabel.centerYAnchor),
            mentorsSeeAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            collectionView.topAnchor.constraint(equalTo: mentorsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // move becomeMentorButton to top-right (safe area), avoid overlapping sessions
        NSLayoutConstraint.activate([
            becomeMentorButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            becomeMentorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            becomeMentorButton.heightAnchor.constraint(equalToConstant: 32),
            becomeMentorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        sessionsTableHeightConstraint = sessionsTableView.heightAnchor.constraint(equalToConstant: 0)
        sessionsTableHeightConstraint.isActive = true
    }

    private func wireDelegates() {
        sessionsTableView.dataSource = self
        sessionsTableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self

        // segment control action
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        sessionsSeeAllButton.addTarget(self, action: #selector(didTapSessionsSeeAll), for: .touchUpInside)
        mentorsSeeAllButton.addTarget(self, action: #selector(didTapMentorsSeeAll), for: .touchUpInside)
    }

    // MARK: actions
    @objc private func didReceiveSessionNotification(_ n: Notification) {
        print("[PostBookingMentorship] received sessionUpdated: \(n.userInfo ?? [:])")
        reloadSessions()
    }

    func reloadSessions() {
        // For demo, both use session store — but we switch the UI/data used in tableView based on segment.
        sessions = SessionStore.shared.all()
        updateSessionsLayout()
    }

    private func updateSessionsLayout() {
        DispatchQueue.main.async {
            self.sessionsTableView.reloadData()
            self.sessionsTableView.layoutIfNeeded()
            let h = self.sessionsTableView.contentSize.height
            self.sessionsTableHeightConstraint.constant = h
            UIView.animate(withDuration: 0.18) { self.view.layoutIfNeeded() }
        }
    }

    // Called when segment control changes between Mentee / Mentor
    @objc private func segmentChanged(_ s: UISegmentedControl) {
        if s.selectedSegmentIndex == 0 {
            // Mentee selected -> My Session UI
            sessionsTitleLabel.text = "My Session"
            sessionsSeeAllButton.setTitle("See all", for: .normal)
            // Make sure sessions UI is visible and empty state hidden
            toggleUIForSegment(index: 0)
            // reload sessions
            reloadSessions()
            updateBecomeMentorVisibility(animated: true)
        } else {
            // Mentor selected -> show Mentor-style UI (like code 2)
            sessionsTitleLabel.text = "Calls"
            sessionsSeeAllButton.setTitle("See all", for: .normal)
            toggleUIForSegment(index: 1)
            updateBecomeMentorVisibility(animated: true)
        }
    }

    private func toggleUIForSegment(index: Int) {
        // index 0 -> Mentee: show sessions table; hide empty state and becomeMentor
        // index 1 -> Mentor: hide sessions table; show empty state and becomeMentor
        let isMentor = (index == 1)

        // hide or show sessions header + table
        sessionsTitleLabel.isHidden = isMentor
        sessionsSeeAllButton.isHidden = isMentor
        sessionsTableView.isHidden = isMentor

        // show empty state when mentor selected
        emptyIcon.isHidden = !isMentor
        emptyLabel.isHidden = !isMentor
        // becomeMentor button visibility handled by updateBecomeMentorVisibility
    }

    private func updateBecomeMentorVisibility(animated: Bool) {
        let shouldShow = (segmentControl.selectedSegmentIndex == 1)
        let changes = {
            self.becomeMentorButton.isHidden = !shouldShow
            self.becomeMentorButton.alpha = shouldShow ? 1.0 : 0.0
        }

        // configure empty state content
        if segmentControl.selectedSegmentIndex == 0 {
            emptyIcon.image = UIImage(systemName: "square.and.pencil")
            emptyLabel.text = "No sessions yet. Book your first mentorship session to get started."
        } else {
            emptyIcon.image = UIImage(systemName: "phone.fill")
            emptyLabel.text = "No bookings yet. Become a mentor — once a mentee schedules a session, you'll see it here."
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func didTapSessionsSeeAll() {
        // Push different VC depending on which segment is active
        if segmentControl.selectedSegmentIndex == 0 {
            // Mentee -> show Upcoming/My Sessions (existing)
            let vc = MySessionViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // Mentor -> show Calls list (or your CallsViewController)
            let vc = CallsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func didTapMentorsSeeAll() {
        let vc = AllMentorsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapBecomeMentor() {
        let vc = BecomeMentorViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // load some example calls for demo (replace with real data fetch)
    private func loadSampleCallsIfNeeded() {
        guard calls.isEmpty else { return }
        let calendar = Calendar.current
        calls = [
            Call(id: "1", mentorName: "Amit Sawi", mentorRole: "Junior Artist", date: calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date(), services: ["Acting", "Voice Over"], avatarName: "Image", status: .upcoming),
            Call(id: "2", mentorName: "Amit Sawi", mentorRole: "Junior Artist", date: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date(), services: ["Acting", "Voice Over"], avatarName: "Image", status: .ended)
        ]
    }
}

// MARK: - Table + Collection delegates
extension PostBookingMentorshipViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            return sessions.count
        } else {
            return calls.count
        }
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentControl.selectedSegmentIndex == 0 {
            // Mentee -> SessionCell
            guard let cell = tv.dequeueReusableCell(withIdentifier: SessionCell.reuseIdentifier, for: indexPath) as? SessionCell else {
                return UITableViewCell()
            }
            let s = sessions[indexPath.row]
            cell.configure(with: s)
            return cell
        } else {
            // Mentor -> CallCell (rounded cards)
            guard let cell = tv.dequeueReusableCell(withIdentifier: CallCell.reuseIdentifier, for: indexPath) as? CallCell else {
                return UITableViewCell()
            }
            let c = calls[indexPath.row]
            cell.configure(with: c)
            return cell
        }
    }

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        if segmentControl.selectedSegmentIndex == 0 {
            // open session detail
            let s = sessions[indexPath.row]
            let detailVC = SessionDetailViewController()
            detailVC.session = s
            detailVC.hidesBottomBarWhenPushed = false
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // open call detail
            let c = calls[indexPath.row]
            let vc = CallDetailViewController()
            vc.call = c
            vc.hidesBottomBarWhenPushed = false
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension PostBookingMentorshipViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { mentors.count }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let c = cv.dequeueReusableCell(withReuseIdentifier: MentorCell.reuseIdentifier, for: indexPath) as? MentorCell else {
            return UICollectionViewCell()
        }
        c.configure(with: mentors[indexPath.item])
        return c
    }

    func collectionView(_ cv: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 160, height: 170)
        }
        let insets = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let width = floor((cv.bounds.width - insets - spacing) / 2.0)
        return CGSize(width: width, height: width * 0.85)
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Now behaves like code 2: tapping a mentor opens BookViewController with the mentor passed.
        let mentor = mentors[indexPath.item]

        let bookVC = BookViewController()
        bookVC.mentor = mentor
        bookVC.hidesBottomBarWhenPushed = true

        if let nav = navigationController {
            nav.pushViewController(bookVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: bookVC)
            present(nav, animated: true, completion: nil)
        }
    }
}

// ------------------------
// Mentor detail (kept in same file — unused for mentor tap now, but kept if needed elsewhere)
// ------------------------
final class MentorDetailViewController: UIViewController {

    var mentor: Mentor!

    private let scrollView = UIScrollView()
    private let content = UIView()

    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = UIColor(red: 0/255, green: 120/255, blue: 255/255, alpha: 1)
        return l
    }()

    private let aboutLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var bookButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Book Session", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapBook), for: .touchUpInside)
        return b
    }()

    private lazy var callButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start Call", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapCall), for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHierarchy()
        setupConstraints()
        populate()
    }

    private func setupHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(content)

        content.addSubview(headerImageView)
        content.addSubview(nameLabel)
        content.addSubview(roleLabel)
        content.addSubview(ratingLabel)
        content.addSubview(aboutLabel)
        content.addSubview(bookButton)
        content.addSubview(callButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // scrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // header image
            headerImageView.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            headerImageView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 180),

            // name + rating
            nameLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),

            ratingLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            roleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),

            aboutLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 12),
            aboutLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            aboutLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            // buttons
            bookButton.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 20),
            bookButton.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            bookButton.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            bookButton.heightAnchor.constraint(equalToConstant: 50),

            callButton.topAnchor.constraint(equalTo: bookButton.bottomAnchor, constant: 12),
            callButton.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            callButton.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            callButton.heightAnchor.constraint(equalToConstant: 50),

            callButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32)
        ])
    }

    private func populate() {
        guard let m = mentor else { return }
        nameLabel.text = m.name
        roleLabel.text = m.role
        ratingLabel.text = "★ \(String(format: "%.1f", m.rating))"

        aboutLabel.text = "Experienced \(m.role). Offers mentoring in acting, casting, audition prep and voice work. Book a session or start a call."

        if let imageName = m.imageName, let img = UIImage(named: imageName) {
            headerImageView.image = img
        } else {
            headerImageView.image = UIImage(systemName: "person.crop.rectangle.fill")
            headerImageView.tintColor = .systemGray3
            headerImageView.contentMode = .center
        }
    }

    // MARK: - Actions
    @objc private func didTapBook() {
        let vc = BookViewController()
        vc.mentor = mentor
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapCall() {
        // open call detail, or start call flow
        let callVC = CallDetailViewController()
        navigationController?.pushViewController(callVC, animated: true)
    }
}

// ------------------------
// Placeholder CallsViewController
// ------------------------
final class CallsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Calls"
        let label = UILabel()
        label.text = "Calls list goes here"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
