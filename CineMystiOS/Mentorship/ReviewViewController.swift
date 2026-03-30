//
//  ReviewViewController.swift
//  CineMystApp
//
//  Created by You on Today.
//  Review page: star rating + comment + submit; tab bar hidden while visible.
//  NOTE: Only one "Write a review" label is shown (the large in-content header).
//

import UIKit

final class ReviewViewController: UIViewController, UITextViewDelegate {

    // Optional: pass mentor name if you want to show it (not required)
    private let mentorName: String?

    // MARK: - UI

    // Large in-content header (only one header; nav title is NOT set to avoid duplication)
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Write a review"
        l.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let questionLabel: UILabel = {
        let l = UILabel()
        l.text = "How was your experience?"
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let starsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 14
        s.alignment = .center
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var starButtons: [UIButton] = []

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.layer.cornerRadius = 8
        tv.layer.masksToBounds = true
        tv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let p = UILabel()
        p.text = "Tell us about your experience..."
        p.textColor = UIColor(white: 0.6, alpha: 1)
        p.font = UIFont.systemFont(ofSize: 14)
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Submit review", for: .normal)
        b.backgroundColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 10
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    // MARK: - State

    private var rating: Int = 0 {
        didSet { updateStarSelection() }
    }

    // MARK: - Init

    init(mentorName: String? = nil) {
        self.mentorName = mentorName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // do not set navigationItem.title to avoid duplicate text in the nav bar and page header
        // navigationItem.title = "Write a review" // intentionally omitted

        setupViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide tab bar while this screen is visible
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // restore tab bar when leaving
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(headerLabel)
        view.addSubview(questionLabel)
        view.addSubview(starsStack)
        view.addSubview(textView)
        textView.addSubview(placeholderLabel)
        view.addSubview(submitButton)

        textView.delegate = self

        // create 5 star buttons
        for i in 1...5 {
            let btn = UIButton(type: .system)
            btn.setImage(unfilledStarImage(), for: .normal)
            btn.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
            btn.tag = i
            btn.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            // set a reasonable intrinsic size constraint so distribution works
            btn.widthAnchor.constraint(equalToConstant: 36).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            starButtons.append(btn)
            starsStack.addArrangedSubview(btn)
        }

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 18),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -18),

            questionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 18),
            questionLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),

            starsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            starsStack.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            starsStack.heightAnchor.constraint(equalToConstant: 36),

            textView.topAnchor.constraint(equalTo: starsStack.bottomAnchor, constant: 18),
            textView.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            textView.heightAnchor.constraint(equalToConstant: 120),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 10),

            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 22),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            submitButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - Stars

    @objc private func starTapped(_ sender: UIButton) {
        // tap any star sets rating to that number (1..5)
        rating = sender.tag
    }

    private func updateStarSelection() {
        for btn in starButtons {
            if btn.tag <= rating {
                btn.setImage(filledStarImage(), for: .normal)
            } else {
                btn.setImage(unfilledStarImage(), for: .normal)
            }
        }
    }

    private func filledStarImage() -> UIImage? {
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        return UIImage(systemName: "star.fill", withConfiguration: cfg)
    }

    private func unfilledStarImage() -> UIImage? {
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        return UIImage(systemName: "star", withConfiguration: cfg)
    }

    // MARK: - UITextViewDelegate (placeholder)

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Submit

    @objc private func submitTapped() {
        let comment = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rating > 0 else {
            let alert = UIAlertController(title: "Rating required", message: "Please select a star rating before submitting.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Simulate submit (replace with network call if needed)
        let message = "You gave \(rating) star(s).\n\nComment:\n\(comment.isEmpty ? "—" : comment)"
        let alert = UIAlertController(title: "Thanks!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // pop back to previous screen
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
