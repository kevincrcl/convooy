import SwiftUI
import MapKit

struct LocationSearchInput<T: SearchServiceProtocol>: View {
    @ObservedObject var searchService: T
    @ObservedObject var routeService: RouteService
    @ObservedObject var locationService: LocationService
    @State private var isShowingSuggestions = false
    @State private var selectedDestinationText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search for destination...", text: $searchService.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchService.searchText) { query in
                        // Show suggestions as user types (minimum 2 characters)
                        if query.isEmpty {
                            isShowingSuggestions = false
                        } else if query.count >= 2 {
                            isShowingSuggestions = true
                        }
                    }

                if !searchService.searchText.isEmpty {
                    Button(action: {
                        searchService.clearSearch()
                        isShowingSuggestions = false
                        selectedDestinationText = ""
                        routeService.clearRoute()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)

            // Loading indicator
            if searchService.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            
            // Error message
            if let errorMessage = searchService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }

            // Search results
            if isShowingSuggestions && !searchService.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchService.searchResults) { result in
                            Button(action: {
                                searchService.searchText = result.name
                                isShowingSuggestions = false
                                selectedDestinationText = result.name

                                // Convert to MKMapItem for route calculation
                                let mapItem = createMapItem(from: result)
                                if let currentLocation = locationService.currentLocation {
                                    routeService.calculateRoute(from: currentLocation, to: mapItem)
                                }
                                
                                // Hide suggestions after selection
                                isShowingSuggestions = false
                            }) {
                                HStack(spacing: 12) {
                                    // Result type icon
                                    Image(systemName: result.type.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(result.fullAddress)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        // Result type badge
                                        Text(result.type.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    Spacer()
                                    
                                    // Relevance indicator
                                    if result.relevance > 0.8 {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal)
    }
    
    private func createMapItem(from result: MapboxSearchResult) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude
        )
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = result.name
        
        return mapItem
    }
}

#Preview {
    LocationSearchInput<MockMapboxSearchService>(
        searchService: MockMapboxSearchService(),
        routeService: RouteService(),
        locationService: LocationService()
    )
} 