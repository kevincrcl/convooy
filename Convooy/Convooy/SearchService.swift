import Foundation
import MapboxMaps
import MapboxSearch
import MapboxSearchUI

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var selectedDestination: SearchResult?
    
    private init() {
        // No initialization needed for prebuilt UI
    }
    
    func setSelectedDestination(_ destination: SearchResult) {
        selectedDestination = destination
        print("Selected destination: \(destination.name)")
        let coordinate = destination.coordinate
        print("Location: \(coordinate.latitude), \(coordinate.longitude)")
    }
}
