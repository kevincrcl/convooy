import SwiftUI
import MapboxMaps
import CoreLocation
import MapboxSearch

struct MapBoxMapView: UIViewRepresentable {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var navigationService = NavigationService.shared
    @ObservedObject var stopService = StopManagementService.shared
    
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
            displayRoute(route as RouteProtocol, on: mapView)
        } else {
            // Clear route display if no route is set
            clearRouteDisplay(on: mapView)
        }
    }
    
    private func displayRoute(_ route: any RouteProtocol, on mapView: MapView) {
        // Remove existing route and markers if any
        clearRouteDisplay(on: mapView)
        
        // Extract coordinates from the route
        let routeCoordinates = route.getCoordinates()
        
        // Create a GeoJSON source for the route
        let routeFeature = Feature(geometry: .lineString(LineString(routeCoordinates)))
        var routeSource = GeoJSONSource(id: "route-source")
        routeSource.data = .feature(routeFeature)
        
        // Create a line layer for the route with enhanced styling
        var routeLayer = LineLayer(id: "route-layer", source: "route-source")
        routeLayer.lineColor = .constant(StyleColor(.systemBlue))
        routeLayer.lineWidth = .constant(8)
        routeLayer.lineCap = .constant(.round)
        routeLayer.lineJoin = .constant(.round)
        
        // Add a shadow effect for the route
        var routeShadowLayer = LineLayer(id: "route-shadow-layer", source: "route-source")
        routeShadowLayer.lineColor = .constant(StyleColor(.black))
        routeShadowLayer.lineWidth = .constant(10)
        routeShadowLayer.lineCap = .constant(.round)
        routeShadowLayer.lineJoin = .constant(.round)
        routeShadowLayer.lineOpacity = .constant(0.3)
        
        // Add the source and layers to the map
        try? mapView.mapboxMap.addSource(routeSource)
        // Add shadow layer first (bottom layer)
        try? mapView.mapboxMap.addLayer(routeShadowLayer)
        // Add main route layer on top
        try? mapView.mapboxMap.addLayer(routeLayer)
        
        // Add origin and destination markers
        if let origin = route.getOrigin() {
            addMarker(at: origin, title: "Origin", color: UIColor.systemGreen, on: mapView)
        }
        
        if let destination = route.getDestination() {
            addMarker(at: destination, title: "Destination", color: UIColor.systemRed, on: mapView)
        }
        
        // Add stop markers
        for (index, stop) in stopService.stops.enumerated() {
            addStopMarker(at: stop.coordinate, title: stop.name, stopNumber: index + 1, on: mapView)
        }
        
        // Fit the map to show the entire route with proper padding
        if !routeCoordinates.isEmpty {
            // Calculate the center point of the route
            let centerLat = (routeCoordinates.first!.latitude + routeCoordinates.last!.latitude) / 2
            let centerLon = (routeCoordinates.first!.longitude + routeCoordinates.last!.longitude) / 2
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            
            let cameraOptions = CameraOptions(center: center, zoom: 12)
            mapView.mapboxMap.setCamera(to: cameraOptions)
        }
    }
    
    private func addMarker(at coordinate: CLLocationCoordinate2D, title: String, color: UIColor, on mapView: MapView) {
        let markerFeature = Feature(geometry: .point(Point(coordinate)))
        let markerId = "\(title.lowercased())-marker"
        
        var markerSource = GeoJSONSource(id: markerId)
        markerSource.data = .feature(markerFeature)
        
        var markerLayer = CircleLayer(id: markerId, source: markerId)
        markerLayer.circleRadius = .constant(8)
        markerLayer.circleColor = .constant(StyleColor(color))
        markerLayer.circleStrokeColor = .constant(StyleColor(.white))
        markerLayer.circleStrokeWidth = .constant(2)
        
        try? mapView.mapboxMap.addSource(markerSource)
        try? mapView.mapboxMap.addLayer(markerLayer)
    }
    
    private func addStopMarker(at coordinate: CLLocationCoordinate2D, title: String, stopNumber: Int, on mapView: MapView) {
        let markerFeature = Feature(geometry: .point(Point(coordinate)))
        let markerId = "stop-\(stopNumber)-marker"
        
        var markerSource = GeoJSONSource(id: markerId)
        markerSource.data = .feature(markerFeature)
        
        // Create a circle layer for the stop marker
        var markerLayer = CircleLayer(id: markerId, source: markerId)
        markerLayer.circleRadius = .constant(10)
        markerLayer.circleColor = .constant(StyleColor(.systemBlue))
        markerLayer.circleStrokeColor = .constant(StyleColor(.white))
        markerLayer.circleStrokeWidth = .constant(3)
        
        // Create a symbol layer for the stop number
        let numberLayerId = "stop-\(stopNumber)-number"
        var numberLayer = SymbolLayer(id: numberLayerId, source: markerId)
        numberLayer.textField = .constant("\(stopNumber)")
        numberLayer.textColor = .constant(StyleColor(.white))
        numberLayer.textSize = .constant(12)
        numberLayer.textFont = .constant(["Arial Unicode MS Bold"])
        
        try? mapView.mapboxMap.addSource(markerSource)
        try? mapView.mapboxMap.addLayer(markerLayer)
        try? mapView.mapboxMap.addLayer(numberLayer)
    }
    
    private func clearRouteDisplay(on mapView: MapView) {
        // Remove route layers
        try? mapView.mapboxMap.removeLayer(withId: "route-layer")
        try? mapView.mapboxMap.removeLayer(withId: "route-shadow-layer")
        try? mapView.mapboxMap.removeSource(withId: "route-source")
        
        // Remove origin marker
        try? mapView.mapboxMap.removeLayer(withId: "origin-marker")
        try? mapView.mapboxMap.removeSource(withId: "origin-marker")
        
        // Remove destination marker
        try? mapView.mapboxMap.removeLayer(withId: "destination-marker")
        try? mapView.mapboxMap.removeSource(withId: "destination-marker")
        
        // Remove all stop markers
        for i in 1...20 { // Remove up to 20 stops (should be enough for most use cases)
            try? mapView.mapboxMap.removeLayer(withId: "stop-\(i)-marker")
            try? mapView.mapboxMap.removeLayer(withId: "stop-\(i)-number")
            try? mapView.mapboxMap.removeSource(withId: "stop-\(i)-marker")
        }
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
