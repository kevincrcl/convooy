import Foundation
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import CoreLocation

class NavigationService: ObservableObject {
    static let shared = NavigationService()
    
    @Published var isCalculatingRoute = false
    @Published var routeError: String?
    @Published var isNavigating = false
    @Published var currentRoute: Route?
    
    private init() {
        // Navigation SDK will use the MBXAccessToken from Info.plist
    }
    
    func startNavigation(to destination: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) {
        isCalculatingRoute = true
        routeError = nil
        
        print("Starting navigation from \(origin) to \(destination)")
        
        // Create a route using Navigation SDK v3
        // First, let's try to create a simple route and display it on the map
        createAndDisplayRoute(from: origin, to: destination)
    }
    
    private func createAndDisplayRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        // For now, let's create a simple route line between the two points
        // This will show the route on the map
        let route = createSimpleRoute(from: origin, to: destination)
        currentRoute = route
        
        isCalculatingRoute = false
        isNavigating = true
        
        print("Route created and displayed")
        print("Distance: \(calculateDistance(from: origin, to: destination)) km")
        
        // TODO: Implement proper Navigation SDK v3 turn-by-turn navigation
        // For now, we'll just show the route line on the map
    }
    
    private func createSimpleRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Route {
        // Create a simple route object for display
        // This is a placeholder until we implement proper Navigation SDK v3 routing
        let route = Route(
            id: UUID().uuidString,
            origin: origin,
            destination: destination,
            coordinates: [origin, destination],
            distance: calculateDistance(from: origin, to: destination) * 1000, // Convert to meters
            duration: calculateEstimatedDuration(distance: calculateDistance(from: origin, to: destination))
        )
        return route
    }
    
    private func calculateDistance(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return originLocation.distance(from: destinationLocation) / 1000 // Convert to kilometers
    }
    
    private func calculateEstimatedDuration(distance: Double) -> TimeInterval {
        // Estimate travel time assuming average speed of 50 km/h
        let averageSpeedKmH = 50.0
        let durationHours = distance / averageSpeedKmH
        return durationHours * 3600 // Convert to seconds
    }
    
    func stopNavigation() {
        isNavigating = false
        currentRoute = nil
        print("Navigation stopped")
    }
    
    func clearRoute() {
        routeError = nil
        isNavigating = false
        currentRoute = nil
    }
}

// Simple Route struct for displaying routes on the map
struct Route {
    let id: String
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double // in meters
    let duration: TimeInterval // in seconds
}
