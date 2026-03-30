//
//  UpcomingViewController.swift
//  CineMystApp
//
//  Programmatic "My Sessions -> Upcoming" screen (uses existing Session & SessionStore).
//

import UIKit

final class UpcomingViewController: UIViewController {

    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // MARK: - Header
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "My Sessions"
        l.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var segmented: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Upcoming", "Past", "Canceled"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.backgroundColor = UIColor.systemGray5
        sc.selectedSegmentTintColor = .white
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .normal)
        sc.layer.cornerRadius = 18
        sc.clipsToBounds = true
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return sc
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Track your upcoming sessions"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Table
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.estimatedRowHeight = 160
        tv.rowHeight = UITableView.automaticDimension
        tv.dataSource = self
        tv.delegate = self
        tv.tableFooterView = UIView()
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        return tv
    }()

    // MARK: - Data
    private var sessions: [SessionM] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        titleLabel.textColor = plum

        setupViews()
        setupConstraints()
        reloadSessions()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveSessionNotification(_:)), name: .sessionUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup UI
    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(segmented)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: g.topAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            segmented.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 38),

            subtitleLabel.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 14),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data loading & filtering
    @objc private func didReceiveSessionNotification(_ n: Notification) {
        reloadSessions()
    }

    private func reloadSessions() {
        let all = SessionStore.shared.all()
        applySegmentFilter(base: all)
        tableView.reloadData()
    }

    @objc private func segmentChanged(_ s: UISegmentedControl) {
        let all = SessionStore.shared.all()
        applySegmentFilter(base: all)
        tableView.reloadData()
        tableView.setContentOffset(.zero, animated: true)
    }

    private func applySegmentFilter(base all: [SessionM]) {
        switch segmented.selectedSegmentIndex {
        case 0: // Upcoming
            let now = Date()
            sessions = all.filter { $0.date >= now }
        case 1: // Past
            let now = Date()
            sessions = all.filter { $0.date < now }
        case 2: // Canceled
            // try to read `status` if your model has it; otherwise show none
            if Mirror(reflecting: all.first as Any).children.contains(where: { $0.label == "status" }) {
                sessions = all.filter {
                    if let s = ( ($0 as AnyObject).value(forKey: "status") as? String ) {
                        return s.lowercased() == "canceled" || s.lowercased() == "cancelled"
                    }
                    return false
                }
            } else {
                sessions = []
            }
        default:
            sessions = all
        }
    }

    // MARK: - Actions
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension UpcomingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { sessions.count }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tv.dequeueReusableCell(withIdentifier: SessionCell.reuseIdentifier, for: indexPath) as? SessionCell else {
            return UITableViewCell()
        }
        let s = sessions[indexPath.row]
        cell.configure(with: s)   // your existing SessionCell.configure(with:)
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        let s = sessions[indexPath.row]
        let detailVC = SessionDetailViewController()
        detailVC.session = s
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
