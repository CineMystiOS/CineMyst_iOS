//
//  WorkshopCell.swift
//  CineMystApp
//

import UIKit

final class WorkshopCell: UICollectionViewCell {
    static let reuseId = "WorkshopCell"
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let typeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        lbl.textColor = UIColor(white: 0.7, alpha: 1)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let locationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        lbl.textColor = UIColor(white: 0.7, alpha: 1)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let durationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        lbl.textColor = UIColor(white: 0.7, alpha: 1)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor(white: 0.08, alpha: 1)
        layer.cornerRadius = 8
        
        addSubview(titleLabel)
        addSubview(typeLabel)
        addSubview(locationLabel)
        addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            typeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            typeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            locationLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            locationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            durationLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            durationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            durationLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with workshop: Workshop) {
        titleLabel.text = workshop.title
        typeLabel.text = workshop.type
        locationLabel.text = workshop.location.isEmpty ? nil : workshop.location
        durationLabel.text = workshop.duration.isEmpty ? nil : workshop.duration
    }
}
