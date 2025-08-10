import Foundation
import CoreLocation

class RouteService: NSObject, ObservableObject {
    @Published var route: Route?
    @Published var selectedDestination: SearchResult?
    @Published var isCalculatingRoute = false
    @Published var routeError: String?

    func calculateRoute(from startLocation: CLLocation, to destination: SearchResult) {
        selectedDestination = destination
        isCalculatingRoute = true
        routeError = nil

        // This will be replaced with MapBox routing
        // For now, just simulate route calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isCalculatingRoute = false
            
            // Create a mock route
            let distance = startLocation.distance(from: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude))
            let estimatedTime = distance / 500.0 // Rough estimate: 500 meters per minute
            
            self.route = Route(
                distance: distance,
                expectedTravelTime: estimatedTime * 60, // Convert to seconds
                polyline: [] // Will be replaced with actual route coordinates
            )
        }
    }

    func clearRoute() {
        route = nil
        selectedDestination = nil
        routeError = nil
    }
}

struct Route {
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let polyline: [CLLocationCoordinate2D] // Will contain route coordinates
} 