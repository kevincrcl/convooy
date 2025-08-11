import Foundation
import MapboxMaps
import MapboxSearch
import MapboxSearchUI
import CoreLocation

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
        
        // Trigger navigation to destination
        startNavigationToDestination(destination)
    }
    
    private func startNavigationToDestination(_ destination: SearchResult) {
        // Get current location from LocationManager
        if let currentLocation = LocationManager.shared.currentLocation {
            NavigationService.shared.startNavigation(
                to: destination.coordinate,
                from: currentLocation.coordinate
            )
        } else {
            print("Current location not available for navigation")
        }
    }
}
