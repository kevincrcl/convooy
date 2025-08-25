import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationService: LocationService
    @StateObject private var searchService: MockMapboxSearchService
    @StateObject private var routeService: RouteService
    
    // Use simple default values
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    init() {
        self._locationService = StateObject(wrappedValue: LocationService())
        self._searchService = StateObject(wrappedValue: MockMapboxSearchService())
        self._routeService = StateObject(wrappedValue: RouteService())
    }
    
    var body: some View {
        TabView {
            // Map Tab
            MapTabView(
                locationService: locationService,
                searchService: searchService,
                routeService: routeService,
                region: $region
            )
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
            
            // Trips Tab
            TripsTabView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Trips")
                }
        }
        .accentColor(.blue)
    }
}
    
// MARK: - Map Tab View
struct MapTabView: View {
    let locationService: LocationService
    let searchService: MockMapboxSearchService
    let routeService: RouteService
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                mapView
                    .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 0) {
                    LocationSearchInput<MockMapboxSearchService>(searchService: searchService, routeService: routeService, locationService: locationService)
                        .padding(.top, 60)
                    
                    // Route info panel
                    if let route = routeService.route {
                        RouteInfoPanel(route: route, destinationCoordinate: routeService.selectedDestination?.placemark.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                locationService.requestLocationPermission()
            }
            .onChange(of: locationService.currentLocation) { oldValue, newValue in
                if let location = newValue {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = location.coordinate
                    }
                }
            }
        }
    }
    
    private var mapView: some View {
        MapKitMapView(
            region: $region,
            annotations: allAnnotations,
            route: routeService.route
        )
    }
    
    private var allAnnotations: [CustomMapAnnotation] {
        var annotations: [CustomMapAnnotation] = []
        
        // Add current location
        if let location = locationService.currentLocation {
            let currentLocationAnnotation = CustomMapAnnotation(coordinate: location.coordinate, type: .currentLocation)
            annotations.append(currentLocationAnnotation)
        }
        
        // Add destination if route exists
        if let destination = routeService.selectedDestination {
            let destinationAnnotation = CustomMapAnnotation(coordinate: destination.placemark.coordinate, type: .destination)
            annotations.append(destinationAnnotation)
        }
        
        return annotations
    }
}

// MARK: - Trips Tab View
struct TripsTabView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Trip Planning")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Plan your trips, organize vehicles, and coordinate with your group")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    NavigationLink(destination: TripCreateView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Trip")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TripOverviewView(tripId: "mock-trip-1")) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Sample Trip")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CustomMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
}

enum AnnotationType {
    case currentLocation
    case destination
}

struct RouteInfoPanel: View {
    let route: MKRoute
    let destinationCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                Text("Driving Route")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Text("Distance:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatDistance(route.distance))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Time:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatTime(route.expectedTravelTime))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            // Start Navigation Button
            Button(action: {
                startTurnByTurnNavigation()
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white)
                    Text("Start Navigation")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func startTurnByTurnNavigation() {
        // Open the route in Apple Maps for turn-by-turn navigation
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        
        // Open in Apple Maps
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: distance)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

struct MapKitMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [CustomMapAnnotation]
    let route: MKRoute?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)
        
        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add annotations
        for annotation in annotations {
            let mkAnnotation = MKPointAnnotation()
            mkAnnotation.coordinate = annotation.coordinate
            mkAnnotation.title = annotation.type == .currentLocation ? "Current Location" : "Destination"
            mapView.addAnnotation(mkAnnotation)
        }
        
        // Add route overlay if available and zoom to show entire route
        if let route = route {
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            // Zoom to show the entire route with some padding
            let routeRect = route.polyline.boundingMapRect
            let padding = UIEdgeInsets(top: 80, left: 50, bottom: 100, right: 50)
            mapView.setVisibleMapRect(routeRect, edgePadding: padding, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitMapView
        
        init(_ parent: MapKitMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "CustomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            // Find the corresponding custom annotation to determine the type
            if let customAnnotation = parent.annotations.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                if customAnnotation.type == .currentLocation {
                    annotationView?.image = UIImage(systemName: "location.circle.fill")?.withTintColor(.blue, renderingMode: .alwaysOriginal)
                } else if customAnnotation.type == .destination {
                    annotationView?.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

#Preview {
    ContentView()
} 
