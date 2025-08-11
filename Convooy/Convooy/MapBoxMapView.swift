import SwiftUI
import MapboxMaps
import CoreLocation

struct MapBoxMapView: UIViewRepresentable {
    @ObservedObject var locationManager = LocationManager()
    
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
    }
}

// Location Manager to handle user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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
