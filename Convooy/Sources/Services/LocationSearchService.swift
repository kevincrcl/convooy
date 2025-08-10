import Foundation
import CoreLocation
import Combine

class LocationSearchService: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
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
        
        // This will be replaced with MapBox search
        // For now, just simulate search results
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSearching = false
            self.searchResults = [
                SearchResult(name: "\(query) Location 1", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
                SearchResult(name: "\(query) Location 2", coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094))
            ]
        }
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
} 