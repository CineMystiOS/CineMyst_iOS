//
//  UserFlicksFeedViewController.swift
//  CineMystApp
//
//  A full-screen vertical scrolling feed of a user's Flicks (Reels).
//

import UIKit
import AVFoundation

class UserFlicksFeedViewController: UIViewController {
    
    private enum DS {
        static let blushBackground = UIColor(red: 0.986, green: 0.958, blue: 0.975, alpha: 1)
        static let mist = UIColor(red: 1.0, green: 0.992, blue: 0.997, alpha: 0.82)
        static let deepPlum = UIColor(red: 0.263, green: 0.082, blue: 0.188, alpha: 1)
        static let rose = UIColor(red: 0.854, green: 0.553, blue: 0.742, alpha: 1)
    }

    private let tableView = UITableView()
    private let backgroundGlowTop = UIView()
    private let backgroundGlowBottom = UIView()
    private let headerBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let headerTitleLabel = UILabel()
    private var flicks: [Flick] = []
    private var initialIndex: Int = 0
    private var isFirstAppearance = true
    
    // MARK: - Init
    init(flicks: [Flick], startIndex: Int = 0) {
        self.flicks = flicks
        self.initialIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
            if initialIndex < flicks.count {
                tableView.scrollToRow(at: IndexPath(row: initialIndex, section: 0), at: .top, animated: false)
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = nil
        view.backgroundColor = DS.blushBackground
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.backBarButtonItem = nil

        backgroundGlowTop.backgroundColor = DS.mist
        backgroundGlowTop.layer.cornerRadius = 140
        backgroundGlowTop.alpha = 0.95
        backgroundGlowTop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundGlowTop)

        backgroundGlowBottom.backgroundColor = DS.rose.withAlphaComponent(0.10)
        backgroundGlowBottom.layer.cornerRadius = 170
        backgroundGlowBottom.alpha = 0.9
        backgroundGlowBottom.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundGlowBottom)

        headerBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBarView)

        headerTitleLabel.text = "Flicks"
        headerTitleLabel.font = .systemFont(ofSize: 31, weight: .heavy)
        headerTitleLabel.textColor = DS.deepPlum
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBarView.addSubview(headerTitleLabel)
        
        let cfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        backButton.tintColor = DS.deepPlum
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.78)
        backButton.layer.cornerRadius = 22
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        backButton.layer.shadowColor = DS.deepPlum.withAlphaComponent(0.12).cgColor
        backButton.layer.shadowOpacity = 1
        backButton.layer.shadowRadius = 14
        backButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        headerBarView.addSubview(backButton)

        NSLayoutConstraint.activate([
            backgroundGlowTop.widthAnchor.constraint(equalToConstant: 280),
            backgroundGlowTop.heightAnchor.constraint(equalToConstant: 280),
            backgroundGlowTop.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 96),
            backgroundGlowTop.topAnchor.constraint(equalTo: view.topAnchor, constant: 84),

            backgroundGlowBottom.widthAnchor.constraint(equalToConstant: 340),
            backgroundGlowBottom.heightAnchor.constraint(equalToConstant: 340),
            backgroundGlowBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 138),
            backgroundGlowBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 96),

            headerBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            headerBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            headerBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            headerBarView.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: headerBarView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerBarView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            headerTitleLabel.centerXAnchor.constraint(equalTo: headerBarView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerBarView.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 560
        tableView.contentInset = UIEdgeInsets(top: 68, left: 0, bottom: 28, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 68, left: 0, bottom: 28, right: 0)
        tableView.register(FlickFeedCell.self, forCellReuseIdentifier: FlickFeedCell.reuseId)
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func showFlickOptions(for flick: Flick, at index: Int, sourceButton: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Edit Flick", style: .default, handler: { [weak self] _ in
            self?.showEditFlickAlert(for: flick, at: index)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete Flick", style: .destructive, handler: { [weak self] _ in
            self?.confirmDeleteFlick(flick, at: index)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceButton
            popover.sourceRect = sourceButton.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
        
        present(alert, animated: true)
    }
    
    private func showEditFlickAlert(for flick: Flick, at index: Int) {
        let alert = UIAlertController(title: "Edit Caption", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter new caption..."
            textField.text = flick.caption
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            if let newCaption = alert.textFields?.first?.text {
                self?.updateFlickCaption(flickId: flick.id, newCaption: newCaption, at: index)
            }
        }))
        
        present(alert, animated: true)
    }
    
    private func updateFlickCaption(flickId: String, newCaption: String, at index: Int) {
        Task {
            do {
                try await FlicksService.shared.updateFlickCaption(flickId: flickId, newCaption: newCaption)
                await MainActor.run {
                    var updatedFlick = self.flicks[index]
                    updatedFlick.caption = newCaption
                    self.flicks[index] = updatedFlick
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }
            } catch {
                print("❌ Error updating flick: \(error)")
            }
        }
    }
    
    private func confirmDeleteFlick(_ flick: Flick, at index: Int) {
        let alert = UIAlertController(title: "Delete Flick", message: "Are you sure you want to delete this flick?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteFlick(flick, at: index)
        }))
        present(alert, animated: true)
    }
    
    private func deleteFlick(_ flick: Flick, at index: Int) {
        Task {
            do {
                try await FlicksService.shared.deleteFlick(flickId: flick.id)
                await MainActor.run {
                    self.flicks.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }
            } catch {
                print("❌ Error deleting flick: \(error)")
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension UserFlicksFeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flicks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FlickFeedCell.reuseId, for: indexPath) as! FlickFeedCell
        let flick = flicks[indexPath.row]
        cell.configure(with: flick)
        
        cell.onMoreTap = { [weak self] button in
            self?.showFlickOptions(for: flick, at: indexPath.row, sourceButton: button)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Open the full screen player if desired, or stay in card view
        let flick = flicks[indexPath.row]
        let item = ProfileMediaItem(id: flick.id, previewURL: flick.thumbnailUrl ?? "", contentURL: flick.videoUrl ?? "", type: "video", source: .flick)
        
        // Show the existing Reel-style viewer if tapped on the card
        let reelVC = UserFlicksFeedViewController_FullScreen(flicks: flicks, startIndex: indexPath.row)
        navigationController?.pushViewController(reelVC, animated: true)
    }
}

// Rename the old full screen one to something else or keep it as a sub-viewer
class UserFlicksFeedViewController_FullScreen: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var flicks: [Flick] = []
    private var currentIndex: Int = 0
    private var isFirstAppearance = true
    
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
    
    init(flicks: [Flick], startIndex: Int = 0) {
        self.flicks = flicks
        self.currentIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 55),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    @objc private func backTapped() { navigationController?.popViewController(animated: true) }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
            collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .top, animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.playCurrentVideo() }
        } else { playCurrentVideo() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        pauseAllVideos()
    }
    
    private func playCurrentVideo() {
        let visibleCells = collectionView.visibleCells.compactMap { $0 as? ReelCell }
        for cell in visibleCells {
            let indexPath = collectionView.indexPath(for: cell)
            if indexPath?.item == currentIndex { cell.play() } else { cell.pause() }
        }
    }
    
    private func pauseAllVideos() {
        collectionView.visibleCells.forEach { ($0 as? ReelCell)?.pause() }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return flicks.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReelCell.identifier, for: indexPath) as! ReelCell
        let flick = flicks[indexPath.item]
        cell.configure(with: Reel.from(flick: flick))
        cell.setFullscreenMode(true)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { return collectionView.bounds.size }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageHeight = scrollView.frame.height
        let newIndex = Int(scrollView.contentOffset.y / pageHeight)
        if newIndex != currentIndex { currentIndex = newIndex; playCurrentVideo() }
    }
}
