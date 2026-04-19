import UIKit
import Supabase

// MARK: - AllCastingsViewController
// Shows every active casting call regardless of location
final class AllCastingsViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let jobListStack: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 12
        return s
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text          = "No castings match your filters"
        l.textColor     = CineMystTheme.brandPlum.withAlphaComponent(0.5)
        l.font          = .systemFont(ofSize: 16, weight: .medium)
        l.textAlignment = .center
        l.isHidden      = true
        return l
    }()
    
    // Filter State
    private var selectedRole: String?
    private var selectedPos: String?
    private var selectedProj: String?
    private var selectedEarn: Float?
    private var selectedLoc: String?
    private var allJobs: [Job] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "All Castings"
        view.backgroundColor = CineMystTheme.pinkPale

        let filter = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
                                     style: .plain, target: self, action: #selector(openFilter))
        filter.tintColor = CineMystTheme.brandPlum
        navigationItem.rightBarButtonItem = filter

        setupScrollView()
        setupLoading()
        Task { await loadJobs() }
    }

    // MARK: - Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        jobListStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(jobListStack)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            jobListStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            jobListStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            jobListStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            jobListStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100),

            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80)
        ])
    }

    private func setupLoading() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = CineMystTheme.brandPlum
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
    }

    // MARK: - Data
    private func applyFilters() {
        let filtered = allJobs.filter { job in
            if let r = selectedRole, job.jobType != r { return false }
            if let p = selectedPos, job.title?.contains(p) == false { return false }
            // Note: project type/role pref often match jobType in this simple schema
            if let pr = selectedProj, job.jobType != pr { return false }
            if let e = selectedEarn, (job.ratePerDay ?? 0) < Int(e) { return false }
            if let l = selectedLoc, job.location?.contains(l) == false { return false }
            return true
        }

        renderJobs(filtered)
    }

    private func renderJobs(_ jobs: [Job]) {
        jobListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        loadingIndicator.stopAnimating()
        
        if jobs.isEmpty {
            emptyLabel.isHidden = false
            return
        }
        emptyLabel.isHidden = true

        for (index, job) in jobs.enumerated() {
            let card = JobCardView()
            Task {
                let directorUuid = job.directorId ?? UUID()
                let companyInfo  = await self.fetchProductionHouse(directorId: directorUuid)
                let appCount     = await self.fetchApplicationCount(jobId: job.id)
                let assocTask    = try? await JobsService.shared.fetchTaskForJob(jobId: job.id)
                var profileImage: UIImage? = nil
                
                if let directorId = job.directorId,
                   let dirProf = try? await ProfileService.shared.fetchUserProfile(userId: directorId),
                   let urlStr  = dirProf.profile.profilePictureUrl,
                   let url     = URL(string: urlStr),
                   let (data, _) = try? await URLSession.shared.data(from: url) {
                    profileImage = UIImage(data: data)
                }
                
                await MainActor.run {
                    let company = (companyInfo != "Production House" && !companyInfo.isEmpty)
                        ? companyInfo
                        : (job.companyName.flatMap { $0.isEmpty ? nil : $0 } ?? "CineMyst Production")
                    
                    let rate = (job.ratePerDay ?? 0) > 0 ? "₹ \(job.ratePerDay!)/day" : "Negotiable"
                    
                    card.configure(
                        image: profileImage ?? UIImage(named: "avatar_placeholder"),
                        title: job.title ?? "Untitled",
                        company: company,
                        location: job.location ?? "Remote",
                        salary: rate,
                        daysLeft: job.daysLeftText,
                        tag: job.jobType ?? "Film",
                        appliedCount: "\(appCount) applied",
                        hasTask: assocTask != nil
                    )
                    
                    card.updateBookmark(isBookmarked: BookmarkManager.shared.isBookmarked(job.id))
                    
                    card.onApplyTap = { [weak self] in
                        if let task = assocTask {
                            let vc = TaskDetailsViewController()
                            vc.job = job; vc.task = task
                            self?.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            self?.directApply(job: job)
                        }
                    }
                }
            }
            
            card.onTap = { [weak self] in
                let vc = JobDetailsViewController()
                vc.job = job
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            
            card.onBookmarkTap = {
                _ = BookmarkManager.shared.toggle(job.id)
                card.updateBookmark(isBookmarked: BookmarkManager.shared.isBookmarked(job.id))
            }

            card.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 24)
            jobListStack.addArrangedSubview(card)
            
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveEaseOut) {
                card.alpha = 1
                card.transform = .identity
            }
        }
    }

    private func loadJobs() async {
        do {
            let fetched = try await JobsService.shared.fetchActiveJobs()
            allJobs = fetched
            await MainActor.run {
                applyFilters()
            }
        } catch {
            await MainActor.run {
                loadingIndicator.stopAnimating()
                emptyLabel.text = "Failed to load castings"
                emptyLabel.isHidden = false
            }
        }
    }

    // MARK: - Helpers
    private func fetchProductionHouse(directorId: UUID) async -> String {
        struct CastingProfile: Codable {
            let companyName: String?
            let productionHouse: String?
            enum CodingKeys: String, CodingKey {
                case companyName = "company_name"
                case productionHouse = "production_house"
            }
        }
        if let prof = try? await supabase.from("casting_profiles")
            .select("company_name, production_house")
            .eq("id", value: directorId.uuidString)
            .single().execute().value as CastingProfile {
            return prof.productionHouse ?? prof.companyName ?? "Production House"
        }
        return "Production House"
    }

    private func fetchApplicationCount(jobId: UUID) async -> Int {
        (try? await supabase.from("applications")
            .select("*", head: false, count: .exact)
            .eq("job_id", value: jobId.uuidString)
            .execute().count) ?? 0
    }

    private func directApply(job: Job) {
        let alert = UIAlertController(title: "Confirm Application",
                                      message: "Apply to \(job.title ?? "this job") by sending your portfolio?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { _ in
            Task {
                guard let user = supabase.auth.currentUser else { return }
                let newApp = Application(
                    id: UUID(), jobId: job.id, actorId: user.id,
                    status: .portfolioSubmitted,
                    portfolioUrl: user.userMetadata["portfolio_url"] as? String,
                    portfolioSubmittedAt: Date(), appliedAt: Date(), updatedAt: Date()
                )
                _ = try? await supabase.from("applications").insert(newApp).execute()
            }
        })
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func openFilter() {
        let vc = FilterScrollViewController()
        vc.selectedRolePreference = selectedRole
        vc.selectedPosition = selectedPos
        vc.selectedProjectType = selectedProj
        vc.selectedEarning = selectedEarn
        vc.selectedLocation = selectedLoc

        vc.onFiltersApplied = { [weak self] role, pos, proj, earn, loc in
            self?.selectedRole = role
            self?.selectedPos = pos
            self?.selectedProj = proj
            self?.selectedEarn = earn
            self?.selectedLoc = loc
            self?.applyFilters()
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(nav, animated: true)
    }
}
