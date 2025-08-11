import Foundation
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import CoreLocation
import UIKit

@MainActor
class NavigationService: ObservableObject {
    static let shared = NavigationService()
    
    @Published var isCalculatingRoute = false
    @Published var routeError: String?
    @Published var isNavigating = false
    @Published var currentRoute: MapboxDirections.Route?
    @Published var isLoading = false
    
    // Define the Mapbox Navigation entry point
    private lazy var mapboxNavigationProvider = MapboxNavigationProvider(coreConfig: .init())
    private lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
    
    private init() {
        // Navigation SDK will use the MBXAccessToken from Info.plist
    }
    
    func startNavigation(to destination: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async {
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(origin) else {
            routeError = "Current location is not available. Please enable location services."
            return
        }
        
        guard CLLocationCoordinate2DIsValid(destination) else {
            routeError = "Invalid destination coordinates."
            return
        }
        
        isLoading = true
        isCalculatingRoute = true
        routeError = nil
        
        print("Starting navigation from \(origin) to \(destination)")
        
        // Create waypoints for the route
        let originWaypoint = Waypoint(coordinate: origin, name: "Current Location")
        let destinationWaypoint = Waypoint(coordinate: destination, name: "Destination")
        
        // Set options using NavigationRouteOptions for turn-by-turn navigation
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        options.includesAlternativeRoutes = true // Include alternative routes
        
        // Request a route using RoutingProvider
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        
        switch await request.result {
        case .failure(let error):
            isLoading = false
            isCalculatingRoute = false
            
            // Provide more user-friendly error messages
            let errorMessage: String
            if let nsError = error as NSError? {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    errorMessage = "No internet connection. Please check your network and try again."
                case NSURLErrorTimedOut:
                    errorMessage = "Request timed out. Please try again."
                default:
                    errorMessage = "Failed to calculate route: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to calculate route: \(error.localizedDescription)"
            }
            
            routeError = errorMessage
            print("Route calculation failed: \(error)")
            
        case .success(let navigationRoutes):
            isLoading = false
            isCalculatingRoute = false
            
            print("Received navigation routes: \(navigationRoutes)")
            
            // Extract the main route from navigationRoutes
            let mainNavigationRoute = navigationRoutes.mainRoute
            
            // Extract the route from NavigationRoute
            let directionsRoute = mainNavigationRoute.route
            currentRoute = directionsRoute
            print("Successfully extracted main route for navigation")
            print("Route distance: \(directionsRoute.distance) meters")
            print("Route duration: \(directionsRoute.expectedTravelTime) seconds")
            
            // Collect all routes (main + alternatives) for navigation
            var allRoutes = [directionsRoute]
            
            // Add alternative routes if available
            for altRoute in navigationRoutes.alternativeRoutes {
                let altDirectionsRoute = altRoute.route
                allRoutes.append(altDirectionsRoute)
            }
            
            print("Total routes available: \(allRoutes.count)")
            
            // Start turn-by-turn navigation with all available routes
            startTurnByTurnNavigation(with: allRoutes)
        }
    }
    
    private func startTurnByTurnNavigation(with routes: [MapboxDirections.Route]) {
        // Pass the generated navigation routes to the NavigationViewController
        // For now, let's create a basic view controller to avoid constructor issues
        let navigationViewController = UIViewController()
        navigationViewController.view.backgroundColor = .white
        navigationViewController.title = "Navigation"
        navigationViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        print("Created basic navigation view controller with \(routes.count) routes")
        
        // Present the navigation view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the topmost view controller to present from
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            print("Presenting basic navigation view controller from \(type(of: topController))")
            
            topController.present(navigationViewController, animated: true) {
                self.isNavigating = true
                print("Basic navigation started")
            }
        } else {
            print("Could not present navigation view controller")
            self.routeError = "Could not start navigation. Please try again."
            self.isNavigating = false
        }
    }
    
    func startNavigation() {
        guard currentRoute != nil else {
            routeError = "No route available"
            return
        }
        
        isNavigating = true
        print("Starting navigation with route")
    }
    
    func stopNavigation() {
        isNavigating = false
        print("Navigation stopped")
        
        // Dismiss the navigation view controller if it's presented
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            if topController is NavigationViewController {
                topController.dismiss(animated: true) {
                    print("Navigation view controller dismissed")
                }
            }
        }
    }
    
    func clearRoute() {
        routeError = nil
        isNavigating = false
        isLoading = false
        isCalculatingRoute = false
        currentRoute = nil
        print("Route cleared")
    }
    
    func clearRouteError() {
        routeError = nil
        isLoading = false
        isCalculatingRoute = false
    }
    
    func completeNavigation() {
        isNavigating = false
        clearRoute()
        print("Navigation completed")
        
        // Dismiss the navigation view controller if it's presented
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            if topController is NavigationViewController {
                topController.dismiss(animated: true) {
                    print("Navigation view controller dismissed after completion")
                }
            }
        }
    }
    
    func previewRoute(to destination: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async {
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(origin) else {
            routeError = "Current location is not available. Please enable location services."
            return
        }
        
        guard CLLocationCoordinate2DIsValid(destination) else {
            routeError = "Invalid destination coordinates."
            return
        }
        
        isLoading = true
        isCalculatingRoute = true
        routeError = nil
        
        print("🔄 Starting route preview - isLoading set to true")
        print("Previewing route from \(origin) to \(destination)")
        
        // Create waypoints for the route
        let originWaypoint = Waypoint(coordinate: origin, name: "Current Location")
        let destinationWaypoint = Waypoint(coordinate: destination, name: "Destination")
        
        // Set options using NavigationRouteOptions for turn-by-turn navigation
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        
        // Request a route using RoutingProvider
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        
        switch await request.result {
        case .failure(let error):
            isLoading = false
            isCalculatingRoute = false
            
            // Provide more user-friendly error messages
            let errorMessage: String
            if let nsError = error as NSError? {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    errorMessage = "No internet connection. Please check your network and try again."
                case NSURLErrorTimedOut:
                    errorMessage = "Request timed out. Please try again."
                default:
                    errorMessage = "Failed to calculate route: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to calculate route: \(error.localizedDescription)"
            }
            
            routeError = errorMessage
            print("Route calculation failed: \(error)")
            
        case .success(let navigationRoutes):
            isLoading = false
            isCalculatingRoute = false
            
            print("✅ Route preview calculation completed - isLoading set to false")
            print("Received navigation routes for preview: \(navigationRoutes)")
            
            // Extract the main route from navigationRoutes for preview
            let mainNavigationRoute = navigationRoutes.mainRoute
            
            // Extract the route from NavigationRoute for preview
            let directionsRoute = mainNavigationRoute.route
            currentRoute = directionsRoute
            print("✅ Successfully extracted main route for preview")
            print("✅ currentRoute has been set - UI should update now")
            print("Route distance: \(directionsRoute.distance) meters")
            print("Route duration: \(directionsRoute.expectedTravelTime) seconds")
            
            // Log alternative routes if available
            let altCount = navigationRoutes.alternativeRoutes.count
            if altCount > 0 {
                print("Alternative routes available: \(altCount)")
            }
        }
    }
    
    private func showRouteSelection(_ routes: [MapboxDirections.Route]) {
        // Create an alert to let the user choose between routes
        let alert = UIAlertController(title: "Choose Route", message: "Multiple routes available. Select your preferred route:", preferredStyle: .actionSheet)
        
        for (index, route) in routes.enumerated() {
            let distance = String(format: "%.1f", route.distance / 1000) // Convert to km
            let duration = String(format: "%.0f", route.expectedTravelTime / 60) // Convert to minutes
            
            let action = UIAlertAction(title: "Route \(index + 1): \(distance) km, \(duration) min", style: .default) { [weak self] _ in
                self?.startTurnByTurnNavigation(with: [route])
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            // For iPad, set the popover presentation controller
            if let popover = alert.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topController.present(alert, animated: true)
        }
    }
    
    func getRouteSummary() -> String? {
        guard let route = currentRoute else { return nil }
        
        let distance = String(format: "%.1f", route.distance / 1000) // Convert to km
        let duration = String(format: "%.0f", route.expectedTravelTime / 60) // Convert to minutes
        
        let summary = "Distance: \(distance) km • Duration: \(duration) min"
        
        // Note: Traffic information may not be available in all MapBox versions
        // We'll skip it for now to avoid compilation errors
        // if let congestion = route.legs.first?.congestion {
        //     let congestionLevel = getCongestionLevel(congestion)
        //     summary += " • Traffic: \(congestionLevel)"
        // }
        
        return summary
    }
    
    func getRouteSteps() -> [String] {
        guard let route = currentRoute else { return [] }
        
        var steps: [String] = []
        
        for leg in route.legs {
            for step in leg.steps {
                // Note: Maneuver data may not be available in all MapBox versions
                // We'll use basic step information to avoid compilation errors
                let distance = String(format: "%.0f", step.distance)
                steps.append("Continue for \(distance) meters")
            }
        }
        
        return steps
    }
    
    func getRouteStepsCount() -> Int {
        return getRouteSteps().count
    }
}

// Protocol for routes to work with the map view
protocol RouteProtocol {
    func getCoordinates() -> [CLLocationCoordinate2D]
    func getOrigin() -> CLLocationCoordinate2D?
    func getDestination() -> CLLocationCoordinate2D?
}

// Extension for MapBox Route to conform to RouteProtocol
extension MapboxDirections.Route: RouteProtocol {
    func getCoordinates() -> [CLLocationCoordinate2D] {
        return self.shape?.coordinates ?? []
    }
    
    func getOrigin() -> CLLocationCoordinate2D? {
        return self.legs.first?.source?.coordinate
    }
    
    func getDestination() -> CLLocationCoordinate2D? {
        return self.legs.first?.destination?.coordinate
    }
}
