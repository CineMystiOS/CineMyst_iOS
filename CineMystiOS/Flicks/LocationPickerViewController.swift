//
//  LocationPickerViewController.swift
//  CineMystApp
//
//  Searchable location picker using MKLocalSearch
//

import UIKit
import MapKit

protocol LocationPickerDelegate: AnyObject {
    func didSelectLocation(_ locationName: String)
}

class LocationPickerViewController: UIViewController {
    
    weak var delegate: LocationPickerDelegate?
    private var searchResults: [MKMapItem] = []
    
    // MARK: - UI Elements
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for a location..."
        sb.searchBarStyle = .minimal
        sb.backgroundColor = .systemBackground
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Select a location"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
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
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension LocationPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let item = searchResults[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = item.name
        config.secondaryText = item.placemark.title // Shows address
        config.image = UIImage(systemName: "mappin.and.ellipse")
        config.imageProperties.tintColor = .systemRed
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = searchResults[indexPath.row]
        delegate?.didSelectLocation(item.name ?? "Unknown Location")
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension LocationPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count < 2 {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response else { return }
            self?.searchResults = response.mapItems
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}
