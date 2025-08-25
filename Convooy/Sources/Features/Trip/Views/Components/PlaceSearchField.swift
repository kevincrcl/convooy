import SwiftUI

struct PlaceSearchField: View {
    @Binding var searchText: String
    @Binding var selectedPlace: Place?
    let placeholder: String
    let onPlaceSelected: (Place) -> Void
    
    @State private var searchResults: [Place] = []
    @State private var isSearching = false
    @State private var showResults = false
    
    private let geocodingService: GeocodingService
    
    init(
        searchText: Binding<String>,
        selectedPlace: Binding<Place?>,
        placeholder: String,
        geocodingService: GeocodingService = MockGeocodingService(),
        onPlaceSelected: @escaping (Place) -> Void
    ) {
        self._searchText = searchText
        self._selectedPlace = selectedPlace
        self.placeholder = placeholder
        self.geocodingService = geocodingService
        self.onPlaceSelected = onPlaceSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        selectedPlace = nil
                        searchResults = []
                        showResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if showResults && !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { place in
                            PlaceSearchResultRow(place: place) {
                                selectedPlace = place
                                searchText = place.name
                                showResults = false
                                onPlaceSelected(place)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                .zIndex(1)
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            showResults = false
            return
        }
        
        isSearching = true
        showResults = true
        
        Task {
            do {
                let results = try await geocodingService.searchPlaces(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

struct PlaceSearchResultRow: View {
    let place: Place
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let address = place.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 16)
    }
}

#Preview {
    PlaceSearchField(
        searchText: .constant(""),
        selectedPlace: .constant(nil),
        placeholder: "Search for a place..."
    ) { place in
        print("Selected: \(place.name)")
    }
    .padding()
}
