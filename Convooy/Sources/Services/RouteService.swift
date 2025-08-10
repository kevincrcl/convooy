import Foundation
import MapKit
import Combine

class RouteService: NSObject, ObservableObject {
    @Published var route: MKRoute?
    @Published var selectedDestination: MKMapItem?
    @Published var isCalculatingRoute = false
    @Published var routeError: String?
    
    func calculateRoute(from startLocation: CLLocation, to destination: MKMapItem) {
        selectedDestination = destination
        isCalculatingRoute = true
        routeError = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
        request.destination = destination
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isCalculatingRoute = false
                
                if let error = error {
                    self?.routeError = "Route calculation failed: \(error.localizedDescription)"
                    print("Route error: \(error)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    self?.routeError = "No route found to destination"
                    return
                }
                
                self?.route = route
            }
        }
    }
    
    func clearRoute() {
        route = nil
        selectedDestination = nil
        routeError = nil
    }
} 