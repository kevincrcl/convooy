import SwiftUI
import MapboxMaps
import CoreLocation

struct MapBoxMapView: UIViewRepresentable {
    @ObservedObject var mapBoxService: MapBoxService
    @ObservedObject var locationService: LocationService
    
    func makeUIView(context: Context) -> MapView {
        // Create MapBox map view - access token should be in Info.plist
        let options = MapInitOptions(
            styleURI: StyleURI(rawValue: MapBoxConfig.mapStyleURL)
        )
        
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        
        // Enable user location first
        mapView.location.options.puckType = .puck2D()
        
        // Set initial camera position - will be overridden when location is available
        let cameraOptions = CameraOptions(
            center: MapBoxConfig.defaultCenter,
            zoom: MapBoxConfig.defaultZoom
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        // Set delegate
        let _ = mapView.mapboxMap.onMapLoaded.observe { _ in
            print("🗺️ MapBox map loaded successfully")
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update map when location changes
        if let location = locationService.currentLocation {
            let cameraOptions = CameraOptions(
                center: location.coordinate,
                zoom: 15.0
            )
            mapView.mapboxMap.setCamera(to: cameraOptions)
            print("🗺️ Map focused on current location: \(location.coordinate)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MapBoxMapView
        
        init(_ parent: MapBoxMapView) {
            self.parent = parent
        }
    }
}

// MARK: - Current Location Button
struct CurrentLocationButton: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Button(action: {
            locationService.startUpdatingLocation()
        }) {
            Image(systemName: "location.fill")
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding()
    }
}

#Preview {
    MapBoxMapView(
        mapBoxService: MapBoxService.shared,
        locationService: LocationService()
    )
} 
