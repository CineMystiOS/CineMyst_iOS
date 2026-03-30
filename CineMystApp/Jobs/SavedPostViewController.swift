import UIKit

class SavedPostViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    private var bookmarkedJobs: [Job] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = "Saved Jobs"
        
        setupNavigationBar()
        setupScrollView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedJobCards()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
        navigationController?.navigationBar.tintColor = .black
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - ScrollView + Stack Setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // stack inside scrollView
        scrollView.addSubview(contentView)
        contentView.axis = .vertical
        contentView.spacing = 20
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Load JobCardView from Backend
    private func loadSavedJobCards() {
        // Clear existing cards
        contentView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Get bookmarked job IDs from local storage
        let bookmarkedIDs = BookmarkManager.shared.allBookmarkedIDs()
        
        guard !bookmarkedIDs.isEmpty else {
            showEmptyState()
            return
        }
        
        // Load jobs from backend
        Task {
            do {
                let jobs = try await JobsService.shared.fetchJobsByIds(jobIds: bookmarkedIDs)
                self.bookmarkedJobs = jobs
                
                await MainActor.run {
                    self.displayJobCards()
                }
            } catch {
                print("❌ Error loading bookmarked jobs: \(error)")
                await MainActor.run {
                    self.showErrorState()
                }
            }
        }
    }
    
    private func displayJobCards() {
        for job in bookmarkedJobs {
            let card = JobCardView()
            card.translatesAutoresizingMaskIntoConstraints = false

            card.configure(
                image: UIImage(named: "rani2"),
                title: job.title,
                company: job.companyName,
                location: job.location,
                salary: "₹ \(job.ratePerDay)/day",
                daysLeft: job.daysLeftText,
                tag: job.jobType,
                appliedCount: "0 applied"
            )
            
            // Set bookmark state
            card.updateBookmark(isBookmarked: true)
            
            // Card tap - open job details
            card.onTap = { [weak self] in
                let detailVC = JobDetailsViewController()
                detailVC.job = job
                self?.navigationController?.pushViewController(detailVC, animated: true)
            }
            
            // Bookmark tap - remove from saved
            card.onBookmarkTap = { [weak self] in
                let newState = BookmarkManager.shared.toggle(job.id)
                card.updateBookmark(isBookmarked: newState)
                
                // Remove card from view if unbookmarked
                if !newState {
                    UIView.animate(withDuration: 0.3, animations: {
                        card.alpha = 0
                        card.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    }) { _ in
                        self?.contentView.removeArrangedSubview(card)
                        card.removeFromSuperview()
                        
                        // Show empty state if no more cards
                        if self?.contentView.arrangedSubviews.isEmpty == true {
                            self?.showEmptyState()
                        }
                    }
                }
                
                // Sync to backend
                Task {
                    do {
                        try await JobsService.shared.toggleBookmark(jobId: job.id)
                        print("✅ Bookmark removed from backend for job: \(job.title)")
                    } catch {
                        print("❌ Failed to sync bookmark removal: \(error)")
                    }
                }
            }

            contentView.addArrangedSubview(card)
        }
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No saved jobs yet\nBookmark jobs to see them here"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addArrangedSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
    }
    
    private func showErrorState() {
        let errorLabel = UILabel()
        errorLabel.text = "Failed to load saved jobs\nPlease try again"
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        errorLabel.textColor = .systemRed
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addArrangedSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
    }
}

