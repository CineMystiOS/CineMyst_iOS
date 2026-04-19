import UIKit
import MapKit

class JobLocationPickerViewController: UIViewController {
    
    var onLocationSelected: ((String) -> Void)?
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let searchCompleter = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCompleter()
    }
    
    private func setupUI() {
        title = "Search Location"
        view.backgroundColor = .white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        
        searchBar.placeholder = "Enter city or area..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        searchBar.becomeFirstResponder()
    }
    
    private func setupCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension JobLocationPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            results = []
            tableView.reloadData()
        } else {
            searchCompleter.queryFragment = searchText
        }
    }
}

extension JobLocationPickerViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { result in
            // Filter to address types (likely cities/localities)
            let subtitle = result.subtitle.lowercased()
            return !subtitle.isEmpty && !result.title.contains("Airport") && !result.title.contains("Station")
        }
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Location search error: \(error)")
    }
}

extension JobLocationPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "LocationCell")
        let result = results[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = .gray
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = results[indexPath.row]
        onLocationSelected?(selection.title)
        dismiss(animated: true)
    }
}
