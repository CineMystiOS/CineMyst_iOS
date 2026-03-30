//
//  MentorPanelViewController.swift
//  ProgrammaticMentorship
//

import UIKit

final class MentorPanelViewController: UIViewController {

    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: - Header
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
        sc.backgroundColor = .systemGray5
        sc.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .normal
        )
        sc.layer.cornerRadius = 18
        sc.layer.masksToBounds = true
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - Sessions
    private let sessionsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "My Session"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var sessionsTableView: UITableView = {
        let tv = UITableView()
        tv.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tv.register(CallCell.self, forCellReuseIdentifier: CallCell.reuseIdentifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        return tv
    }()

    // MARK: - Mentors
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
        cv.isScrollEnabled = false
        return cv
    }()

    private var sessions: [SessionM] = []
    private var calls: [Call] = []
    private var mentors: [Mentor] = []

    private var sessionsTableHeightConstraint: NSLayoutConstraint!
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        titleLabel.textColor = plum

        setupHierarchy()
        setupConstraints()
        wireDelegates()

        sessions = SessionStore.shared.all()
        loadSampleCallsIfNeeded()
        updateSessionsLayout()

        Task {
            let fetched = await MentorsProvider.fetchAll()
            self.mentors = fetched
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
        }

        segmentChanged(segmentControl)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveSessionNotification(_:)),
            name: .sessionUpdated,
            object: nil
        )

        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSessionsLayout()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Setup
    private func setupHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(segmentControl)

        view.addSubview(sessionsTitleLabel)
        view.addSubview(sessionsTableView)

        view.addSubview(mentorsLabel)
        view.addSubview(mentorsSeeAllButton)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        let pad: CGFloat = 20
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: pad),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            segmentControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            segmentControl.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            segmentControl.widthAnchor.constraint(equalToConstant: 220),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            sessionsTitleLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 18),
            sessionsTitleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: pad),

            sessionsTableView.topAnchor.constraint(equalTo: sessionsTitleLabel.bottomAnchor, constant: 12),
            sessionsTableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: pad),
            sessionsTableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -pad),

            mentorsLabel.topAnchor.constraint(equalTo: sessionsTableView.bottomAnchor, constant: 22),
            mentorsLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: pad),

            mentorsSeeAllButton.centerYAnchor.constraint(equalTo: mentorsLabel.centerYAnchor),
            mentorsSeeAllButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -pad),

            collectionView.topAnchor.constraint(equalTo: mentorsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safe.trailingAnchor)
        ])

        sessionsTableHeightConstraint = sessionsTableView.heightAnchor.constraint(equalToConstant: 0)
        sessionsTableHeightConstraint.isActive = true

        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 200)
        collectionViewHeightConstraint.isActive = true

        let bottomGap = collectionView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -12
        )
        bottomGap.priority = .defaultLow
        bottomGap.isActive = true
    }

    private func wireDelegates() {
        sessionsTableView.dataSource = self
        sessionsTableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self

        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        mentorsSeeAllButton.addTarget(self, action: #selector(didTapMentorsSeeAll), for: .touchUpInside)
    }

    // MARK: - Segment
    @objc private func segmentChanged(_ s: UISegmentedControl) {
        sessionsTitleLabel.text = s.selectedSegmentIndex == 0 ? "My Session" : "Calls"
        updateSessionsLayout()
    }

    // MARK: - Navigation
    @objc private func didTapMentorsSeeAll() {
        let vc = AllMentorsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Data
    @objc private func didReceiveSessionNotification(_ n: Notification) {
        reloadSessions()
    }

    func reloadSessions() {
        sessions = SessionStore.shared.all()
        updateSessionsLayout()
    }

    private func updateSessionsLayout() {
        DispatchQueue.main.async {
            self.sessionsTableView.reloadData()
            self.sessionsTableView.layoutIfNeeded()
            self.sessionsTableHeightConstraint.constant = self.sessionsTableView.contentSize.height

            self.collectionView.layoutIfNeeded()
            let height = max(100, self.collectionView.collectionViewLayout.collectionViewContentSize.height)
            self.collectionViewHeightConstraint.constant = height
        }
    }

    private func loadSampleCallsIfNeeded() {
        guard calls.isEmpty else { return }
        let calendar = Calendar.current
        calls = [
            Call(
                id: "1",
                mentorName: "Amit Sawi",
                mentorRole: "Junior Artist",
                date: calendar.date(byAdding: .day, value: 2, to: Date())!,
                services: ["Acting", "Voice Over"],
                avatarName: "Image",
                status: .upcoming
            )
        ]
    }
}

// MARK: - Table / Collection
extension MentorPanelViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        segmentControl.selectedSegmentIndex == 0 ? sessions.count : calls.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentControl.selectedSegmentIndex == 0 {
            let cell = tv.dequeueReusableCell(
                withIdentifier: SessionCell.reuseIdentifier,
                for: indexPath
            ) as! SessionCell
            cell.configure(with: sessions[indexPath.row])
            return cell
        } else {
            let cell = tv.dequeueReusableCell(
                withIdentifier: CallCell.reuseIdentifier,
                for: indexPath
            ) as! CallCell
            cell.configure(with: calls[indexPath.row])
            return cell
        }
    }

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)

        if segmentControl.selectedSegmentIndex == 0 {
            let vc = SessionDetailViewController()
            vc.session = sessions[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = MentorSessionDetailViewController()
            vc.call = calls[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension MentorPanelViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mentors.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = cv.dequeueReusableCell(
            withReuseIdentifier: MentorCell.reuseIdentifier,
            for: indexPath
        ) as! MentorCell
        c.configure(with: mentors[indexPath.item])
        return c
    }

    func collectionView(
        _ cv: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let insets = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let width = floor((cv.bounds.width - insets - spacing) / 2.0)
        return CGSize(width: width, height: width * 0.85)
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = BookViewController()
        vc.mentor = mentors[indexPath.item]
        navigationController?.pushViewController(vc, animated: true)
    }
}
