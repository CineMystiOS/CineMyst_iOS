import UIKit

class OptionsListController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()
    var options: [String] = []

    private var selectedIndex: IndexPath? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(RadioButtonCell.self, forCellReuseIdentifier: "RadioButtonCell")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "RadioButtonCell", for: indexPath) as! RadioButtonCell
        cell.optionLabel.text = options[indexPath.row]

        // Set selected state based on selectedIndex
        let isSelected = (indexPath == selectedIndex)
        cell.setSelectedState(isSelected)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        selectedIndex = indexPath  // update model

        tableView.reloadData()     // refresh UI
    }
}

