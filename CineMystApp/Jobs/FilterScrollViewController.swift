import UIKit

class FilterScrollViewController: UIViewController {

    // MARK: - UI Elements
    let categoryTableView = UITableView()
    let optionsContainer = UIView()
    let headerLabel = UILabel()

    // Keep selection states
    var selectedRolePreference: String?
    var selectedPosition: String?
    var selectedProjectType: String?
    var selectedEarning: Float?
    
    // Callback to pass filters back
    var onFiltersApplied: ((String?, String?, String?, Float?) -> Void)?

    // MARK: Data
    enum FilterCategory: Int, CaseIterable {
        case rolePreference = 0
        case position
        case projectType
        case expectedEarning
    }

    let categories = [
        "Role preference",
        "Position",
        "Project Type",
        "Expected earning"
    ]

    let roleOptions = ["Acting", "Modeling", "Theatre", "Voice Over", "Anchoring"]
    let positionOptions = ["Lead Actor", "Supporting", "Junior Artist", "Child Artist"]
    let projectOptions = ["Web Series", "TV", "Film", "Short Film", "Ad/Commercial"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupLayout()

        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        categoryTableView.separatorStyle = .none

        loadCategory(.rolePreference)
    }

    // MARK: - UI SETUP
    func setupUI() {

        headerLabel.text = "Filter"
        headerLabel.font = .boldSystemFont(ofSize: 22)
        headerLabel.textColor = UIColor(red: 82/255, green: 7/255, blue: 65/255, alpha: 1)

        categoryTableView.backgroundColor = .white
        optionsContainer.backgroundColor = .white

        view.addSubview(headerLabel)
        view.addSubview(categoryTableView)
        view.addSubview(optionsContainer)
    }

    func setupLayout() {

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryTableView.translatesAutoresizingMaskIntoConstraints = false
        optionsContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            categoryTableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            categoryTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryTableView.widthAnchor.constraint(equalToConstant: 150),
            categoryTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            optionsContainer.leadingAnchor.constraint(equalTo: categoryTableView.trailingAnchor),
            optionsContainer.topAnchor.constraint(equalTo: categoryTableView.topAnchor),
            optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            optionsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - MAIN LOAD UI
    func loadCategory(_ category: FilterCategory) {
        optionsContainer.subviews.forEach { $0.removeFromSuperview() }

        switch category {
        case .rolePreference:
            showOptionList(title: "ROLE PREFERENCE", items: roleOptions)

        case .position:
            showOptionList(title: "POSITION", items: positionOptions)

        case .projectType:
            showOptionList(title: "PROJECT TYPE", items: projectOptions)

        case .expectedEarning:
            showEarningSlider()
        }

        addBottomButtons()
    }

    // MARK: - SHOW OPTION LIST
    func showOptionList(title: String, items: [String]) {

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        optionsContainer.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor, constant: -80) // Make room for buttons
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor.darkGray
        stack.addArrangedSubview(titleLabel)

        for item in items {
            let row = makeRadioRow(text: item)
            stack.addArrangedSubview(row)
        }
    }

    // MARK: - RADIO ROW
    func makeRadioRow(text: String) -> UIView {

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        let circle = UIView()
        circle.layer.cornerRadius = 10
        circle.layer.borderWidth = 2
        circle.layer.borderColor = UIColor.lightGray.cgColor
        circle.tag = 111 // for identification
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 20).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)

        row.addArrangedSubview(circle)
        row.addArrangedSubview(label)

        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleRadioTap(_:))))

        return row
    }

    @objc func handleRadioTap(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view as? UIStackView else { return }

        let label = row.arrangedSubviews[1] as! UILabel
        let selectedText = label.text
        
        // Store selection based on current category
        if roleOptions.contains(selectedText ?? "") {
            selectedRolePreference = selectedText
        } else if positionOptions.contains(selectedText ?? "") {
            selectedPosition = selectedText
        } else if projectOptions.contains(selectedText ?? "") {
            selectedProjectType = selectedText
        }

        clearAllCircles()

        if let circle = row.arrangedSubviews[0] as? UIView {
            circle.backgroundColor = UIColor(
                red: 82/255, green: 7/255, blue: 65/255, alpha: 1
            )
        }
    }

    func clearAllCircles() {
        for view in optionsContainer.subviews {
            for sub in view.subviews {
                if let stack = sub as? UIStackView {
                    for row in stack.arrangedSubviews {
                        if let rowStack = row as? UIStackView,
                           let circle = rowStack.arrangedSubviews.first as? UIView,
                           circle.tag == 111 {
                            circle.backgroundColor = .clear
                        }
                    }
                }
            }
        }
    }

    // MARK: - EARNING SLIDER
    func showEarningSlider() {

        let titleLabel = UILabel()
        titleLabel.text = "EXPECTED EARNING"
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = "₹ 0"
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100000
        slider.value = selectedEarning ?? 0
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tag = 999 // To access later

        optionsContainer.addSubview(titleLabel)
        optionsContainer.addSubview(valueLabel)
        optionsContainer.addSubview(slider)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: optionsContainer.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 32),
            
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -32),

            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 32),
            slider.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -32)
        ])
    }
    
    @objc func sliderChanged(_ slider: UISlider) {
        selectedEarning = slider.value
        // Update value label
        if let valueLabel = optionsContainer.subviews.first(where: { $0 is UILabel && $0 != optionsContainer.subviews.first }) as? UILabel {
            valueLabel.text = "₹ \(Int(slider.value))"
        }
    }

    // MARK: - BOTTOM BUTTONS
    func addBottomButtons() {

        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.black, for: .normal)
        clearButton.backgroundColor = UIColor(white: 0.9, alpha: 1)
        clearButton.layer.cornerRadius = 10
        clearButton.addTarget(self, action: #selector(clearFiltersTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Results", for: .normal)
        showButton.setTitleColor(.white, for: .normal)
        showButton.backgroundColor = UIColor(red: 82/255, green: 7/255, blue: 65/255, alpha: 1)
        showButton.layer.cornerRadius = 10
        showButton.translatesAutoresizingMaskIntoConstraints = false
        

        showButton.addTarget(self, action: #selector(showResultsTapped), for: .touchUpInside)


        optionsContainer.addSubview(clearButton)
        optionsContainer.addSubview(showButton)

        NSLayoutConstraint.activate([
            clearButton.bottomAnchor.constraint(equalTo: optionsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalTo: optionsContainer.widthAnchor, multiplier: 0.4),
            clearButton.heightAnchor.constraint(equalToConstant: 45),

            showButton.bottomAnchor.constraint(equalTo: optionsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            showButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -20),
            showButton.widthAnchor.constraint(equalTo: optionsContainer.widthAnchor, multiplier: 0.4),
            showButton.heightAnchor.constraint(equalToConstant: 45),
        ])
    }
    @objc func showResultsTapped() {
        // Call the callback with selected filters
        onFiltersApplied?(selectedRolePreference, selectedPosition, selectedProjectType, selectedEarning)
        
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc func clearFiltersTapped() {
        // Clear all selections
        selectedRolePreference = nil
        selectedPosition = nil
        selectedProjectType = nil
        selectedEarning = nil
        
        // Clear UI
        clearAllCircles()
        
        // Reset slider if visible
        if let slider = optionsContainer.viewWithTag(999) as? UISlider {
            slider.value = 0
            if let valueLabel = optionsContainer.subviews.compactMap({ $0 as? UILabel }).last {
                valueLabel.text = "₹ 0"
            }
        }
    }

}



// MARK: - TABLEVIEW
extension FilterScrollViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: "catCell")
        cell.selectionStyle = .none
        cell.textLabel?.text = categories[indexPath.row]
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let cat = FilterCategory(rawValue: indexPath.row) {
            loadCategory(cat)
        }
    }
}
