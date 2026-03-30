//
//  AllCallsPanelViewController.swift
//  ProgrammaticMentorship
//

import UIKit

// MARK: - Model
struct CallItem {
    let id: String
    let mentorName: String
    let mentorRole: String
    let date: Date
    let services: [String]
    let avatarName: String?
    let status: Status

    enum Status {
        case upcoming
        case ended
        case canceled

        var text: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .ended: return "Ended"
            case .canceled: return "Canceled"
            }
        }

        var color: UIColor {
            switch self {
            case .upcoming: return .systemGreen
            case .ended: return .systemRed
            case .canceled: return .systemOrange
            }
        }
    }
}

// MARK: - Cell
final class CallItemCell: UITableViewCell {

    static let reuseIdentifier = "CallItemCell"

    private let cardView = UIView()
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let servicesLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {

        cardView.backgroundColor = .systemGray6
        cardView.layer.cornerRadius = 18
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 32
        avatar.clipsToBounds = true
        avatar.backgroundColor = .systemGray5

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        roleLabel.font = .systemFont(ofSize: 12)
        roleLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 12)
        timeLabel.font = .systemFont(ofSize: 12)
        servicesLabel.font = .systemFont(ofSize: 13)
        servicesLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let infoStack = UIStackView(arrangedSubviews: [
            nameLabel, roleLabel, dateLabel, timeLabel, servicesLabel
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(avatar)
        cardView.addSubview(infoStack)
        cardView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            avatar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatar.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 64),
            avatar.heightAnchor.constraint(equalToConstant: 64),

            infoStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            infoStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -12),

            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            statusLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18)
        ])
    }

    func configure(with call: CallItem) {

        nameLabel.text = call.mentorName
        roleLabel.text = call.mentorRole

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let parts = df.string(from: call.date).split(separator: ",")

        dateLabel.text = "📅 \(parts.first ?? "")"
        timeLabel.text = "⏰ \(parts.last ?? "")"
        servicesLabel.text = "Services  \(call.services.joined(separator: ", "))"

        statusLabel.text = call.status.text
        statusLabel.textColor = call.status.color

        if let name = call.avatarName, let img = UIImage(named: name) {
            avatar.image = img
            avatar.contentMode = .scaleAspectFill
        } else {
            avatar.image = UIImage(systemName: "person.crop.circle")
            avatar.tintColor = .systemGray3
            avatar.contentMode = .center
        }
    }
}

// MARK: - ViewController
final class AllCallsPanelViewController: UIViewController {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Upcoming", "Past", "Canceled"])
    private let tableView = UITableView()

    private var allCalls: [CallItem] = []
    private var displayedCalls: [CallItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hidesBottomBarWhenPushed = true

        setupUI()
        setupConstraints()
        setupTable()

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        loadSampleData()
        applyFilter()
    }

    private func setupUI() {
        titleLabel.text = "All calls"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)

        subtitleLabel.text = "Track all your calls"
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        segmentedControl.backgroundColor = .systemGray5
        segmentedControl.selectedSegmentTintColor = .white

        [titleLabel, subtitleLabel, segmentedControl, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            segmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 320),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTable() {
        tableView.register(CallItemCell.self, forCellReuseIdentifier: CallItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
    }

    // MARK: - Data
    private func loadSampleData() {
        let cal = Calendar.current
        allCalls = [
            CallItem(
                id: "1",
                mentorName: "Amit Sawi",
                mentorRole: "Junior Artist",
                date: cal.date(byAdding: .day, value: 2, to: Date())!,
                services: ["Acting", "Voice Over"],
                avatarName: "Image",
                status: .upcoming
            )
        ]
    }

    // MARK: - Filtering (CORRECT)
    @objc private func segmentChanged() {
        applyFilter()
    }

    private func applyFilter() {

        switch segmentedControl.selectedSegmentIndex {

        case 0: // UPCOMING
            displayedCalls = allCalls.filter { $0.status == .upcoming }
            tableView.backgroundView = nil

        case 1: // PAST
            displayedCalls = allCalls.filter { $0.status == .ended }
            setEmptyText(displayedCalls.isEmpty ? "No past sessions" : nil)

        case 2: // CANCELED
            displayedCalls = allCalls.filter { $0.status == .canceled }
            setEmptyText(displayedCalls.isEmpty ? "No canceled sessions" : nil)

        default:
            displayedCalls = []
            tableView.backgroundView = nil
        }

        tableView.reloadData()
    }

    private func setEmptyText(_ text: String?) {
        if let text = text {
            let label = UILabel()
            label.text = text
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .secondaryLabel
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - Table Delegates
extension AllCallsPanelViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedCalls.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(
            withIdentifier: CallItemCell.reuseIdentifier,
            for: indexPath
        ) as! CallItemCell
        cell.configure(with: displayedCalls[indexPath.row])
        return cell
    }
}
