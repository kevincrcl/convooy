import Foundation
import MapboxDirections
import CoreLocation

@MainActor
class StopManagementService: ObservableObject {
    static let shared = StopManagementService()
    
    @Published var stops: [Stop] = []
    @Published var isAddingStop = false
    
    private init() {}
    
    // Add a stop to the list
    func addStop(_ stop: Stop) {
        stops.append(stop)
        print("Added stop: \(stop.name) at position \(stops.count)")
        
        // Automatically recalculate route with new stops
        recalculateRouteWithStops()
    }
    
    // Remove a stop at a specific index
    func removeStop(at index: Int) {
        guard index < stops.count else { return }
        let removedStop = stops.remove(at: index)
        print("Removed stop: \(removedStop.name)")
        
        // Recalculate route without this stop
        recalculateRouteWithStops()
    }
    
    // Reorder stops
    func moveStop(from source: IndexSet, to destination: Int) {
        stops.move(fromOffsets: source, toOffset: destination)
        print("Reordered stops")
        
        // Recalculate route with new order
        recalculateRouteWithStops()
    }
    
    // Clear all stops
    func clearAllStops() {
        stops.removeAll()
        print("Cleared all stops")
        
        // Recalculate route without stops
        recalculateRouteWithStops()
    }
    
    // Get all waypoints including origin, stops, and destination
    func getAllWaypoints(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> [Waypoint] {
        var waypoints: [Waypoint] = []
        
        // Add origin
        waypoints.append(Waypoint(coordinate: origin, name: "Current Location"))
        
        // Add all stops in order
        for stop in stops {
            waypoints.append(Waypoint(coordinate: stop.coordinate, name: stop.name))
        }
        
        // Add destination
        waypoints.append(Waypoint(coordinate: destination, name: "Destination"))
        
        return waypoints
    }
    
    // Private method to recalculate route with current stops
    private func recalculateRouteWithStops() {
        // Only recalculate if we have a selected destination
        guard let destination = SearchService.shared.selectedDestination,
              let currentLocation = LocationManager.shared.currentLocation else {
            return
        }
        
        Task {
            await NavigationService.shared.previewRouteWithStops(
                to: destination.coordinate,
                from: currentLocation.coordinate,
                stops: stops
            )
        }
    }
    
    // Check if a location is already a stop
    func isLocationAlreadyAStop(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return stops.contains { stop in
            // Check if coordinates are very close (within ~10 meters)
            let distance = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            return distance < 10
        }
    }
}

// Stop model
struct Stop: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    
    // Equatable conformance
    static func == (lhs: Stop, rhs: Stop) -> Bool {
        return lhs.id == rhs.id
    }
}
