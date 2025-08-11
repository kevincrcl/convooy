import SwiftUI
import MapboxMaps
import MapboxSearch
import UIKit

struct MapBoxSearchView: UIViewControllerRepresentable {
    @ObservedObject var searchService = SearchService.shared
    let isPresented: Bool
    
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
        
        func placeAutocompleteViewController(_ viewController: PlaceAutocompleteViewController, didSelect result: PlaceAutocomplete.Result) {
            // Convert PlaceAutocomplete.Result to SearchResult for compatibility
            let searchResult = SearchResult(
                id: result.mapboxId ?? UUID().uuidString,
                name: result.name,
                coordinate: result.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                address: result.description
            )
            parent.searchService.setSelectedDestination(searchResult)
        }
    }
}

// Custom search view controller using PlaceAutocomplete
class PlaceAutocompleteViewController: UIViewController {
    private lazy var placeAutocomplete = PlaceAutocomplete()
    private var cachedSuggestions: [PlaceAutocomplete.Suggestion] = []
    private let locationManager = CLLocationManager()
    
    weak var delegate: PlaceAutocompleteViewControllerDelegate?
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search destination..."
        searchBar.delegate = self
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
        placeAutocomplete.suggestions(
            for: query,
            proximity: locationManager.location?.coordinate,
            filterBy: .init(types: [.POI], navigationProfile: .driving)
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let suggestions):
                    self.cachedSuggestions = suggestions
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Search error: \(error)")
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension PlaceAutocompleteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            cachedSuggestions = []
            tableView.reloadData()
        } else {
            performSearch(query: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
        placeAutocomplete.select(suggestion: suggestion) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let suggestionResult):
                    self?.delegate?.placeAutocompleteViewController(self!, didSelect: suggestionResult)
                case .failure(let error):
                    print("Suggestion selection error: \(error)")
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
    @State private var isSearchPresented = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map View
            MapBoxMapView()
                .ignoresSafeArea()
            
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
                }
            }
        }
    }
}
