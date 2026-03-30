import UIKit
import Supabase

class PostedJobsDashboardViewController: UIViewController {

    // MARK: - UI Colors
    private let themeColor = UIColor(hex: "#431631")

    // MARK: - UI Elements

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .black
        return btn
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "My Jobs and Tasks"
        lbl.font = UIFont.boldSystemFont(ofSize: 26)
        lbl.textColor = UIColor(red: 67/255, green: 0, blue: 34/255, alpha: 1)
        return lbl
    }()

    private lazy var postJobButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Post job", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.layer.cornerRadius = 15
        btn.backgroundColor = themeColor
        let icon = UIImage(systemName: "plus.circle.fill")
        btn.setImage(icon, for: .normal)
        btn.tintColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        return btn
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Active Jobs", "Pending", "Completed"])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = UIColor(white: 0.95, alpha: 1)
        sc.selectedSegmentTintColor = .white
        sc.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.black
        ], for: .selected)
        sc.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ], for: .normal)
        return sc
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Track your casting journey in one place"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .darkGray
        return lbl
    }()

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupLayout()
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        postJobButton.addTarget(self, action: #selector(didTapPostJob), for: .touchUpInside)
        loadCards(for: 0) // load active jobs initially
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

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        postJobButton.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

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
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }


    // MARK: - Load Cards
    private func loadCards(for index: Int) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let sectionName = ["Active Jobs", "Pending", "Completed"][index]
        print("📱 Loading \(sectionName) section...")
        
        // Fetch jobs from database
        Task { [weak self] in
            do {
                guard let userId = supabase.auth.currentUser?.id else {
                    print("❌ User not authenticated")
                    return
                }
                
                let status: Job.JobStatus?
                switch index {
                case 0: status = .active
                case 1: status = .pending
                case 2: status = .completed
                default: status = nil
                }
                
                print("🔍 Fetching jobs with status: \(status?.rawValue ?? "all")")
                
                let jobs = try await JobsService.shared.fetchJobsByDirector(directorId: userId, status: status)
                
                print("✅ Found \(jobs.count) jobs for \(sectionName)")
                for job in jobs {
                    print("   - \(job.title) | Status: \(job.status.rawValue) | ID: \(job.id.uuidString.prefix(8))")
                }
                
                await MainActor.run {
                    guard let self = self else { return }
                    
                    for job in jobs {
                        let jobCardModel = job.toJobCardModel(applicationsCount: 0)
                        let card = JobTrackCardView()
                        card.configure(with: jobCardModel)
                        card.onViewApplicationsTapped = { [weak self] in
                            let vc = SwipeScreenViewController()
                            vc.job = job
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                        self.stackView.addArrangedSubview(card)
                    }
                    
                    if jobs.isEmpty {
                        print("ℹ️ No jobs to display in \(sectionName)")
                    }
                }
            } catch {
                print("❌ Error loading director jobs: \(error)")
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


