//
//  FilterViewController.swift
//  CineMystApp
//
//  Programmatic filter UI — bottom sheet style.
//  Left tab list + right content area. Compact height, aligned rows.
//  Returns chosen filters via completion closure.
//

import UIKit

/// Simple model representing chosen filters
struct MentorFilters {
    var skills: Set<String> = []
    var mentorRole: String? = nil
    var experience: String? = nil
    var priceMin: Int? = nil
    var priceMax: Int? = nil
}

final class FilterViewController: UIViewController {

    // MARK: Public
    /// called when "Show Results" tapped with current filters
    var onApplyFilters: ((MentorFilters) -> Void)?

    // MARK: UI components
    private let backdrop = UIView()
    private let sheet = UIView()
    private let leftMenu = UIStackView()
    private let contentContainer = UIView()
    private let bottomBar = UIView()

    private let clearButton = UIButton(type: .system)
    private let showResultsButton = UIButton(type: .system)

    private var selectedTab: Tab = .skills {
        didSet { updateContentForSelectedTab() }
    }

    // filter state
    private var filters = MentorFilters()

    // static lists (replace with dynamic lists if needed)
    private let skillsList = ["Acting", "Modeling", "Theatre", "Voice Over", "Anchoring"]
    private let mentorRoles = ["Senior Actor", "Director", "Freelancer", "Dubber"]
    private let experienceOptions = ["1 Year+", "2 Year+", "3 Year+"]

    // views for content
    private let skillsStack = UIStackView()
    private let mentorRoleStack = UIStackView()
    private let experienceStack = UIStackView()
    private let priceStack = UIStackView()

    // price inputs
    private let priceMinField: UITextField = {
        let t = UITextField()
        t.placeholder = "Min"
        t.keyboardType = .numberPad
        t.borderStyle = .roundedRect
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()
    private let priceMaxField: UITextField = {
        let t = UITextField()
        t.placeholder = "Max"
        t.keyboardType = .numberPad
        t.borderStyle = .roundedRect
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    // MARK: Tabs
    private enum Tab: Int {
        case skills = 0, mentorRole, experience, price

        var title: String {
            switch self {
            case .skills: return "Skills"
            case .mentorRole: return "Mentor Role"
            case .experience: return "Experience"
            case .price: return "Price"
            }
        }
    }

    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupHierarchy()
        setupConstraints()
        buildLeftMenu()
        buildContentViews()
        updateContentForSelectedTab()
        animateSheetUp()
    }

    private func setupAppearance() {
        view.backgroundColor = .clear
        modalPresentationStyle = .overFullScreen

        // backdrop dim
        backdrop.backgroundColor = UIColor(white: 0, alpha: 0.35)
        backdrop.alpha = 0.0
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTappedOutside))
        backdrop.addGestureRecognizer(tap)

        // sheet (rounded top corners only)
        sheet.backgroundColor = .systemBackground
        sheet.layer.cornerRadius = 16
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // top corners
        sheet.layer.masksToBounds = true
        sheet.translatesAutoresizingMaskIntoConstraints = false

        // left menu styling
        leftMenu.axis = .vertical
        leftMenu.alignment = .fill
        leftMenu.distribution = .fillEqually
        leftMenu.spacing = 0
        leftMenu.translatesAutoresizingMaskIntoConstraints = false

        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // bottom bar
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = UIColor.systemGray6

        // Clear button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.label, for: .normal)
        clearButton.layer.cornerRadius = 12
        clearButton.layer.borderWidth = 1
        clearButton.layer.borderColor = UIColor.systemGray4.cgColor
        clearButton.backgroundColor = .clear
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        // Show Results button - keep black filled (user asked neutral / not purple)
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.title = "Show Results"
        cfg.baseBackgroundColor = .black
        cfg.baseForegroundColor = .white
        showResultsButton.configuration = cfg
        showResultsButton.translatesAutoresizingMaskIntoConstraints = false
        showResultsButton.addTarget(self, action: #selector(showResultsTapped), for: .touchUpInside)
    }

    private func setupHierarchy() {
        view.addSubview(backdrop)
        view.addSubview(sheet)
        sheet.addSubview(leftMenu)
        sheet.addSubview(contentContainer)
        sheet.addSubview(bottomBar)

        bottomBar.addSubview(clearButton)
        bottomBar.addSubview(showResultsButton)

        // small drag indicator
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = UIColor.systemGray3
        indicator.layer.cornerRadius = 3
        sheet.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 8),
            indicator.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 60),
            indicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    private var sheetBottomConstraint: NSLayoutConstraint!
    private var sheetHeightConstraint: NSLayoutConstraint!

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Sheet: full width, anchored at bottom, with shorter height to be "compact"
        // We'll use 0.52 of the screen height so it's shorter (user asked to make it less tall)
        sheetBottomConstraint = sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 600) // start offscreen; animated later
        sheetBottomConstraint.isActive = true
        sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sheetHeightConstraint = sheet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.52)
        sheetHeightConstraint.isActive = true

        // left menu width fixed
        NSLayoutConstraint.activate([
            leftMenu.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
            leftMenu.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 24), // leave space for drag indicator
            leftMenu.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            leftMenu.widthAnchor.constraint(equalToConstant: 120)
        ])

        NSLayoutConstraint.activate([
            contentContainer.leadingAnchor.constraint(equalTo: leftMenu.trailingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 24),
            contentContainer.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])

        // bottom bar pinned to bottom of sheet and full width (this bleeds to screen edge because sheet spans full width)
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: sheet.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 84) // roomy for buttons and safe area
        ])

        // buttons inside bottomBar
        NSLayoutConstraint.activate([
            clearButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            clearButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 110),
            clearButton.heightAnchor.constraint(equalToConstant: 44),

            showResultsButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            showResultsButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            showResultsButton.widthAnchor.constraint(equalToConstant: 170),
            showResultsButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // Build left menu buttons
    private func buildLeftMenu() {
        for i in 0...3 {
            guard let t = Tab(rawValue: i) else { continue }
            let b = UIButton(type: .system)
            b.setTitle(t.title, for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            b.setTitleColor(.label, for: .normal)
            b.contentHorizontalAlignment = .left
            b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            b.tag = i
            b.backgroundColor = (t == selectedTab) ? UIColor.systemGray6 : .clear
            b.addTarget(self, action: #selector(leftMenuTapped(_:)), for: .touchUpInside)
            leftMenu.addArrangedSubview(b)
        }
    }

    private func rebuildLeftMenuSelection() {
        for case let b as UIButton in leftMenu.arrangedSubviews {
            b.backgroundColor = (b.tag == selectedTab.rawValue) ? UIColor.systemGray6 : .clear
            // keep font color default (no purple). Selected tab will appear on gray background.
            b.setTitleColor(.label, for: .normal)
        }
    }

    // Build each content view once
    private func buildContentViews() {
        // Skills stack: vertical list of checkbox rows
        skillsStack.axis = .vertical
        skillsStack.spacing = 14
        skillsStack.alignment = .fill
        skillsStack.translatesAutoresizingMaskIntoConstraints = false

        for s in skillsList {
            let row = makeCheckboxRow(title: s)
            skillsStack.addArrangedSubview(row)
        }

        // Mentor role: radio list (single select)
        mentorRoleStack.axis = .vertical
        mentorRoleStack.spacing = 14
        mentorRoleStack.alignment = .fill
        mentorRoleStack.translatesAutoresizingMaskIntoConstraints = false

        for r in mentorRoles {
            let row = makeRadioRow(title: r, group: .mentorRole)
            mentorRoleStack.addArrangedSubview(row)
        }

        // Experience: radio list
        experienceStack.axis = .vertical
        experienceStack.spacing = 14
        experienceStack.alignment = .fill
        experienceStack.translatesAutoresizingMaskIntoConstraints = false

        for e in experienceOptions {
            let row = makeRadioRow(title: e, group: .experience)
            experienceStack.addArrangedSubview(row)
        }

        // Price: two text fields horizontally
        priceStack.axis = .horizontal
        priceStack.spacing = 12
        priceStack.alignment = .center
        priceStack.translatesAutoresizingMaskIntoConstraints = false
        priceStack.addArrangedSubview(priceMinField)
        priceStack.addArrangedSubview(priceMaxField)
        priceMinField.widthAnchor.constraint(equalToConstant: 110).isActive = true
        priceMaxField.widthAnchor.constraint(equalToConstant: 110).isActive = true
    }

    // MARK: - Content swapping
    private func updateContentForSelectedTab() {
        rebuildLeftMenuSelection()

        // remove existing subviews
        contentContainer.subviews.forEach { $0.removeFromSuperview() }

        switch selectedTab {
        case .skills:
            contentContainer.addSubview(skillsStack)
            NSLayoutConstraint.activate([
                skillsStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 20),
                skillsStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 20),
                skillsStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -20)
            ])
        case .mentorRole:
            contentContainer.addSubview(mentorRoleStack)
            NSLayoutConstraint.activate([
                mentorRoleStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 20),
                mentorRoleStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 20),
                mentorRoleStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -20)
            ])
        case .experience:
            contentContainer.addSubview(experienceStack)
            NSLayoutConstraint.activate([
                experienceStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 20),
                experienceStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 20),
                experienceStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -20)
            ])
        case .price:
            contentContainer.addSubview(priceStack)
            NSLayoutConstraint.activate([
                priceStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 28),
                priceStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 20)
            ])
        }
    }

    // MARK: - Controls factory (aligned rows)

    /// Creates a checkbox row where the checkbox and label are vertically centered and aligned.
    private func makeCheckboxRow(title: String) -> UIControl {
        let container = UIControl()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Checkbox button (square)
        let checkbox = UIButton(type: .system)
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.tintColor = .label
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.widthAnchor.constraint(equalToConstant: 26).isActive = true
        checkbox.heightAnchor.constraint(equalToConstant: 26).isActive = true
        checkbox.addTarget(self, action: #selector(skillCheckboxTapped(_:)), for: .touchUpInside)
        checkbox.accessibilityLabel = title

        // Label
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        // Stack to keep them aligned
        let hStack = UIStackView(arrangedSubviews: [checkbox, label])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 16
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])

        return container
    }

    private enum RadioGroup { case mentorRole, experience }
    private func makeRadioRow(title: String, group: RadioGroup) -> UIControl {
        let container = UIControl()
        container.translatesAutoresizingMaskIntoConstraints = false

        let circle = UIButton(type: .system)
        circle.setImage(UIImage(systemName: "circle"), for: .normal)
        circle.tintColor = .label
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 26).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 26).isActive = true
        circle.tag = (group == .mentorRole) ? 0 : 1
        circle.accessibilityValue = title
        circle.addTarget(self, action: #selector(radioTapped(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView(arrangedSubviews: [circle, label])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 16
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func leftMenuTapped(_ sender: UIButton) {
        selectedTab = Tab(rawValue: sender.tag) ?? .skills
    }

    @objc private func skillCheckboxTapped(_ sender: UIButton) {
        guard let title = sender.accessibilityLabel else { return }
        if filters.skills.contains(title) {
            filters.skills.remove(title)
            sender.setImage(UIImage(systemName: "square"), for: .normal)
        } else {
            filters.skills.insert(title)
            sender.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        }
    }

    @objc private func radioTapped(_ sender: UIButton) {
        guard let title = sender.accessibilityValue else { return }
        if sender.tag == 0 {
            // mentorRole group: clear visuals first
            for case let ctrl as UIControl in mentorRoleStack.arrangedSubviews {
                if let b = ctrl.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UIButton {
                    b.setImage(UIImage(systemName: "circle"), for: .normal)
                }
            }
            sender.setImage(UIImage(systemName: "largecircle.fill.circle"), for: .normal)
            filters.mentorRole = title
        } else {
            // experience group
            for case let ctrl as UIControl in experienceStack.arrangedSubviews {
                if let b = ctrl.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UIButton {
                    b.setImage(UIImage(systemName: "circle"), for: .normal)
                }
            }
            sender.setImage(UIImage(systemName: "largecircle.fill.circle"), for: .normal)
            filters.experience = title
        }
    }

    @objc private func clearTapped() {
        filters = MentorFilters()

        // reset checkboxes
        for case let ctrl as UIControl in skillsStack.arrangedSubviews {
            if let b = ctrl.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UIButton {
                b.setImage(UIImage(systemName: "square"), for: .normal)
            }
        }
        // reset radios
        for case let ctrl as UIControl in mentorRoleStack.arrangedSubviews {
            if let b = ctrl.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UIButton {
                b.setImage(UIImage(systemName: "circle"), for: .normal)
            }
        }
        for case let ctrl as UIControl in experienceStack.arrangedSubviews {
            if let b = ctrl.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UIButton {
                b.setImage(UIImage(systemName: "circle"), for: .normal)
            }
        }

        priceMinField.text = ""
        priceMaxField.text = ""
    }

    @objc private func showResultsTapped() {
        // read price fields
        if let minText = priceMinField.text, let min = Int(minText) {
            filters.priceMin = min
        } else {
            filters.priceMin = nil
        }
        if let maxText = priceMaxField.text, let max = Int(maxText) {
            filters.priceMax = max
        } else {
            filters.priceMax = nil
        }

        dismissAnimated {
            self.onApplyFilters?(self.filters)
        }
    }

    // MARK: - Dismiss / animations
    @objc private func dismissTappedOutside() {
        dismissAnimated()
    }

    private func animateSheetUp() {
        // show backdrop
        UIView.animate(withDuration: 0.25) {
            self.backdrop.alpha = 1.0
        }

        // animate sheet from bottom into position
        self.sheetBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.86,
                       initialSpringVelocity: 0.9,
                       options: [.curveEaseOut],
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func dismissAnimated(completion: (() -> Void)? = nil) {
        // fade backdrop
        UIView.animate(withDuration: 0.22) {
            self.backdrop.alpha = 0.0
        }

        // slide sheet down
        self.sheetBottomConstraint.constant = 600
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.dismiss(animated: false, completion: completion)
        })
    }
}
