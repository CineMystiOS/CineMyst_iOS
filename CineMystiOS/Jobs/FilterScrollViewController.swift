import UIKit

class FilterScrollViewController: UIViewController {
    
    // MARK: - Selection States
    var selectedRolePreference: String?
    var selectedPosition: String?
    var selectedProjectType: String?
    var selectedLocation: String?
    var selectedEarning: Float?
    
    // Callback to pass filters back
    var onFiltersApplied: ((String?, String?, String?, Float?, String?) -> Void)?
    
    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let roleOptions = ["Acting", "Modeling", "Theatre", "Voice Over", "Anchoring"]
    private let positionOptions = ["Lead Actor", "Supporting", "Junior Artist", "Child Artist"]
    private let projectOptions = ["Web Series", "TV", "Film", "Short Film", "Ad/Commercial"]
    private let locationOptions = ["Bhubaneswar", "Mumbai", "Kolkata", "Delhi", "Chennai", "Hyderabad", "Bangalore"]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
    }
    
    private func setupNavigationBar() {
        title = "Filter"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        // Standard iOS plum/brand color if desired, otherwise default tint
        navigationItem.leftBarButtonItem?.tintColor = .systemRed
        navigationItem.rightBarButtonItem?.tintColor = CineMystTheme.brandPlum
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FilterCell")
        tableView.register(EarningSliderCell.self, forCellReuseIdentifier: "EarningCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func resetTapped() {
        selectedRolePreference = nil
        selectedPosition = nil
        selectedProjectType = nil
        selectedLocation = nil
        selectedEarning = 0
        tableView.reloadData()
    }
    
    @objc private func doneTapped() {
        onFiltersApplied?(selectedRolePreference, selectedPosition, selectedProjectType, selectedEarning, selectedLocation)
        dismiss(animated: true)
    }
    
    fileprivate func showSelectionSheet(title: String, options: [String], current: String?, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for option in options {
            let action = UIAlertAction(title: option, style: .default) { _ in
                completion(option)
            }
            // Add checkmark if it's the current selection (Alert controller doesn't support checkmarks easily, but we can append text)
            if option == current {
                action.setValue(true, forKey: "checked") // Some internal hacks or just plain text
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension FilterScrollViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // 1: Main Filters, 2: Earning
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 4 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Categories" : "Expected Earning"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "FilterCell")
            cell.accessoryType = .disclosureIndicator
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Role preference"
                cell.detailTextLabel?.text = selectedRolePreference ?? "Any"
            case 1:
                cell.textLabel?.text = "Position"
                cell.detailTextLabel?.text = selectedPosition ?? "Any"
            case 2:
                cell.textLabel?.text = "Project Type"
                cell.detailTextLabel?.text = selectedProjectType ?? "Any"
            case 3:
                cell.textLabel?.text = "Location"
                cell.detailTextLabel?.text = selectedLocation ?? "Any"
            default: break
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EarningCell", for: indexPath) as! EarningSliderCell
            cell.configure(value: selectedEarning ?? 0) { [weak self] newValue in
                self?.selectedEarning = newValue
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 { return }
        
        switch indexPath.row {
        case 0:
            showSelectionSheet(title: "Role Preference", options: roleOptions, current: selectedRolePreference) { val in
                self.selectedRolePreference = val; self.tableView.reloadData()
            }
        case 1:
            showSelectionSheet(title: "Position", options: positionOptions, current: selectedPosition) { val in
                self.selectedPosition = val; self.tableView.reloadData()
            }
        case 2:
            showSelectionSheet(title: "Project Type", options: projectOptions, current: selectedProjectType) { val in
                self.selectedProjectType = val; self.tableView.reloadData()
            }
        case 3:
            showSelectionSheet(title: "Location", options: locationOptions, current: selectedLocation) { val in
                self.selectedLocation = val; self.tableView.reloadData()
            }
        default: break
        }
    }
}

// MARK: - Earning Slider Cell
class EarningSliderCell: UITableViewCell {
    static let reuseId = "EarningCell"
    private var onValueChange: ((Float) -> Void)?
    
    private let slider = UISlider()
    private let valueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = CineMystTheme.brandPlum
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(valueLabel)
        
        slider.minimumValue = 0
        slider.maximumValue = 100000
        slider.tintColor = CineMystTheme.brandPlum
        slider.addTarget(self, action: #selector(sliderMoved), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            slider.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(value: Float, onUpdate: @escaping (Float) -> Void) {
        slider.value = value
        valueLabel.text = "₹ \(Int(value))"
        self.onValueChange = onUpdate
    }
    
    @objc private func sliderMoved() {
        valueLabel.text = "₹ \(Int(slider.value))"
        onValueChange?(slider.value)
    }
}
