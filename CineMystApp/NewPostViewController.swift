//
//  NewPostViewController.swift
//  CineMystApp
//
//  Created by user@50 on 20/11/25.
//

import UIKit

final class NewPostViewController: UIViewController {
    
    private let images: [UIImage]
    var onPostCompleted: (() -> Void)?
    
    private let captionTextView = UITextView()
    private let collectionView: UICollectionView
    
    init(images: [UIImage]) {
        self.images = images
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 12
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        navigationItem.title = "New Post"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Share",
            style: .done,
            target: self,
            action: #selector(sharePost)
        )
        
        // preview
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        
        captionTextView.font = .systemFont(ofSize: 17)
        captionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        captionTextView.layer.borderWidth = 1
        captionTextView.layer.cornerRadius = 8
        
        view.addSubview(collectionView)
        view.addSubview(captionTextView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        captionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 110),
            
            captionTextView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            captionTextView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    @objc private func sharePost() {
        // Upload the post to backend here
        
        dismiss(animated: true) {
            self.onPostCompleted?()
        }
    }
}

extension NewPostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let img = UIImageView(image: images[indexPath.row])
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.frame = cell.bounds
        
        cell.contentView.addSubview(img)
        return cell
    }
}
