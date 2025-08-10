import Foundation
import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    
    private var searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: Timer?
    
    override init() {
        super.init()
        searchCompleter.resultTypes = .pointOfInterest
        searchCompleter.delegate = self
        
        // Set up debounced search
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    print("Search error: \(error)")
                    return
                }
                
                self?.searchResults = response?.mapItems ?? []
            }
        }
    }
    
    // This method is no longer needed since we use debounced search
    func searchLocations(query: String) {
        // Kept for backward compatibility if needed
        performSearch(query: query)
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // This could be used for real-time suggestions if needed
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error)")
    }
} 