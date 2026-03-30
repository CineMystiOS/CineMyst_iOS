//
// RescheduleConfirmationViewController.swift
// CineMystApp
//
// Small confirmation card shown after reschedule.
//

import UIKit

final class RescheduleConfirmationViewController: UIViewController {

    /// Called when user taps Done
    var onDone: (() -> Void)?

    /// Configurable texts (set before presenting)
    var titleText: String? = "Rescheduled"
    var messageText: String? = "Your session was successfully rescheduled."

    // MARK: UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.45)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.backgroundColor = UIColor(red: 0.94, green: 0.9, blue: 0.98, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let checkImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = UIColor(red: 0.4, green: 0.15, blue: 0.31, alpha: 1)
        iv.contentMode = .center
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Rescheduled"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your session was successfully rescheduled."
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var doneButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.title = "Done"
        cfg.baseBackgroundColor = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1)
        cfg.baseForegroundColor = .white
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 42).isActive = true
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return b
    }()

    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
        setupViews()

        // Apply configured texts
        titleLabel.text = titleText
        subtitleLabel.text = messageText

        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped(_:)))
        dimView.addGestureRecognizer(tap)
    }

    private func setupViews() {
        view.addSubview(dimView)
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        cardView.addSubview(iconContainer)
        iconContainer.addSubview(checkImage)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(doneButton)

        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconContainer.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),

            checkImage.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            checkImage.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            checkImage.widthAnchor.constraint(equalToConstant: 18),
            checkImage.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            doneButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            doneButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            doneButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18)
        ])
    }

    // MARK: actions
    @objc private func doneTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDone?()
        }
    }

    @objc private func dimTapped(_ g: UITapGestureRecognizer) {
        dismiss(animated: true) { [weak self] in
            self?.onDone?()
        }
    }
}
