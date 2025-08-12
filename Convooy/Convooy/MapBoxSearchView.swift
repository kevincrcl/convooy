import SwiftUI
import MapboxMaps
import MapboxSearch
import UIKit

struct MapBoxSearchView: UIViewControllerRepresentable {
    @ObservedObject var searchService = SearchService.shared
    var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PlaceAutocompleteViewController {
        let searchController = PlaceAutocompleteViewController()
        searchController.delegate = context.coordinator
        return searchController
    }
    
    func updateUIViewController(_ uiViewController: PlaceAutocompleteViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PlaceAutocompleteViewControllerDelegate {
        var parent: MapBoxSearchView
        
        init(_ parent: MapBoxSearchView) {
            self.parent = parent
        }
        
        @MainActor
        func placeAutocompleteViewController(_ viewController: PlaceAutocompleteViewController, didSelect result: PlaceAutocomplete.Result) {
            // Handle the selected result
            let searchResult = SearchResult(
                id: result.mapboxId ?? UUID().uuidString,
                name: result.name,
                coordinate: result.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                address: result.address?.formattedAddress(style: .medium) ?? ""
            )
            
            parent.searchService.setSelectedDestination(searchResult)
            
            // Dismiss the search view
            parent.isPresented = false
        }
    }
}

// Custom search view controller using PlaceAutocomplete
class PlaceAutocompleteViewController: UIViewController {
    private lazy var placeAutocomplete = PlaceAutocomplete()
    private var cachedSuggestions: [PlaceAutocomplete.Suggestion] = []
    private let locationManager = CLLocationManager()
    private var searchTimer: Timer?
    private var currentSearchTask: Task<Void, Never>?
    
    weak var delegate: PlaceAutocompleteViewControllerDelegate?
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search destination..."
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestion-cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
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
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
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
                        case .failure(let error):
                            // Only show error if it's not a cancellation error
                            let errorMessage = error.localizedDescription
                            if !errorMessage.contains("cancelled") && !errorMessage.contains("canceled") {
                                print("Search error: \(error)")
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
extension PlaceAutocompleteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Cancel any existing timer
        searchTimer?.invalidate()
        
        if searchText.isEmpty {
            // Cancel any ongoing search
            currentSearchTask?.cancel()
            cachedSuggestions = []
            tableView.reloadData()
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
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension PlaceAutocompleteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cachedSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion-cell", for: indexPath)
        let suggestion = cachedSuggestions[indexPath.row]
        
        cell.textLabel?.text = suggestion.name
        cell.detailTextLabel?.text = suggestion.description
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let suggestion = cachedSuggestions[indexPath.row]
        
        // Show destination details before selection
        showDestinationDetails(suggestion)
    }
    
    private func showDestinationDetails(_ suggestion: PlaceAutocomplete.Suggestion) {
        let alert = UIAlertController(title: suggestion.name, message: suggestion.description, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Select Destination", style: .default) { [weak self] _ in
            self?.selectDestination(suggestion)
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
    
    private func selectDestination(_ suggestion: PlaceAutocomplete.Suggestion) {
        // Show loading state
        let suggestionIndex = cachedSuggestions.enumerated().first { $0.element.name == suggestion.name }?.offset ?? 0
        let indexPath = IndexPath(row: suggestionIndex, section: 0)
        let loadingCell = tableView.cellForRow(at: indexPath)
        loadingCell?.textLabel?.text = "Loading..."
        loadingCell?.isUserInteractionEnabled = false
        
        placeAutocomplete.select(suggestion: suggestion) { [weak self] result in
            DispatchQueue.main.async {
                // Restore original cell state
                loadingCell?.textLabel?.text = suggestion.name
                loadingCell?.isUserInteractionEnabled = true
                
                switch result {
                case .success(let suggestionResult):
                    self?.delegate?.placeAutocompleteViewController(self!, didSelect: suggestionResult)
                case .failure(let error):
                    print("Suggestion selection error: \(error)")
                    self?.showSearchError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Delegate Protocol
protocol PlaceAutocompleteViewControllerDelegate: AnyObject {
    func placeAutocompleteViewController(_ viewController: PlaceAutocompleteViewController, didSelect result: PlaceAutocomplete.Result)
}

// MARK: - SearchResult Compatibility
struct SearchResult {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
}

struct MapBoxSearchViewContainer: View {
    @StateObject private var searchService = SearchService.shared
    @ObservedObject private var navigationService = NavigationService.shared
    @ObservedObject private var stopService = StopManagementService.shared
    @State private var isSearchPresented = false
    @State private var isStopSelectionPresented = false
    @State private var showDestinationSelected = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map View
            MapBoxMapView()
                .ignoresSafeArea()
            
            // Loading Overlay
            if navigationService.isLoading {
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Calculating route...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black)
                        .cornerRadius(16)
                    )
            }
            
            // Search Toggle Button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isSearchPresented = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                            Text("Search Destination")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.6)) // Convooy purple
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 60) // Account for status bar
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                // Navigation Button (appears when destination is selected)
                if searchService.selectedDestination != nil {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Destination Info Card
                            if let destination = searchService.selectedDestination {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Destination")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))
                                    
                                    Text(destination.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    
                                    if let address = destination.address {
                                        Text(address)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color.white.opacity(0.7))
                                            .lineLimit(2)
                                    }
                                    
                                    // Route Summary
                                    if let routeSummary = navigationService.getRouteSummary() {
                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                        
                                        Text(routeSummary)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color.white.opacity(0.9))
                                            .lineLimit(3)
                                    }
                                    
                                    // Stops List
                                    if !stopService.stops.isEmpty {
                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                        
                                        Text("Stops (\(stopService.stops.count))")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.white.opacity(0.8))
                                        
                                        ForEach(Array(stopService.stops.enumerated()), id: \.element.id) { index, stop in
                                            HStack {
                                                // Stop number
                                                Text("\(index + 1)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 16, height: 16)
                                                    .background(Color.blue)
                                                    .clipShape(Circle())
                                                
                                                // Stop name
                                                Text(stop.name)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Color.white.opacity(0.9))
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                
                                                // Remove stop button
                                                Button(action: {
                                                    stopService.removeStop(at: index)
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(16)
                                .frame(maxWidth: 250, alignment: .leading)
                                
                                // Error Display
                                if let error = navigationService.routeError {
                                    VStack(spacing: 8) {
                                        Text(error)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(12)
                                            .frame(maxWidth: 250, alignment: .leading)
                                        
                                        Button(action: {
                                            navigationService.clearRouteError()
                                        }) {
                                            Text("Retry")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.red.opacity(0.8))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            
                            // Stop Management Buttons (only show when route exists)
                            if navigationService.currentRoute != nil {
                                HStack(spacing: 8) {
                                    // Add Stop Button
                                    Button(action: {
                                        isStopSelectionPresented = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.white)
                                            Text("Add Stop")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(20)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    
                                    // Clear All Stops Button (only show when there are stops)
                                    if !stopService.stops.isEmpty {
                                        Button(action: {
                                            stopService.clearAllStops()
                                        }) {
                                            HStack {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.white)
                                                Text("Clear Stops")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(20)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                            
                            // Clear Destination Button
                            Button(action: {
                                searchService.clearSelectedDestination()
                                stopService.clearAllStops() // Also clear stops when clearing destination
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                    Text("Clear")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.7))
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            
                            // Start Navigation Button
                            Button(action: {
                                if let destination = searchService.selectedDestination {
                                    Task {
                                        await navigationService.startNavigation(
                                            to: destination.coordinate,
                                            from: LocationManager.shared.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                                        )
                                    }
                                }
                            }) {
                                HStack {
                                    if navigationService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(navigationService.isLoading ? "Calculating..." : "Start Navigation")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(navigationService.isLoading ? Color.gray : Color(red: 1.0, green: 0.4, blue: 0.2))
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            .disabled(navigationService.isLoading || !CLLocationCoordinate2DIsValid(searchService.selectedDestination?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)))
                            
                            // Location Status Indicator
                            if LocationManager.shared.currentLocation == nil {
                                Button(action: {
                                    LocationManager.shared.requestLocationPermission()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.slash")
                                            .font(.system(size: 10))
                                        Text("Tap to enable location access")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow.opacity(0.3))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.bottom, 100) // Account for safe area
                        .padding(.trailing, 20)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isSearchPresented) {
            // Full-screen search experience
            ZStack {
                MapBoxSearchView(isPresented: true)
                    .ignoresSafeArea()
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            isSearchPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                    }
                    
                    Spacer()
                }
            }
            .onReceive(searchService.$selectedDestination) { destination in
                if destination != nil {
                    // Close search when destination is selected
                    isSearchPresented = false
                    showDestinationSelected = true // Show success message
                }
            }
        }
        .sheet(isPresented: $isStopSelectionPresented) {
            // Stop selection view
            StopSelectionView(isPresented: true) {
                isStopSelectionPresented = false
            }
        }
    }

}
