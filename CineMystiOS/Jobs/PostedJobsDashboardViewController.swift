import UIKit
import Supabase

class PostedJobsDashboardViewController: UIViewController {

    // MARK: - UI Colors
    private let themeColor = CineMystTheme.brandPlum
    private let backgroundGradient = CAGradientLayer()

    // MARK: - UI Elements

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = CineMystTheme.brandPlum
        return btn
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Posted Castings"
        lbl.font = .systemFont(ofSize: 26, weight: .bold)
        lbl.textColor = CineMystTheme.ink
        return lbl
    }()

    private lazy var postJobButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add a role", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.layer.cornerRadius = 16
        btn.backgroundColor = themeColor
        let icon = UIImage(systemName: "plus.circle.fill")
        btn.setImage(icon, for: .normal)
        btn.tintColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        btn.layer.shadowColor = CineMystTheme.brandPlum.withAlphaComponent(0.34).cgColor
        btn.layer.shadowOpacity = 0.28
        btn.layer.shadowRadius = 12
        btn.layer.shadowOffset = CGSize(width: 0, height: 8)
        return btn
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Active", "Pending", "Completed"])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        sc.selectedSegmentTintColor = CineMystTheme.brandPlum
        sc.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.white
        ], for: .selected)
        sc.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: CineMystTheme.brandPlum.withAlphaComponent(0.65)
        ], for: .normal)
        sc.layer.cornerRadius = 16
        sc.layer.borderWidth = 1
        sc.layer.borderColor = CineMystTheme.brandPlum.withAlphaComponent(0.12).cgColor
        return sc
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Track your casting journey in one place"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = CineMystTheme.brandPlum.withAlphaComponent(0.62)
        return lbl
    }()

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()
    
    private let loader = UIActivityIndicatorView(style: .medium)
    private let emptyStateLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No jobs found in this section"
        lbl.textColor = .gray
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 14)
        lbl.isHidden = true
        return lbl
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CineMystTheme.pinkPale
        setupBackground()

        setupLayout()
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        postJobButton.addTarget(self, action: #selector(didTapPostJob), for: .touchUpInside)
        loadCards(for: 0) // load active jobs initially
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            // Hide tab bar only
            tabBarController?.tabBar.isHidden = true
            
            // Reload data to show updated job statuses
            loadCards(for: segmentedControl.selectedSegmentIndex)

            // If you also have a floating button on your custom TabBarController,
            // you'll need to hide/show it here as well. Example:
            // (Assuming your tabBar controller has a `floatingButton` property)
            //
            // if let tb = tabBarController as? CineMystTabBarController {
            //     tb.setFloatingButton(hidden: true)
            // }
        }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            // Restore tab bar only
            tabBarController?.tabBar.isHidden = false

            // Restore floating button if you hid it above:
            // if let tb = tabBarController as? CineMystTabBarController {
            //     tb.setFloatingButton(hidden: false)
            // }
        }

    @objc private func didTapPostJob() {
        let vc = PostJobViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Layout
    private func setupLayout() {

        // Removed backButton
        // view.addSubview(backButton)

        view.addSubview(titleLabel)
        view.addSubview(postJobButton)
        view.addSubview(segmentedControl)
        view.addSubview(subtitleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(loader)
        view.addSubview(emptyStateLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        postJobButton.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        loader.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            // ⬇️ Title now aligned directly to safe area (no back button)
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            // Post Job button aligned with title
            postJobButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            postJobButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            postJobButton.heightAnchor.constraint(equalToConstant: 32),
            postJobButton.widthAnchor.constraint(equalToConstant: 100),

            // Segment control now below the title
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),

            subtitleLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 100),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.988, green: 0.978, blue: 0.984, alpha: 1).cgColor,
            CineMystTheme.plumMist.cgColor,
            UIColor(red: 0.936, green: 0.892, blue: 0.917, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.45, 1]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }


    // MARK: - Load Cards
    private var currentTask: Task<Void, Never>?

    private func loadCards(for index: Int) {
        currentTask?.cancel()
        
        let sectionName = ["Active Jobs", "Pending", "Completed"][index]
        print("📱 Loading \(sectionName) section...")
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.loader.startAnimating()
                self.emptyStateLabel.isHidden = true
                self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            }
            
            guard let userId = supabase.auth.currentUser?.id else {
                print("❌ User not authenticated")
                await MainActor.run { self.loader.stopAnimating() }
                return
            }
            
            let status: Job.JobStatus?
            switch index {
            case 0: status = .active
            case 1: status = .pending
            case 2: status = .completed
            default: status = nil
            }
            
            do {
                print("🔍 Fetching jobs with status: \(status?.rawValue ?? "all") for director: \(userId.uuidString)")
                let jobs = try await JobsService.shared.fetchJobsByDirector(directorId: userId, status: status)
                print("✅ Found \(jobs.count) jobs for \(sectionName)")
                
                var displayJobs = jobs
                
                // Fetch director profile ONCE as all these jobs are by the same director
                var profilePictureUrl: String? = nil
                do {
                    let directorProfile = try await ProfileService.shared.fetchUserProfile(userId: userId)
                    profilePictureUrl = directorProfile.profile.profilePictureUrl
                } catch {
                    print("⚠️ Failed to fetch director profile: \(error)")
                }
                
                // DATA HEALING: If we are in Active Jobs, check if any should actually be Pending
                if index == 0 {
                    for job in jobs {
                        do {
                            let shortlistedCount: Int = try await supabase
                                .from("applications")
                                .select("id", head: true, count: .exact)
                                .eq("job_id", value: job.id.uuidString)
                                .in("status", values: ["shortlisted", "selected"])
                                .execute()
                                .count ?? 0
                            
                            if shortlistedCount > 0 {
                                print("🛠 Auto-healing job \(job.id.uuidString.prefix(8)): Moving to PENDING")
                                _ = try? await supabase.from("jobs").update(["status": "pending"]).eq("id", value: job.id.uuidString).execute()
                                if let idx = displayJobs.firstIndex(where: { $0.id == job.id }) {
                                    displayJobs.remove(at: idx)
                                }
                            }
                        } catch {}
                    }
                }
                
                await MainActor.run {
                    self.loader.stopAnimating()
                    
                    if displayJobs.isEmpty {
                        self.emptyStateLabel.isHidden = false
                        self.emptyStateLabel.text = "No \(sectionName.lowercased()) postings yet."
                    } else {
                        self.emptyStateLabel.isHidden = true
                        for job in displayJobs {
                            let jobCardModel = job.toJobCardModel(applicationsCount: 0, profilePictureUrl: profilePictureUrl)
                            let card = JobTrackCardView()
                            let isCompleted = index == 2
                            let buttonTitle = isCompleted ? "View Selected" : "View Applications"
                            
                            card.configure(with: jobCardModel, buttonTitle: buttonTitle)
                            card.onViewApplicationsTapped = { [weak self] in
                                if isCompleted {
                                    let vc = ActorProfileViewController()
                                    self?.navigationController?.pushViewController(vc, animated: true)
                                } else {
                                    let vc = SwipeScreenViewController()
                                    vc.job = job
                                    self?.navigationController?.pushViewController(vc, animated: true)
                                }
                            }
                            self.stackView.addArrangedSubview(card)
                        }
                    }
                }
            } catch {
                print("❌ Error loading director jobs: \(error)")
                await MainActor.run { self.loader.stopAnimating() }
            }
        }
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        loadCards(for: sender.selectedSegmentIndex)
    }
}



// MARK: - Hex Color Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
