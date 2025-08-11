import Foundation
import MapboxMaps
import MapboxSearch
import MapboxSearchUI
import CoreLocation

@MainActor
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
        
        // Automatically preview the route when destination is selected
        if let currentLocation = LocationManager.shared.currentLocation {
            Task {
                await NavigationService.shared.previewRoute(
                    to: destination.coordinate,
                    from: currentLocation.coordinate
                )
            }
        } else {
            print("Current location not available for route preview")
            // Request location permission if not already granted
            LocationManager.shared.requestLocationPermission()
        }
    }
    
    func clearSelectedDestination() {
        selectedDestination = nil
        NavigationService.shared.clearRoute()
        print("Destination cleared")
    }
    
    private func startNavigationToDestination(_ destination: SearchResult) {
        // Get current location from LocationManager
        if let currentLocation = LocationManager.shared.currentLocation {
            Task {
                await NavigationService.shared.startNavigation(
                    to: destination.coordinate,
                    from: currentLocation.coordinate
                )
            }
        } else {
            print("Current location not available for navigation")
            // Request location permission if not already granted
            LocationManager.shared.requestLocationPermission()
        }
    }
}
