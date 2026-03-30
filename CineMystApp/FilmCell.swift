//
//  FilmCell.swift
//  CineMystApp
//

import UIKit

final class FilmCell: UICollectionViewCell {
    static let reuseId = "FilmCell"
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .darkGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let trailerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("TRAILER", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        btn.backgroundColor = UIColor(white: 0, alpha: 0.7)
        btn.layer.cornerRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let yearLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let roleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let productionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        lbl.textColor = UIColor(white: 0.7, alpha: 1)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let galleryStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .black
        
        addSubview(posterImageView)
        posterImageView.addSubview(trailerButton)
        addSubview(yearLabel)
        addSubview(titleLabel)
        addSubview(roleLabel)
        addSubview(productionLabel)
        addSubview(galleryStackView)
        
        // Add gallery images (2 thumbnails)
        for _ in 0..<2 {
            let imgView = UIImageView()
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imgView.layer.cornerRadius = 4
            imgView.backgroundColor = .darkGray
            galleryStackView.addArrangedSubview(imgView)
        }
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            posterImageView.heightAnchor.constraint(equalToConstant: 200),
            
            trailerButton.bottomAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: -12),
            trailerButton.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: -12),
            trailerButton.widthAnchor.constraint(equalToConstant: 60),
            trailerButton.heightAnchor.constraint(equalToConstant: 24),
            
            yearLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 12),
            yearLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            roleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            productionLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 4),
            productionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            galleryStackView.topAnchor.constraint(equalTo: productionLabel.bottomAnchor, constant: 12),
            galleryStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryStackView.heightAnchor.constraint(equalToConstant: 80),
            galleryStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with film: Film) {
        titleLabel.text = film.title
        yearLabel.text = film.year
        roleLabel.text = "Role: \(film.role)"
        productionLabel.text = film.production
        posterImageView.image = UIImage(named: film.imageName)
        
        // Set gallery images if available
        if let arrangedSubviews = galleryStackView.arrangedSubviews as? [UIImageView] {
            for (index, imgView) in arrangedSubviews.enumerated() {
                imgView.image = UIImage(named: "\(film.imageName)_\(index + 1)")
            }
        }
    }
}
