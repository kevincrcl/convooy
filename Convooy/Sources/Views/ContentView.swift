import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var searchService = LocationSearchService()
    @StateObject private var routeService = RouteService()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Map(coordinateRegion: $region, annotationItems: allAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        if annotation.type == .currentLocation {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        } else if annotation.type == .destination {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 0) {
                    LocationSearchInput(searchService: searchService, routeService: routeService, locationService: locationService)
                        .padding(.top, 60)
                    
                    // Route info panel
                    if let route = routeService.route {
                        RouteInfoPanel(route: route)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Convooy")
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
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

#Preview {
    ContentView()
} 
