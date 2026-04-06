
import UIKit
import AVFoundation
import UniformTypeIdentifiers
import PhotosUI

// MARK: - Reels View Controller
final class ReelsViewController: UIViewController {
    
    private var reels: [Reel] = []
    private var currentIndex: Int = 0
    private var isLoadingMore = false
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        cv.delegate = self
        cv.dataSource = self
        cv.register(ReelCell.self, forCellWithReuseIdentifier: ReelCell.identifier)
        return cv
    }()
    
    // Gradient FAB container — round, bottom-right
    private let createButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = false
        v.layer.shadowColor   = UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1).cgColor
        v.layer.shadowOpacity = 0.7
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        v.layer.shadowRadius  = 12
        return v
    }()

    private let createButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: "sparkles", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        return btn
    }()

    // Gradient layer for the FAB (inserted in viewDidLoad after layout)
    private let fabGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors    = [UIColor(red: 0.80, green: 0.45, blue: 0.66, alpha: 1).cgColor,
                       UIColor(red: 0.26, green: 0.09, blue: 0.19, alpha: 1).cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        g.cornerRadius = 30
        return g
    }()
    
    // Top-left title
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Flicks"
        lbl.font = .systemFont(ofSize: 28, weight: .heavy)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        // Subtle drop shadow for readability over videos
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowOpacity = 0.5
        lbl.layer.shadowOffset = CGSize(width: 0, height: 2)
        lbl.layer.shadowRadius = 4
        return lbl
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        configureAudioSession()
        setupCollectionView()
        setupCreateButton()
        loadInitialReels()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fabGradient.frame = createButtonContainer.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        reels = []
        collectionView.reloadData()
        Task { await fetchReelsFromSupabase() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        pauseCurrentVideo()
    }
    
    // MARK: - Audio Session
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.contentInsetAdjustmentBehavior = .never

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add title over collection view
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupCreateButton() {
        view.addSubview(createButtonContainer)
        createButtonContainer.layer.addSublayer(fabGradient)
        
        createButtonContainer.addSubview(createButton)
        
        let recordAction = UIAction(title: "Record Video", image: UIImage(systemName: "video.fill")) { [weak self] _ in
            self?.openCamera()
        }
        let uploadAction = UIAction(title: "Upload from Library", image: UIImage(systemName: "photo.on.rectangle.angled")) { [weak self] _ in
            self?.openLibrary()
        }
        
        let menu = UIMenu(title: "", children: [recordAction, uploadAction])
        createButton.menu = menu
        createButton.showsMenuAsPrimaryAction = true

        NSLayoutConstraint.activate([
            createButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            createButtonContainer.widthAnchor.constraint(equalToConstant: 60),
            createButtonContainer.heightAnchor.constraint(equalToConstant: 60),

            createButton.topAnchor.constraint(equalTo: createButtonContainer.topAnchor),
            createButton.bottomAnchor.constraint(equalTo: createButtonContainer.bottomAnchor),
            createButton.leadingAnchor.constraint(equalTo: createButtonContainer.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: createButtonContainer.trailingAnchor)
        ])
    }
    
    // MARK: - Photo/Video Actions
    private func openCamera() {
        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func openLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Data Loading
    private func loadInitialReels() {
        Task {
            await fetchReelsFromSupabase()
        }
    }
    
    private func fetchReelsFromSupabase() async {
        do {
            let offset = reels.count
            let flicks = try await FlicksService.shared.fetchFlicks(limit: 10, offset: offset)

            // Batch-check liked status concurrently for all fetched flicks
            var likedMap: [String: Bool] = [:]
            await withTaskGroup(of: (String, Bool).self) { group in
                for flick in flicks {
                    group.addTask {
                        let liked = (try? await FlicksService.shared.isFlickLiked(flickId: flick.id)) ?? false
                        return (flick.id, liked)
                    }
                }
                for await (id, liked) in group {
                    likedMap[id] = liked
                }
            }

            let newReels = flicks.map { flick in
                Reel.from(flick: flick, isLiked: likedMap[flick.id] ?? false)
            }

            if offset == 0 {
                reels = newReels
            } else {
                reels.append(contentsOf: newReels)
            }
            collectionView.reloadData()

        } catch {
            print("❌ Failed to fetch flicks: \(error)")
            if reels.isEmpty { showEmptyState() }
        }
    }

    // Call this to force a fresh reload (e.g. after posting)
    func refreshFlicks() {
        reels = []
        collectionView.reloadData()
        Task { await fetchReelsFromSupabase() }
    }
    
    private func checkLikesForReels() async {
        for (index, reel) in reels.enumerated() {
            if let isLiked = try? await FlicksService.shared.isFlickLiked(flickId: reel.id) {
                await MainActor.run {
                    // Update reel with like status
                    let updatedReel = Reel(
                        id: reel.id,
                        userId: reel.userId,
                        videoURL: reel.videoURL,
                        authorName: reel.authorName,
                        authorUsername: reel.authorUsername,
                        authorAvatar: reel.authorAvatar,
                        authorAvatarURL: reel.authorAvatarURL,
                        likes: reel.likes,
                        comments: reel.comments,
                        shares: reel.shares,
                        audioTitle: reel.audioTitle,
                        caption: reel.caption,
                        isLiked: isLiked
                    )
                    self.reels[index] = updatedReel
                    
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = self.collectionView.cellForItem(at: indexPath) as? ReelCell {
                        cell.updateLikeStatus(isLiked: isLiked)
                    }
                }
            }
        }
    }
    
    private func showEmptyState() {
        let label = UILabel()
        label.text = "No flicks yet\n\nBe the first to post!"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateShareCount(at index: Int) async {
        guard index < reels.count else { return }
        let reel = reels[index]
        
        // Fetch updated flick data
        if let updatedFlick = try? await FlicksService.shared.fetchFlicks(limit: 1, offset: index).first {
            let updatedReel = Reel.from(flick: updatedFlick, isLiked: reel.isLiked)
            await MainActor.run {
                self.reels[index] = updatedReel
                let indexPath = IndexPath(item: index, section: 0)
                if let cell = self.collectionView.cellForItem(at: indexPath) as? ReelCell {
                    cell.configure(with: updatedReel)
                }
            }
        }
    }
    
    private func loadMoreReels() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        Task {
            await fetchReelsFromSupabase()
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
    
    // MARK: - Video Control
    private func playCurrentVideo() {
        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? ReelCell {
            cell.play()
        }
    }
    
    private func pauseCurrentVideo() {
        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? ReelCell {
            cell.pause()
        }
    }
    
    private func pauseAllExcept(index: Int) {
        for i in 0..<reels.count where i != index {
            let indexPath = IndexPath(item: i, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? ReelCell {
                cell.pause()
            }
        }
    }
    
    // MARK: - Comment Bottom Sheet
    private func showCommentSheet() {
        let commentVC = CommentBottomSheetViewController()
        commentVC.modalPresentationStyle = .pageSheet
        
        if let sheet = commentVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(commentVC, animated: true)
    }
    
    // MARK: - Share Bottom Sheet
    private func showShareSheet() {
        let shareVC = ShareBottomSheetViewController()
        shareVC.modalPresentationStyle = .pageSheet
        
        if let sheet = shareVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(shareVC, animated: true)
    }
}

// MARK: - UICollectionView DataSource
extension ReelsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ReelCell.identifier,
            for: indexPath
        ) as? ReelCell else {
            return UICollectionViewCell()
        }
        
        let reel = reels[indexPath.item]
        cell.configure(with: reel)
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UICollectionView Delegate
extension ReelsViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Use screen bounds so cells fill edge-to-edge even before layout pass
        return UIScreen.main.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageHeight = scrollView.frame.height
        let newIndex = Int(scrollView.contentOffset.y / pageHeight)
        
        if newIndex != currentIndex {
            pauseAllExcept(index: newIndex)
            currentIndex = newIndex
            playCurrentVideo()
        }
        
        if currentIndex >= reels.count - 2 {
            loadMoreReels()
        }
    }
}

// MARK: - ReelCell Delegate
extension ReelsViewController: ReelCellDelegate {

    func didTapComment(on cell: ReelCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let reel = reels[indexPath.item]
        
        let commentVC = CommentBottomSheetViewController()
        commentVC.flickId = reel.id
        commentVC.modalPresentationStyle = .pageSheet
        
        if let sheet = commentVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(commentVC, animated: true)
    }

    func didTapShare(on cell: ReelCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let reel = reels[indexPath.item]
        
        // Create share items
        let shareText = "Check out this flick by \(reel.authorName)!"
        let shareURL = URL(string: reel.videoURL)
        
        var itemsToShare: [Any] = [shareText]
        if let url = shareURL {
            itemsToShare.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true) {
            // Increment share count in backend
            Task {
                do {
                    try await FlicksService.shared.incrementShareCount(flickId: reel.id)
                    // Update local count
                    await self.updateShareCount(at: indexPath.item)
                } catch {
                    print("Failed to increment share count: \(error)")
                }
            }
        }
    }

    func didTapMore(on cell: ReelCell, sourceView: UIView) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            print("Save tapped")
        }))

        sheet.addAction(UIAlertAction(title: "Interested", style: .default, handler: { _ in
            print("Interested tapped")
        }))

        sheet.addAction(UIAlertAction(title: "Not Interested", style: .default, handler: { _ in
            print("Not Interested tapped")
        }))

        sheet.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in
            print("Report tapped")
        }))

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad popover support
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }

        present(sheet, animated: true)
    }
    
    func didTapProfile(on cell: ReelCell, userId: String) {
        let profileVC: ActorProfileViewController
        if let tappedUserId = UUID(uuidString: userId) {
            profileVC = ActorProfileViewController(userId: tappedUserId)
        } else {
            profileVC = ActorProfileViewController()
        }
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ReelsViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        // Show processing indicator if needed
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to load video: \(error.localizedDescription)")
                return
            }
            
            guard let url = url else { return }
            
            // Copy file immediately
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                DispatchQueue.main.async {
                    let composer = FlickComposerViewController(videoURL: tempURL)
                    composer.modalPresentationStyle = .fullScreen
                    self.present(composer, animated: true)
                }
            } catch {
                print("❌ Failed to copy video: \(error)")
            }
        }
    }
}

  
