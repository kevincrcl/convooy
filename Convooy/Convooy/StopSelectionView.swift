import SwiftUI
import MapboxMaps
import MapboxSearch
import UIKit
import CoreLocation

struct StopSelectionView: UIViewControllerRepresentable {
    @ObservedObject var stopService = StopManagementService.shared
    var isPresented: Bool
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> StopAutocompleteViewController {
        let searchController = StopAutocompleteViewController()
        searchController.delegate = context.coordinator
        return searchController
    }
    
    func updateUIViewController(_ uiViewController: StopAutocompleteViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, StopAutocompleteViewControllerDelegate {
        var parent: StopSelectionView
        
        init(_ parent: StopSelectionView) {
            self.parent = parent
        }
        
        @MainActor
        func stopAutocompleteViewController(_ viewController: StopAutocompleteViewController, didSelect result: PlaceAutocomplete.Result) {
            // Handle the selected result
            let stop = Stop(
                name: result.name,
                coordinate: result.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                address: result.address?.formattedAddress(style: .medium)
            )
            
            // Check if this location is already a stop
            if !parent.stopService.isLocationAlreadyAStop(stop.coordinate) {
                parent.stopService.addStop(stop)
                print("Added stop: \(stop.name)")
            } else {
                print("Location is already a stop, skipping")
                // Could show an alert here if needed
            }
            
            // Dismiss the search view
            parent.onDismiss()
        }
        
        func stopAutocompleteViewControllerDidCancel(_ viewController: StopAutocompleteViewController) {
            parent.onDismiss()
        }
    }
}

// Custom stop search view controller using PlaceAutocomplete
class StopAutocompleteViewController: UIViewController {
    private lazy var placeAutocomplete = PlaceAutocomplete()
    private var cachedSuggestions: [PlaceAutocomplete.Suggestion] = []
    private let locationManager = CLLocationManager()
    private var searchTimer: Timer?
    private var currentSearchTask: Task<Void, Never>?
    
    weak var delegate: StopAutocompleteViewControllerDelegate?
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        let navItem = UINavigationItem(title: "Add Stop")
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navItem.leftBarButtonItem = cancelButton
        
        navBar.setItems([navItem], animated: false)
        return navBar
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for a stop along your route..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "stop-suggestion-cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Search for points of interest to add as stops on your route"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
    }
    
    deinit {
        // Clean up timer and search task when view controller is deallocated
        searchTimer?.invalidate()
        currentSearchTask?.cancel()
    }
    
    @objc private func cancelTapped() {
        delegate?.stopAutocompleteViewControllerDidCancel(self)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(navigationBar)
        view.addSubview(searchBar)
        view.addSubview(instructionLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // Navigation bar
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        searchBar.becomeFirstResponder()
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func performSearch(query: String) {
        // Cancel any existing search task
        currentSearchTask?.cancel()
        
        // Create a new search task
        currentSearchTask = Task { [weak self] in
            guard let self = self, !Task.isCancelled else { return }
            
            await withCheckedContinuation { continuation in
                placeAutocomplete.suggestions(
                    for: query,
                    proximity: locationManager.location?.coordinate,
                    filterBy: .init(types: [.POI], navigationProfile: .driving)
                ) { result in
                    continuation.resume()
                    
                    Task { @MainActor [weak self] in
                        guard let self = self, !Task.isCancelled else { return }
                        
                        switch result {
                        case .success(let suggestions):
                            self.cachedSuggestions = suggestions
                            self.tableView.reloadData()
                            
                            // Show/hide instruction label based on results
                            self.instructionLabel.isHidden = !suggestions.isEmpty
                            
                        case .failure(let error):
                            // Only show error if it's not a cancellation error
                            let errorMessage = error.localizedDescription
                            if !errorMessage.contains("cancelled") && !errorMessage.contains("canceled") {
                                print("Stop search error: \(error)")
                                self.showSearchError(errorMessage)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showSearchError(_ message: String) {
        let alert = UIAlertController(title: "Search Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            // Retry the last search
            if let lastQuery = self.searchBar.text, !lastQuery.isEmpty {
                self.performSearch(query: lastQuery)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension StopAutocompleteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Cancel any existing timer
        searchTimer?.invalidate()
        
        if searchText.isEmpty {
            // Cancel any ongoing search
            currentSearchTask?.cancel()
            cachedSuggestions = []
            tableView.reloadData()
            instructionLabel.isHidden = false
        } else {
            // Debounce the search with a 0.3 second delay
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.performSearch(query: searchText)
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // Cancel timer and perform immediate search if there's text
        searchTimer?.invalidate()
        if let searchText = searchBar.text, !searchText.isEmpty {
            performSearch(query: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Clean up timer and search task
        searchTimer?.invalidate()
        currentSearchTask?.cancel()
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        cachedSuggestions = []
        tableView.reloadData()
        instructionLabel.isHidden = false
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension StopAutocompleteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cachedSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stop-suggestion-cell", for: indexPath)
        let suggestion = cachedSuggestions[indexPath.row]
        
        cell.textLabel?.text = suggestion.name
        cell.detailTextLabel?.text = suggestion.description
        cell.accessoryType = .disclosureIndicator
        
        // Add a stop icon
        let stopIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        stopIcon.tintColor = .systemBlue
        cell.accessoryView = stopIcon
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let suggestion = cachedSuggestions[indexPath.row]
        
        // Show stop details before selection
        showStopDetails(suggestion)
    }
    
    private func showStopDetails(_ suggestion: PlaceAutocomplete.Suggestion) {
        let alert = UIAlertController(title: suggestion.name, message: suggestion.description, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Add as Stop", style: .default) { [weak self] _ in
            self?.selectStop(suggestion)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure popover for iPad
        if let popover = alert.popoverPresentationController {
            // Find the index of the suggestion in cached suggestions
            let suggestionIndex = cachedSuggestions.enumerated().first { $0.element.name == suggestion.name }?.offset ?? 0
            let indexPath = IndexPath(row: suggestionIndex, section: 0)
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(alert, animated: true)
    }
    
    private func selectStop(_ suggestion: PlaceAutocomplete.Suggestion) {
        // Show loading state
        let suggestionIndex = cachedSuggestions.enumerated().first { $0.element.name == suggestion.name }?.offset ?? 0
        let indexPath = IndexPath(row: suggestionIndex, section: 0)
        let loadingCell = tableView.cellForRow(at: indexPath)
        loadingCell?.textLabel?.text = "Adding stop..."
        loadingCell?.isUserInteractionEnabled = false
        
        placeAutocomplete.select(suggestion: suggestion) { [weak self] result in
            DispatchQueue.main.async {
                // Restore original cell state
                loadingCell?.textLabel?.text = suggestion.name
                loadingCell?.isUserInteractionEnabled = true
                
                switch result {
                case .success(let suggestionResult):
                    self?.delegate?.stopAutocompleteViewController(self!, didSelect: suggestionResult)
                case .failure(let error):
                    print("Stop suggestion selection error: \(error)")
                    self?.showSearchError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Delegate Protocol
protocol StopAutocompleteViewControllerDelegate: AnyObject {
    func stopAutocompleteViewController(_ viewController: StopAutocompleteViewController, didSelect result: PlaceAutocomplete.Result)
    func stopAutocompleteViewControllerDidCancel(_ viewController: StopAutocompleteViewController)
}
