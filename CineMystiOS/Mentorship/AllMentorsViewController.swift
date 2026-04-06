//
//  AllMentorsViewController.swift
//  CineMystApp
//
//  Pixel-tight card layout matching provided Figma mock.
//  Uses your existing Mentor model.
//  Adds segmented control filtering for roles and a filter panel.
//

import UIKit
import Supabase

// MARK: - MentorCardCell
final class MentorCardCell: UITableViewCell {
    static let reuseIdentifier = "MentorCardCell"
    var onExtraServicesTap: (([String]) -> Void)?
    private let plum = MentorshipUI.brandPlum
    private let softPlum = MentorshipUI.plumChip
    private let deepShadow = MentorshipUI.shadow

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = MentorshipUI.raisedSurface
        v.layer.cornerRadius = 26
        v.layer.masksToBounds = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = MentorshipUI.shadow.cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 22
        v.layer.shadowOffset = CGSize(width: 0, height: 12)
        v.layer.borderWidth = 1
        v.layer.borderColor = MentorshipUI.plumStroke.cgColor
        return v
    }()

    private let cardGlowView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MentorshipUI.softSurface
        view.layer.cornerRadius = 26
        view.isUserInteractionEnabled = false
        return view
    }()

    // Left info
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        l.textColor = MentorshipUI.brandPlum
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = MentorshipUI.softText
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let orgLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Right column (price)
    private let ratingStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .trailing
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        l.textColor = MentorshipUI.brandPlum
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let pricePillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MentorshipUI.plumChip
        view.layer.cornerRadius = 14
        return view
    }()

    private let subtitleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let sessionBadge: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.backgroundColor = MentorshipUI.softSurface
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 18
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = CineMystTheme.plumMist
        return iv
    }()

    private let imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.backgroundColor = CineMystTheme.plumMist
        view.layer.borderWidth = 1
        view.layer.borderColor = MentorshipUI.plumStroke.cgColor
        return view
    }()

    private let imageGradientOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        return view
    }()

    // divider and bottom row
    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = MentorshipUI.plumStroke
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let servicesLabel: UILabel = {
        let l = UILabel()
        l.text = "Services"
        l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let tagsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .leading
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    let bookButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Book"
        cfg.cornerStyle = .capsule
        cfg.baseBackgroundColor = MentorshipUI.deepPlum
        cfg.baseForegroundColor = .white
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private var allServicesForAlert: [String] = []

    // stacking containers
    private let topRow = UIStackView()
    private let bottomRow = UIStackView()

    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        // topRow: left info + spacer + right column + photo
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 8
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // bottomRow: services label + tags + spacer + book button
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = 12
        bottomRow.distribution = .fill
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(cardGlowView)
        cardView.addSubview(topRow)
        cardView.addSubview(divider)
        cardView.addSubview(bottomRow)
        pricePillView.addSubview(priceLabel)

        // left vertical stack
        subtitleStack.addArrangedSubview(roleLabel)
        subtitleStack.addArrangedSubview(sessionBadge)
        let leftStack = UIStackView(arrangedSubviews: [nameLabel, subtitleStack, orgLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 6
        leftStack.alignment = .leading
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        // right vertical stack
        ratingStack.addArrangedSubview(pricePillView)

        // Build topRow: left, spacer, ratingStack, photo
        topRow.addArrangedSubview(leftStack)
        topRow.addArrangedSubview(UIView()) // flexible spacer
        topRow.addArrangedSubview(ratingStack)
        imageContainerView.addSubview(photoView)
        imageContainerView.addSubview(imageGradientOverlay)
        topRow.addArrangedSubview(imageContainerView)

        // Build bottomRow
        bottomRow.addArrangedSubview(servicesLabel)
        bottomRow.addArrangedSubview(tagsStack)
        bottomRow.addArrangedSubview(UIView()) // spacer
        bottomRow.addArrangedSubview(bookButton)

        // constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            cardGlowView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 1),
            cardGlowView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 1),
            cardGlowView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -1),
            cardGlowView.heightAnchor.constraint(equalToConstant: 72),

            topRow.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            topRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            topRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            imageContainerView.widthAnchor.constraint(equalToConstant: 96),
            imageContainerView.heightAnchor.constraint(equalToConstant: 96),

            photoView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            imageGradientOverlay.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageGradientOverlay.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageGradientOverlay.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            imageGradientOverlay.heightAnchor.constraint(equalTo: imageContainerView.heightAnchor, multiplier: 0.42),

            priceLabel.topAnchor.constraint(equalTo: pricePillView.topAnchor, constant: 7),
            priceLabel.leadingAnchor.constraint(equalTo: pricePillView.leadingAnchor, constant: 11),
            priceLabel.trailingAnchor.constraint(equalTo: pricePillView.trailingAnchor, constant: -11),
            priceLabel.bottomAnchor.constraint(equalTo: pricePillView.bottomAnchor, constant: -7),

            sessionBadge.heightAnchor.constraint(equalToConstant: 20),

            divider.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1),

            bottomRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            bottomRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bottomRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            bottomRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            bookButton.widthAnchor.constraint(equalToConstant: 96),
            bookButton.heightAnchor.constraint(equalToConstant: 40),

            // Ensure leftStack doesn't overgrow: leave room for right column
            leftStack.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.5)
        ])

        // --- ALIGNMENT FIX: ensure rating stack and photo align to top of topRow
        ratingStack.topAnchor.constraint(equalTo: topRow.topAnchor).isActive = true
        photoView.topAnchor.constraint(equalTo: topRow.topAnchor).isActive = true

        // default styling for tagsStack (plain text tags)
        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tagsStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tagsStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bookButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        bookButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    // Configure using your Mentor model, with static demo fields to match mock
    func configure(with mentor: Mentor) {
        nameLabel.text = mentor.name
        roleLabel.text = mentor.role
        if let sessions = mentor.sessionCount {
            sessionBadge.text = "  \(sessions) sessions  "
            sessionBadge.isHidden = false
        } else {
            sessionBadge.isHidden = true
            sessionBadge.text = nil
        }

        // orgName (casting house) and session count
        if let org = mentor.orgName, !org.isEmpty {
            orgLabel.text = org
        } else if let org = mentor.orgName {
            orgLabel.text = org
        } else {
            orgLabel.text = ""
        }

        // price from `money` column if present
        priceLabel.text = mentor.moneyString ?? ""

        // local fallback
        photoView.image = UIImage(named: mentor.imageName ?? "Image")

        // load remote profile picture if present
        if let urlString = mentor.profilePictureUrl, let url = URL(string: urlString) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let img = UIImage(data: data) {
                        await MainActor.run { self.photoView.image = img }
                    }
                } catch {
                    // ignore, keep fallback image
                }
            }
        }

        // tags — use mentorshipAreas if present
        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let tagNames = mentor.mentorshipAreas ?? []
        allServicesForAlert = tagNames

        if let first = tagNames.first {
            let label = makePlainTagLabel(text: first)
            tagsStack.addArrangedSubview(label)
        }

        if tagNames.count > 1 {
            let badge = makeMoreBadge(count: tagNames.count - 1)
            tagsStack.addArrangedSubview(badge)
        }
    }

    // Plain tag label (no background)
    private func makePlainTagLabel(text: String) -> UILabel {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = MentorshipUI.brandPlum
        label.backgroundColor = softPlum
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    private func makeMoreBadge(count: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("+\(count)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        button.setTitleColor(MentorshipUI.brandPlum, for: .normal)
        button.backgroundColor = softPlum
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.addTarget(self, action: #selector(didTapMoreServices), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    @objc private func didTapMoreServices() {
        guard !allServicesForAlert.isEmpty else { return }
        onExtraServicesTap?(allServicesForAlert)
    }
}

private final class PaddingLabel: UILabel {
    let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}

// MARK: - AllMentorsViewController
final class AllMentorsViewController: UIViewController {

    // static plum so it can be referenced from property initializers safely
    private static let plum = MentorshipUI.brandPlum

    // make backButton lazy so we can reference Self.plum inside initializer
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = Self.plum
        b.backgroundColor = MentorshipUI.softSurface
        b.layer.cornerRadius = 18
        b.layer.shadowColor = MentorshipUI.shadow.cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius = 10
        b.layer.shadowOffset = CGSize(width: 0, height: 5)
        b.layer.borderWidth = 1
        b.layer.borderColor = MentorshipUI.plumStroke.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "All Mentors"
        l.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let searchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        b.tintColor = MentorshipUI.brandPlum
        b.backgroundColor = MentorshipUI.softSurface
        b.layer.cornerRadius = 18
        b.layer.shadowColor = MentorshipUI.shadow.cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius = 10
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.layer.borderWidth = 1
        b.layer.borderColor = MentorshipUI.plumStroke.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let filterButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "line.horizontal.3.decrease"), for: .normal)
        b.tintColor = MentorshipUI.brandPlum
        b.backgroundColor = MentorshipUI.softSurface
        b.layer.cornerRadius = 18
        b.layer.shadowColor = MentorshipUI.shadow.cgColor
        b.layer.shadowOpacity = 1
        b.layer.shadowRadius = 10
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.layer.borderWidth = 1
        b.layer.borderColor = MentorshipUI.plumStroke.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let segmented: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["All", "Actor", "Director"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = MentorshipUI.brandPlum
        sc.backgroundColor = MentorshipUI.softSurface
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.layer.cornerRadius = 22
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "See all the mentors available"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = MentorshipUI.mutedText
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(MentorCardCell.self, forCellReuseIdentifier: MentorCardCell.reuseIdentifier)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.estimatedRowHeight = 160
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No mentors found"
        l.textColor = .secondaryLabel
        l.font = UIFont.systemFont(ofSize: 16)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Keep a full source and a filtered view
    private var allMentors: [Mentor] = []

    // mentors is the filtered array used by tableView
    private var mentors: [Mentor] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MentorshipUI.pageBackground

        // Hide the default navigation back button (so only our custom chevron is visible)
        navigationItem.hidesBackButton = true

        titleLabel.textColor = Self.plum
        subtitleLabel.textColor = MentorshipUI.mutedText

        setupHierarchy()
        setupConstraints()

        // wire delegates
        tableView.dataSource = self
        tableView.delegate = self

        // segmented action
        segmented.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        // wire buttons
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(presentFilter), for: .touchUpInside)

        // initial data (show all)
        mentors = allMentors
        tableView.reloadData()

        // fetch from backend
        fetchMentorsFromBackend()
    }

    // MARK: - Backend
    // Uses shared `supabase` client from `auth/Supabase.swift`
    private let supabaseClient = supabase

    private func fetchMentorsFromBackend() {
        spinner.startAnimating()
        emptyLabel.isHidden = true

        Task {
            let fetched = await MentorsProvider.fetchAll()
            await MainActor.run {
                self.spinner.stopAnimating()
                self.allMentors = fetched
                self.mentors = fetched
                self.tableView.reloadData()

                if fetched.isEmpty {
                    self.emptyLabel.text = "No mentors found"
                    self.emptyLabel.isHidden = false
                    self.addEmptyLabelTap()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 🔥 Hide the tab bar whenever this screen is visible
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore the tab bar only when this VC is being removed from its parent (popped/dismissed).
        // Do not restore if only pushing another controller (pushed vcs typically set hidesBottomBarWhenPushed = true).
        if isMovingFromParent || isBeingDismissed {
            tabBarController?.tabBar.isHidden = false
        }
    }

    // MARK: - Segment handling
    @objc private func segmentChanged(_ s: UISegmentedControl) {
        switch s.selectedSegmentIndex {
        case 0:
            mentors = allMentors
        case 1:
            // Actor
            mentors = allMentors.filter { $0.role.lowercased().contains("actor") }
        case 2:
            // Director
            mentors = allMentors.filter { $0.role.lowercased().contains("director") }
        default:
            mentors = allMentors
        }

        // refresh table and scroll to top for better UX
        tableView.reloadData()
        if mentors.count > 0 {
            tableView.setContentOffset(.zero, animated: true)
        }
    }

    // MARK: - Present filter
    @objc private func presentFilter() {
        let vc = FilterViewController()
        vc.onApplyFilters = { [weak self] filters in
            guard let self = self else { return }
            // Example: if mentorRole chosen, filter by role; otherwise show all.
            if let role = filters.mentorRole?.lowercased() {
                self.mentors = self.allMentors.filter { $0.role.lowercased().contains(role) }
            } else {
                self.mentors = self.allMentors
            }

            // Additional filters (skills/experience/price) can be applied here as needed.
            self.tableView.reloadData()
            self.tableView.setContentOffset(.zero, animated: true)
        }
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true, completion: nil)
    }

    @objc private func didTapSearch() {
        // no-op currently — add search flow if needed
        print("Search tapped")
    }

    private func addEmptyLabelTap() {
        emptyLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(retryFetch))
        emptyLabel.gestureRecognizers?.forEach { emptyLabel.removeGestureRecognizer($0) }
        emptyLabel.addGestureRecognizer(tap)
    }

    @objc private func retryFetch() {
        emptyLabel.isHidden = true
        fetchMentorsFromBackend()
    }

    private func setupHierarchy() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(searchButton)
        view.addSubview(filterButton)
        view.addSubview(segmented)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
    view.addSubview(emptyLabel)
    view.addSubview(spinner)
    }

    private func setupConstraints() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: g.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -56),
            searchButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 36),
            searchButton.heightAnchor.constraint(equalToConstant: 36),

            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 36),
            filterButton.heightAnchor.constraint(equalToConstant: 36),

            segmented.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 40),

            subtitleLabel.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 14),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // emptyLabel centered
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        // spinner centered in table area
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 80)
        ])
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - TableView
extension AllMentorsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        mentors.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tv.dequeueReusableCell(withIdentifier: MentorCardCell.reuseIdentifier, for: indexPath) as? MentorCardCell else {
            return UITableViewCell()
        }
        let m = mentors[indexPath.row]
        cell.configure(with: m)
        cell.onExtraServicesTap = { [weak self] services in
            self?.showExtraServices(services)
        }
        cell.bookButton.tag = indexPath.row
        cell.bookButton.addTarget(self, action: #selector(didTapBook(_:)), for: .touchUpInside)
        return cell
    }

    @objc private func didTapBook(_ sender: UIButton) {
        let mentor = mentors[sender.tag]

        let vc = BookViewController()   // your existing screen
        vc.mentor = mentor              // pass selected mentor
        vc.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(vc, animated: true)
    }

    private func showExtraServices(_ services: [String]) {
        let alert = UIAlertController(
            title: "Services",
            message: services.joined(separator: "\n"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    func tableView(_ tv: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        // If you want tapping a mentor to open detail, push here
    }
}
