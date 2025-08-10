import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var searchService = LocationSearchService()
    @StateObject private var routeService = RouteService()
    @StateObject private var mapBoxService = MapBoxService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // MapBox Map
                MapBoxMapView(
                    mapBoxService: mapBoxService,
                    locationService: locationService
                )
                .ignoresSafeArea()
                
                // Current Location Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CurrentLocationButton(locationService: locationService)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
                
                // Search Input
                VStack {
                    LocationSearchInput(
                        searchService: searchService,
                        routeService: routeService,
                        locationService: locationService
                    )
                    .padding()
                    
                    Spacer()
                }
                
                // Route Info Panel
                if let route = routeService.currentRoute {
                    VStack {
                        Spacer()
                        RouteInfoPanel(
                            route: route,
                            destinationCoordinate: routeService.selectedDestination?.coordinate
                        )
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("ConvooyLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                        Text("Convooy")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            mapBoxService.configureMapBox()
        }
    }
}

struct RouteInfoPanel: View {
    let route: Route
    let destinationCoordinate: CLLocationCoordinate2D?
    
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
        // This will be replaced with MapBox navigation
        print("Starting MapBox navigation to: \(destinationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))")
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        if distance < 1000 {
            let meters = Measurement(value: distance, unit: UnitLength.meters)
            return formatter.string(from: meters)
        } else {
            let kilometers = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: kilometers)
        }
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
