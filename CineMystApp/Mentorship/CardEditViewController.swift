// CardEditViewController.swift
// Presents from bottom as a sheet (grabber). Calls onSave when saved.

import UIKit

final class CardEditViewController: UIViewController {

    // When user taps Update/Add -> this closure is called with new Card
    var onSave: ((Card) -> Void)?

    // If nil -> add mode. If non-nil -> edit mode.
    private var card: Card?

    // UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Cardholder Name"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let numberField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Card Number"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let expiryField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Expiry Date (MM/YY)"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let cvvField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "CVV"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let clearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Clear", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let saveButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Update"
        c.cornerStyle = .capsule
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }()

    init(card: Card?) {
        self.card = card
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        titleLabel.text = (card == nil) ? "Add Card" : "Edit Card Info"
        if card == nil {
            saveButton.configuration?.title = "Add"
        } else {
            saveButton.configuration?.title = "Update"
        }

        // Compose UI
        let expiryRow = UIStackView(arrangedSubviews: [expiryField, cvvField])
        expiryRow.axis = .horizontal
        expiryRow.spacing = 12
        expiryRow.distribution = .fillProportionally

        let buttonsRow = UIStackView(arrangedSubviews: [clearButton, saveButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.alignment = .center

        // Make Clear small fixed width
        clearButton.widthAnchor.constraint(equalToConstant: 96).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            nameField,
            numberField,
            expiryRow,
            UIView(), // flexible spacer
            buttonsRow
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            expiryField.heightAnchor.constraint(equalToConstant: 44),
            cvvField.heightAnchor.constraint(equalToConstant: 44),
            nameField.heightAnchor.constraint(equalToConstant: 44),
            numberField.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Prefill edit values if provided
        if let c = card {
            nameField.text = c.holderName
            numberField.text = c.number
            expiryField.text = c.expiry
            cvvField.text = (c.cvv == "••••" ? "" : c.cvv)
        }

        // Actions
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // Sheet presentation
        if let sheet = sheetPresentationController {
            sheet.prefersGrabberVisible = true
            if #available(iOS 16.0, *) {
                sheet.detents = [.medium(), .large()]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.preferredCornerRadius = 14
        }
    }

    @objc private func clearTapped() {
        nameField.text = ""
        numberField.text = ""
        expiryField.text = ""
        cvvField.text = ""
    }

    @objc private func saveTapped() {
        // basic validation
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty,
              let number = numberField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !number.isEmpty,
              let expiry = expiryField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !expiry.isEmpty
        else {
            let a = UIAlertController(title: "Missing fields", message: "Please provide name, number and expiry", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        let cvvText = (cvvField.text?.isEmpty ?? true) ? "••••" : (cvvField.text ?? "")

        var newCard = card ?? Card(holderName: name, number: number, expiry: expiry, cvv: cvvText)
        newCard.holderName = name
        newCard.number = number
        newCard.expiry = expiry
        newCard.cvv = cvvText

        // persist in store
        CardStore.shared.update(newCard)

        // callback
        onSave?(newCard)

        dismiss(animated: true, completion: nil)
    }
}
