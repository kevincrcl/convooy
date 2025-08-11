import SwiftUI
import MapboxMaps
import CoreLocation
import MapboxSearch

struct MapBoxMapView: UIViewRepresentable {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var navigationService = NavigationService.shared
    
    func makeUIView(context: Context) -> MapView {
        // Create map view with basic initialization
        let mapView = MapView(frame: .zero, mapInitOptions: MapBoxService.shared.getMapOptions())
        
        // Set up the map view with basic camera
        mapView.mapboxMap.setCamera(
            to: CameraOptions(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
                zoom: 12
            )
        )
        
        // Enable basic location features
        mapView.location.options.puckType = .puck2D()
        
        // Request location permissions and start updating
        locationManager.requestLocationPermission()
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update map when location changes
        if let location = locationManager.currentLocation {
            mapView.mapboxMap.setCamera(
                to: CameraOptions(
                    center: location.coordinate,
                    zoom: 15
                )
            )
        }
        
        // Update route display when route changes
        if let route = navigationService.currentRoute {
            displayRoute(route, on: mapView)
        }
    }
    
    private func displayRoute(_ route: Route, on mapView: MapView) {
        // Remove existing route if any
        try? mapView.mapboxMap.removeLayer(withId: "route-layer")
        try? mapView.mapboxMap.removeSource(withId: "route-source")
        
        // Create a GeoJSON source for the route
        let routeFeature = Feature(geometry: .lineString(LineString(route.coordinates)))
        var routeSource = GeoJSONSource(id: "route-source")
        routeSource.data = .feature(routeFeature)
        
        // Create a line layer for the route
        var routeLayer = LineLayer(id: "route-layer", source: "route-source")
        routeLayer.lineColor = .constant(StyleColor(.systemBlue))
        routeLayer.lineWidth = .constant(6)
        routeLayer.lineCap = .constant(.round)
        routeLayer.lineJoin = .constant(.round)
        
        // Add source and layer to the map
        try? mapView.mapboxMap.addSource(routeSource)
        try? mapView.mapboxMap.addLayer(routeLayer)
        
        // Fit the map to show the entire route
        if !route.coordinates.isEmpty {
            let cameraOptions = CameraOptions(
                center: route.coordinates[route.coordinates.count / 2],
                zoom: 12
            )
            mapView.mapboxMap.setCamera(to: cameraOptions)
        }
        
        print("Route displayed on map: \(route.distance) meters, \(route.duration) seconds")
    }
}

// Location Manager to handle user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
}
