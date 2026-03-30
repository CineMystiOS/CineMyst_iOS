//
//  HomeDashboardViewController.swift
//  CineMystApp
//
//  Updated with PostComposer integration and real data loading
//

import UIKit
import SwiftUI
import PhotosUI

final class HomeDashboardViewController: UIViewController {

    // MARK: - Views
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()

    // MARK: - Data
    private var posts: [Post] = []
    private var jobs: [Job] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupTable()
        setupFloatingMenu()
        
        loadPosts()
        
        navigationItem.backButtonTitle = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh posts when returning to screen
        loadPosts()
    }

    // MARK: - Floating Menu Setup
    private func setupFloatingMenu() {
        
        let swiftUIView = FloatingMenuButton(
            didTapCamera: { [weak self] in
                self?.openCameraForPost()
            },
            didTapGallery: { [weak self] in
                self?.openGalleryForPost()
            }
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.isOpaque = false
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            hostingController.view.widthAnchor.constraint(equalToConstant: 280),
            hostingController.view.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        hostingController.didMove(toParent: self)
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        navigationItem.title = "CineMyst"
        navigationController?.navigationBar.prefersLargeTitles = true

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )

        let bellButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(bellTapped)
        )

        navigationItem.rightBarButtonItems = [bellButton, profileButton]

        searchController.searchBar.placeholder = "Search posts or jobs"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Table Setup
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .systemBackground
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        tableView.register(PostCellTableViewCell.self,
                           forCellReuseIdentifier: PostCellTableViewCell.reuseId)

        tableView.register(JobCardCell.self,
                           forCellReuseIdentifier: JobCardCell.reuseId)

        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    @objc private func handleRefresh() {
        loadPosts()
    }
    
    private func loadPosts() {
        Task {
            do {
                // Load posts from Supabase using PostManager (which handles the new post_media schema)
                let posts = try await PostManager.shared.fetchPosts(limit: 50, offset: 0)
                
                await MainActor.run {
                    self.posts = posts
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
                
            } catch {
                print("❌ Error loading posts: \(error)")
                await MainActor.run {
                    // Show dummy data if real data fails
                    loadDummyData()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    // MARK: - Dummy Data (fallback)
    private func loadDummyData() {
        // Keep this as fallback during development
        posts = []
        
        jobs = [
            Job(
                id: UUID(),
                directorId: UUID(),
                title: "Lead Actor - City of Dreams",
                companyName: "YRF Casting",
                location: "Mumbai",
                ratePerDay: 5000,
                jobType: "Web Series",
                description: "Looking for a lead actor for a web series.",
                requirements: "Acting experience preferred",
                referenceMaterialUrl: nil,
                status: .active,
                applicationDeadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                createdAt: Date(),
                updatedAt: Date()
            ),
            
            Job(
                id: UUID(),
                directorId: UUID(),
                title: "Assistant Director - Feature Film",
                companyName: "Red Chillies Entertainment",
                location: "Mumbai",
                ratePerDay: 3000,
                jobType: "Film",
                description: "Assist director during film production.",
                requirements: "Prior AD experience",
                referenceMaterialUrl: nil,
                status: .active,
                applicationDeadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        tableView.reloadData()
    }

    // MARK: - Header Button Actions
    @objc private func profileTapped() {
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }

    @objc private func bellTapped() {
        let vc = NotificationsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Comment / Share Actions
    func openComments(for post: Post) {
        let vc = CommentViewController(post: post)
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    func openShareSheet(for post: Post) {
        let vc = ShareBottomSheetController(post: post)
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
    
    // MARK: - Post Creation Actions
    private func openCameraForPost() {
        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func openGalleryForPost() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        config.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openTextOnlyPost() {
        openPostComposer(with: [])
    }
    
    private func openPostComposer(with media: [DraftMedia]) {
        let composer = PostComposerViewController(initialMedia: media)
        composer.delegate = self
        composer.modalPresentationStyle = .fullScreen
        present(composer, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search Delegate
extension HomeDashboardViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationController?.pushViewController(SearchViewController(), animated: true)
        return false
    }
}

// MARK: - Table Delegates
extension HomeDashboardViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? posts.count : jobs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PostCellTableViewCell.reuseId,
                for: indexPath
            ) as! PostCellTableViewCell

            let post = posts[indexPath.row]
            cell.configure(with: post)

            cell.profileTapped = { [weak self] in
                self?.navigationController?.pushViewController(ProfileViewController(), animated: true)
            }
            cell.commentTapped = { [weak self] in
                self?.openComments(for: post)
            }
            cell.shareTapped = { [weak self] in
                self?.openShareSheet(for: post)
            }

            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: JobCardCell.reuseId,
            for: indexPath) as! JobCardCell

        cell.configure(with: jobs[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? UITableView.automaticDimension : 180
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 440 : 180
    }
}

// MARK: - Gallery Picker Delegate
extension HomeDashboardViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        var selectedMedia: [DraftMedia] = []
        let group = DispatchGroup()
        
        for result in results {
            group.enter()
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let img = image as? UIImage {
                        selectedMedia.append(DraftMedia(image: img, videoURL: nil, type: .image))
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.openPostComposer(with: selectedMedia)
        }
    }
}

// MARK: - PostComposerDelegate
extension HomeDashboardViewController: PostComposerDelegate {
    func postComposerDidCreatePost(_ post: Post) {
        // Insert new post at the top
        posts.insert(post, at: 0)
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        
        // Show success
        let alert = UIAlertController(title: "✅ Posted!", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    func postComposerDidCancel() {
        // Nothing to do
    }
}
