//
//  MentorshipHomeViewController.swift
//  ProgrammaticMentorship
//

import UIKit
import Supabase

// MARK: - MentorCell (unchanged)
final class MentorCell: UICollectionViewCell {
    static let reuseIdentifier = "MentorCell"
    private static let imageCache = NSCache<NSString, UIImage>()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = UIColor.systemGray6
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let starImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "star.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = UIColor.systemBlue
        return iv
    }()

    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .label
        return l
    }()

    private lazy var ratingStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [starImageView, ratingLabel])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)

        cardView.addSubview(photoView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(roleLabel)
        cardView.addSubview(ratingStack)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // card fills contentView with small padding
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // photo at top, full-width with fixed aspect (keep height proportional)
            photoView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            photoView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            photoView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            photoView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.45),

            // name label below photo, anchored to leading
            nameLabel.topAnchor.constraint(equalTo: photoView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),

            // ratingStack anchored to trailing and vertically aligned with name
            ratingStack.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            ratingStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            // ensure name doesn't overlap rating: name trailing <= rating leading - 8
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: ratingStack.leadingAnchor, constant: -8),

            // roleLabel below name, leading aligned with name, bottom padding
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -12),

            // small fixed sizes for star icon
            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    func configure(with mentor: Mentor) {
        nameLabel.text = mentor.name
        roleLabel.text = mentor.role
        ratingLabel.text = String(format: "%.1f", mentor.rating)
        // Prefer remote profilePictureUrl if provided, with cache; otherwise use local asset or symbol
        photoView.image = nil
        if let urlStrRaw = mentor.profilePictureUrl, !urlStrRaw.isEmpty {
            let placeholderConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            photoView.image = UIImage(systemName: "person.crop.rectangle", withConfiguration: placeholderConfig)
            photoView.contentMode = .center
            photoView.tintColor = UIColor.systemGray3
            photoView.backgroundColor = UIColor.systemGray6

            // Try several URL creation strategies
            var candidateURLs: [URL] = []
            if let u = URL(string: urlStrRaw) { candidateURLs.append(u) }
            if let esc = urlStrRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let u2 = URL(string: esc) { candidateURLs.append(u2) }
            if !urlStrRaw.contains("://"), let u3 = URL(string: "https://\(urlStrRaw)") { candidateURLs.append(u3) }

            // try cache for any candidate key
            for c in candidateURLs {
                let key = NSString(string: c.absoluteString)
                if let cached = MentorCell.imageCache.object(forKey: key) {
                    photoView.image = cached
                    photoView.contentMode = .scaleAspectFill
                    photoView.backgroundColor = .clear
                    return
                }
            }

            Task {
                for c in candidateURLs {
                    if let (data, _) = try? await URLSession.shared.data(from: c), let img = UIImage(data: data) {
                        MentorCell.imageCache.setObject(img, forKey: NSString(string: c.absoluteString))
                        await MainActor.run {
                            self.photoView.image = img
                            self.photoView.contentMode = .scaleAspectFill
                            self.photoView.backgroundColor = .clear
                        }
                        return
                    }
                }
            }
        } else if let imageName = mentor.imageName, let img = UIImage(named: imageName) {
            photoView.image = img
            photoView.contentMode = .scaleAspectFill
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            let img = UIImage(systemName: "person.crop.rectangle", withConfiguration: config)
            photoView.image = img
            photoView.contentMode = .center
            photoView.tintColor = UIColor.systemGray3
            photoView.backgroundColor = UIColor.systemGray6
        }
    }
}

// MARK: - MentorshipHomeViewController
final class MentorshipHomeViewController: UIViewController {

    private let plum = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)

    // UI elements
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Mentorship"
        l.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Discover & learn from your mentor"
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Mentee", "Mentor"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentTintColor = .white
        sc.backgroundColor = UIColor.systemGray5
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .normal)
        sc.layer.cornerRadius = 18
        sc.layer.masksToBounds = true
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return sc
    }()

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

    private let mentorsLabel: UILabel = {
        let l = UILabel()
        l.text = "Mentors"
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let seeAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See all", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Become Mentor button (top-right)
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

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        cv.register(MentorCell.self, forCellWithReuseIdentifier: MentorCell.reuseIdentifier)
        return cv
    }()

    // mentors loaded from Supabase
    private var mentors: [Mentor] = []

    // DTO matching mentor_profiles table
    private struct MentorRecord: Codable {
        let id: String?
        let display_name: String?
        let name: String?
        let role: String?
        let rating: Double?
        let profile_picture_url: String?
        let profile_image: String?

        var displayName: String? { display_name ?? name }
        var imageURL: String? { profile_picture_url ?? profile_image }
    }

    // lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        titleLabel.textColor = plum

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(segmentControl)
        view.addSubview(emptyIcon)
        view.addSubview(emptyLabel)
        view.addSubview(mentorsLabel)
        view.addSubview(seeAllButton)
        view.addSubview(collectionView)
        view.addSubview(becomeMentorButton)

        collectionView.dataSource = self
        collectionView.delegate = self

        seeAllButton.addTarget(self, action: #selector(didTapSeeAll), for: .touchUpInside)

        setupConstraints()
        configureEmptyState(forIndex: segmentControl.selectedSegmentIndex)
        // load mentors from backend
        Task { await loadMentorsFromSupabase() }
    }

    // MARK: - Networking
    private func loadMentorsFromSupabase() async {
        do {
            let response = try await supabase
                .from("mentor_profiles")
                .select()
                .order("rating", ascending: false)
                .execute()

            let records = try JSONDecoder().decode([MentorRecord].self, from: response.data)

            let mapped: [Mentor] = records.map { r in
                let name = r.displayName ?? "Unknown"
                let role = r.role ?? ""
                let rating = r.rating ?? 0.0
                // keep imageName nil => cell will show placeholder (download separately if needed)
                return Mentor(id: r.id,
                              name: name,
                              role: role,
                              rating: rating,
                              imageName: nil,
                              profilePictureUrl: r.imageURL,
                              ratingCount: nil,
                              mentorshipAreas: nil,
                              about: nil,
                              userId: nil,
                              metadataJson: nil,
                              createdAt: nil,
                              priceCents: nil,
                              currency: nil)
            }

            await MainActor.run {
                self.mentors = mapped
                self.collectionView.reloadData()
            }
        } catch {
            print("Failed to load mentors:", error)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBecomeMentorVisibility(animated: false)
    }

    // layout
    private func setupConstraints() {
        let pagePadding: CGFloat = 20

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pagePadding),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -pagePadding),

            segmentControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            segmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentControl.widthAnchor.constraint(equalToConstant: 220),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            emptyIcon.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 26),
            emptyIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 10),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding + 8),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(pagePadding + 8)),

            mentorsLabel.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 28),
            mentorsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pagePadding),

            seeAllButton.centerYAnchor.constraint(equalTo: mentorsLabel.centerYAnchor),
            seeAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pagePadding),

            collectionView.topAnchor.constraint(equalTo: mentorsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            becomeMentorButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            becomeMentorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            becomeMentorButton.heightAnchor.constraint(equalToConstant: 32),
            becomeMentorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    // empty state
    private func configureEmptyState(forIndex index: Int) {
        if index == 0 {
            emptyIcon.image = UIImage(systemName: "square.and.pencil")
            emptyLabel.text = "No sessions yet. Book your first mentorship session to get started."
        } else {
            emptyIcon.image = UIImage(systemName: "phone.fill")
            emptyLabel.text = "No bookings yet. Become a mentor, once a mentee schedules a session, you'll see it here."
        }
    }

    // actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        UIView.transition(with: emptyIcon, duration: 0.18, options: .transitionCrossDissolve, animations: {
            self.configureEmptyState(forIndex: sender.selectedSegmentIndex)
        }, completion: nil)

        updateBecomeMentorVisibility(animated: true)
    }

    private func updateBecomeMentorVisibility(animated: Bool) {
        let shouldShow = (segmentControl.selectedSegmentIndex == 1)
        let changes = {
            self.becomeMentorButton.isHidden = !shouldShow
            self.becomeMentorButton.alpha = shouldShow ? 1.0 : 0.0
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func didTapBecomeMentor() {
        let vc = BecomeMentorViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapSeeAll() {
        let vc = AllMentorsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - Collection DataSource & Delegate
extension MentorshipHomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mentors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MentorCell.reuseIdentifier, for: indexPath) as? MentorCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: mentors[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 160, height: 170)
        }
        let insets = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let width = floor((collectionView.bounds.width - insets - spacing) / 2.0)
        let height = width * 0.85
        return CGSize(width: width, height: height)
    }

    // <-- here we push BookViewController and pass the mentor -->
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let mentor = mentors[indexPath.item]

        // instantiate BookViewController (from your file)
        let detailVC = BookViewController()
        detailVC.mentor = mentor

        // hide the tab bar when this view controller is pushed
        detailVC.hidesBottomBarWhenPushed = true

        // push if we have a navigationController (your TabBar already embeds this VC into a UINavigationController)
        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            // fallback: present modally wrapped inside a nav controller so user gets a back button
            let nav = UINavigationController(rootViewController: detailVC)
            present(nav, animated: true, completion: nil)
        }
    }

}
