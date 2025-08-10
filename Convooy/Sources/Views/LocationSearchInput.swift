import SwiftUI
import MapKit

struct LocationSearchInput: View {
    @ObservedObject var searchService: LocationSearchService
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
                        // Only show suggestions if this is a new search (not the selected destination)
                        if query != selectedDestinationText {
                            if query.isEmpty {
                                isShowingSuggestions = false
                            } else if query.count >= 3 {
                                isShowingSuggestions = true
                            }
                        }
                    }

                if !searchService.searchText.isEmpty {
                    Button(action: {
                        searchService.searchText = ""
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

            if isShowingSuggestions && !searchService.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchService.searchResults, id: \.self) { result in
                            Button(action: {
                                let destinationName = result.name ?? "Unknown Location"
                                searchService.searchText = destinationName
                                isShowingSuggestions = false

                                // Calculate route to selected destination
                                if let currentLocation = locationService.currentLocation {
                                    routeService.calculateRoute(from: currentLocation, to: result)
                                }
                                
                                // Hide suggestions after selection
                                isShowingSuggestions = false
                                searchService.searchResults = []
                                selectedDestinationText = destinationName
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.name ?? "Unknown Location")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        if let address = result.placemark.thoroughfare {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "location.circle")
                                        .foregroundColor(.blue)
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
                .frame(maxHeight: 200)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    LocationSearchInput(
        searchService: LocationSearchService(),
        routeService: RouteService(),
        locationService: LocationService()
    )
} 