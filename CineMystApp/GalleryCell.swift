//  GalleryCell.swift
//  CineMystApp
//

import UIKit

final class GalleryCell: UICollectionViewCell {
    static let reuseId = "GalleryCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .darkGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(imageName: String) {
        imageView.image = UIImage(named: imageName)
    }
    
    func configureWithURL(imageURL: String) {
        guard let url = URL(string: imageURL) else {
            imageView.image = UIImage(systemName: "photo.fill")
            imageView.tintColor = .gray
            return
        }
        
        // Load image from URL
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(systemName: "photo.fill")
                    self?.imageView.tintColor = .gray
                }
                return
            }
            
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
