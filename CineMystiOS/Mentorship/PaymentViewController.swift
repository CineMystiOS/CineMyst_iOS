//
//  PaymentViewController.swift
//  CineMystApp
//
//  Updated: presents CardEditViewController for Edit / Add and updates the card view.
//  Layout tweak: reduce gap between card and action row (edit/add).
//

import UIKit
import Supabase

final class PaymentViewController: UIViewController {

    // MARK: Theme
    private let plum = UIColor(red: 0x43/255.0, green: 0x16/255.0, blue: 0x31/255.0, alpha: 1.0)
    private let accentGray = UIColor(white: 0.4, alpha: 1.0)

    // MARK: Data passed from Schedule screen
    private let selectedArea: String?
    private let selectedDate: Date?
    private let selectedTime: String?

    /// accept mentor (optional)
    var mentor: Mentor? {
        didSet {
            // If mentor assigned after view loaded, refresh price
            Task { await loadPriceFromSessionIfNeeded() }
        }
    }

    init(area: String? = nil, date: Date? = nil, time: String? = nil) {
        self.selectedArea = area
        self.selectedDate = date
        self.selectedTime = time
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        self.selectedArea = nil
        self.selectedDate = nil
        self.selectedTime = nil
        super.init(coder: coder)
    }

    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let segment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Card", "UPI"])
        s.selectedSegmentIndex = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // --- Card Section ---
    private let cardView = UIView()

    // UI elements inside card (we will update these from CardStore)
    private let cardHolderTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "CARD HOLDER"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.9)
        return l
    }()
    private let cardHolderNameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "ANSH GAUTAM"
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = .white
        return l
    }()

    private let cardNumberTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "CARD NUMBER"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.9)
        return l
    }()
    private let cardNumberLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "3096 4347 8180"
        l.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white
        l.numberOfLines = 1
        return l
    }()

    private let expiresTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Expires"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.9)
        return l
    }()
    private let expiresValueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "02/27"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        return l
    }()

    private let cvvTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "CVV"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.9)
        l.textAlignment = .right
        return l
    }()
    private let cvvValueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "••••"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .right
        return l
    }()

    // brand dots
    private let brandDot1: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemOrange
        v.layer.cornerRadius = 10
        return v
    }()
    private let brandDot2: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemRed
        v.layer.cornerRadius = 10
        return v
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Edit card info", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13)
        b.setTitleColor(.secondaryLabel, for: .normal)
        return b
    }()
    private let addAnotherButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Add another card", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13)
        b.setTitleColor(.secondaryLabel, for: .normal)
        return b
    }()

    private lazy var cardActionsRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [editButton, UIView(), addAnotherButton])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    // --- UPI Section (unchanged) ---
    private let upiContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let upiHintLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter UPI ID or scan QR code to pay"
        l.font = .systemFont(ofSize: 14)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let upiTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter  UPI ID"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = UIColor.secondarySystemBackground
        return tf
    }()
    private let scanButton: UIButton = {
        var c = UIButton.Configuration.bordered()
        c.title = "Scan QR Code"
        c.image = UIImage(systemName: "qrcode")
        c.imagePadding = 8
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Totals + Pay (unchanged)
    private let totalTitle: UILabel = {
        let l = UILabel()
        l.text = "Total"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        return l
    }()
    private let amountLabel: UILabel = {
        let l = UILabel()
    l.text = ""
        l.font = .systemFont(ofSize: 32, weight: .bold)
        return l
    }()
    private let payButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Pay"
        c.cornerStyle = .capsule
        c.baseForegroundColor = .white
        c.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        let b = UIButton(configuration: c)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.backButtonDisplayMode = .minimal
        view.tintColor = accentGray

        navigationItem.title = "Payment"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
        setupCard()   // build card UI
        setupUPI()
        wireActions()

        payButton.configuration?.baseBackgroundColor = plum

        // show Card by default
        showCard(animated: false)
        // initial populate from store
        refreshCardFromStore()

    // Load price from mentorship_sessions table (if mentor provided)
    Task { await self.loadPriceFromSessionIfNeeded() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: Actions
    private func wireActions() {
        segment.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)

        // wire edit/add actions to present sheet
        editButton.addTarget(self, action: #selector(editCardTapped), for: .touchUpInside)
        addAnotherButton.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
    }

    @objc private func segChanged() {
        if segment.selectedSegmentIndex == 1 {
            showUPI(animated: true)
        } else {
            showCard(animated: true)
        }
    }

    @objc private func scanTapped() {
        let alert = UIAlertController(title: "Scan", message: "Scan QR code flow not implemented in this preview.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func payTapped() {
        // Present the confirmation (kept as before)
        let confirmationVC = PaymentConfirmationViewController()
        confirmationVC.mentor = self.mentor
        confirmationVC.scheduledDate = self.selectedDate
        present(confirmationVC, animated: true)
    }

    // MARK: - Card Edit/Add presentation
    @objc private func editCardTapped() {
        // present sheet with current card pre-filled
        let current = CardStore.shared.currentCard
        let vc = CardEditViewController(card: current)
        vc.onSave = { [weak self] newCard in
            // update UI immediately
            self?.applyCardToUI(newCard)
        }
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Price loading
    private func loadPriceFromSessionIfNeeded() async {
        guard let mentorId = mentor?.id else { return }
        do {
            let res = try await supabase.database
                .from("mentorship_sessions")
                .select("price_cents")
                .eq("mentor_id", value: mentorId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
            print("[Payment] price query data=\(String(describing: res.data))")
            if let rows = try rowsArray(from: res.data), !rows.isEmpty {
                if let first = rows.first as? [String: Any] {
                    var cents: Int? = nil
                    if let v = first["price_cents"] as? Int { cents = v }
                    else if let s = first["price_cents"] as? String, let iv = Int(s) { cents = iv }
                    else if let d = first["price_cents"] as? Double { cents = Int(d) }

                    if let c = cents {
                        await MainActor.run {
                            self.amountLabel.text = Self.formatPrice(cents: c)
                        }
                        return
                    }
                }
            }
        } catch {
            print("[Payment] error loading price: \(error)")
        }
    }

    private static func formatPrice(cents: Int) -> String {
        let amount = Double(cents) / 100.0
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        // prefer India/Rupee symbol if available
        nf.locale = Locale(identifier: "en_IN")
        if let s = nf.string(from: NSNumber(value: amount)) {
            return s
        }
        // fallback simple formatting
        return "₹\(Int(amount))"
    }

    // Normalize response.data into an array of Any for decoding. Matches helper in other files.
    private func rowsArray(from raw: Any?) throws -> [Any]? {
        guard let raw = raw else { return nil }
        // If it's already an array, return it
        if let arr = raw as? [Any] { return arr }
        // If it's Data representing JSON, try to decode
        if let data = raw as? Data {
            let json = try JSONSerialization.jsonObject(with: data)
            if let arr = json as? [Any] { return arr }
        }
        // If it's a string of JSON, attempt to parse
        if let s = raw as? String, let data = s.data(using: .utf8) {
            let json = try JSONSerialization.jsonObject(with: data)
            if let arr = json as? [Any] { return arr }
        }
        return nil
    }

    @objc private func addCardTapped() {
        // present sheet in "add" mode (nil card)
        let vc = CardEditViewController(card: nil)
        vc.onSave = { [weak self] newCard in
            // update UI immediately with newly added card
            self?.applyCardToUI(newCard)
        }
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Show / hide helpers
    private func showUPI(animated: Bool) {
        cardView.isHidden = true
        upiContainer.isHidden = false
        cardActionsRow.isHidden = true
        if animated {
            upiContainer.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.upiContainer.alpha = 1
            }
        }
    }

    private func showCard(animated: Bool) {
        upiContainer.isHidden = true
        cardView.isHidden = false
        cardActionsRow.isHidden = false
        if animated {
            cardView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.cardView.alpha = 1
            }
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        // bottom Pay button
        view.addSubview(payButton)
        NSLayoutConstraint.activate([
            payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            payButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        payButton.configuration?.baseBackgroundColor = plum

        // scroll content
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -12)
        ])

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Segment container
        let segContainer = UIView()
        segContainer.backgroundColor = UIColor.secondarySystemBackground
        segContainer.layer.cornerRadius = 12
        segContainer.translatesAutoresizingMaskIntoConstraints = false
        segContainer.addSubview(segment)
        NSLayoutConstraint.activate([
            segment.topAnchor.constraint(equalTo: segContainer.topAnchor, constant: 6),
            segment.leadingAnchor.constraint(equalTo: segContainer.leadingAnchor, constant: 6),
            segment.trailingAnchor.constraint(equalTo: segContainer.trailingAnchor, constant: -6),
            segment.bottomAnchor.constraint(equalTo: segContainer.bottomAnchor, constant: -6)
        ])

        // Card box styling
        cardView.backgroundColor = plum
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.15
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(equalToConstant: 180)
        ])

        // UPI container
        upiContainer.backgroundColor = .clear
        upiContainer.layer.cornerRadius = 8
        upiContainer.translatesAutoresizingMaskIntoConstraints = false

        // Totals
        let totalStack = UIStackView(arrangedSubviews: [totalTitle, amountLabel])
        totalStack.axis = .vertical
        totalStack.spacing = 4
        totalStack.alignment = .center

        // Main vertical layout
        // NOTE: spacer between card and actions reduced from 6 to 4, and we also add
        // a negative top constraint on the actions row to pull it up slightly under the card.
        let main = UIStackView(arrangedSubviews: [
            UIView(height: 8),
            segContainer,
            UIView(height: 16),
            cardView,
            upiContainer,
            UIView(height: 4),  // <-- reduced spacer
            cardActionsRow,
            UIView(height: 24),
            totalStack
        ])
        main.axis = .vertical
        main.spacing = 10
        main.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            main.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            main.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            main.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        // initially hide UPI
        upiContainer.isHidden = true

        // card actions row pin to card inner edges
        NSLayoutConstraint.activate([
            cardActionsRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            cardActionsRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])

        // Pull the actions row up slightly so the gap is visually small
        // Negative constant moves the actions a bit over the card's rounded bottom edge (like the design)
        let pullUp: CGFloat = -20
        let topConstraint = cardActionsRow.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: pullUp)
        topConstraint.priority = .defaultHigh
        topConstraint.isActive = true

        cardActionsRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
    }

    private func setupCard() {
        // clear any old subviews
        for v in cardView.subviews { v.removeFromSuperview() }

        // add views
        [cardHolderTitleLabel, cardHolderNameLabel,
         cardNumberTitleLabel, cardNumberLabel,
         brandDot1, brandDot2,
         expiresTitleLabel, expiresValueLabel,
         cvvTitleLabel, cvvValueLabel].forEach { cardView.addSubview($0) }

        // constraints
        NSLayoutConstraint.activate([
            cardHolderTitleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            cardHolderTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            cardHolderNameLabel.topAnchor.constraint(equalTo: cardHolderTitleLabel.bottomAnchor, constant: 4),
            cardHolderNameLabel.leadingAnchor.constraint(equalTo: cardHolderTitleLabel.leadingAnchor),

            cardNumberTitleLabel.topAnchor.constraint(equalTo: cardHolderNameLabel.bottomAnchor, constant: 12),
            cardNumberTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            cardNumberLabel.topAnchor.constraint(equalTo: cardNumberTitleLabel.bottomAnchor, constant: 6),
            cardNumberLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            cardNumberLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -100),

            brandDot2.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            brandDot2.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            brandDot2.widthAnchor.constraint(equalToConstant: 20),
            brandDot2.heightAnchor.constraint(equalToConstant: 20),

            brandDot1.centerYAnchor.constraint(equalTo: brandDot2.centerYAnchor),
            brandDot1.centerXAnchor.constraint(equalTo: brandDot2.centerXAnchor, constant: -12),
            brandDot1.widthAnchor.constraint(equalToConstant: 20),
            brandDot1.heightAnchor.constraint(equalToConstant: 20),

            expiresTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            expiresTitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -44),

            expiresValueLabel.topAnchor.constraint(equalTo: expiresTitleLabel.bottomAnchor, constant: 2),
            expiresValueLabel.leadingAnchor.constraint(equalTo: expiresTitleLabel.leadingAnchor),

            cvvTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            cvvTitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -44),

            cvvValueLabel.topAnchor.constraint(equalTo: cvvTitleLabel.bottomAnchor, constant: 2),
            cvvValueLabel.trailingAnchor.constraint(equalTo: cvvTitleLabel.trailingAnchor)
        ])
    }

    private func setupUPI() {
        upiContainer.addSubview(upiHintLabel)
        upiContainer.addSubview(upiTextField)
        upiContainer.addSubview(scanButton)

        NSLayoutConstraint.activate([
            upiHintLabel.topAnchor.constraint(equalTo: upiContainer.topAnchor, constant: 8),
            upiHintLabel.leadingAnchor.constraint(equalTo: upiContainer.leadingAnchor, constant: 8),
            upiHintLabel.trailingAnchor.constraint(equalTo: upiContainer.trailingAnchor, constant: -8),

            upiTextField.topAnchor.constraint(equalTo: upiHintLabel.bottomAnchor, constant: 12),
            upiTextField.leadingAnchor.constraint(equalTo: upiContainer.leadingAnchor),
            upiTextField.trailingAnchor.constraint(equalTo: upiContainer.trailingAnchor),
            upiTextField.heightAnchor.constraint(equalToConstant: 44),

            scanButton.topAnchor.constraint(equalTo: upiTextField.bottomAnchor, constant: 12),
            scanButton.centerXAnchor.constraint(equalTo: upiContainer.centerXAnchor),
            scanButton.heightAnchor.constraint(equalToConstant: 40),

            scanButton.bottomAnchor.constraint(equalTo: upiContainer.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Helpers to update UI from store
    private func refreshCardFromStore() {
        let c = CardStore.shared.currentCard
        applyCardToUI(c)
    }

    private func applyCardToUI(_ c: Card) {
        cardHolderNameLabel.text = c.holderName.uppercased()
        cardNumberLabel.text = c.number
        expiresValueLabel.text = c.expiry
        cvvValueLabel.text = (c.cvv.isEmpty ? "••••" : c.cvv)
    }
}

// Spacer helper
private extension UIView {
    convenience init(height: CGFloat) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
