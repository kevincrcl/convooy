import Foundation

protocol GeocodingService {
    func searchPlaces(query: String) async throws -> [Place]
}

// Mock implementation for previews and testing
class MockGeocodingService: GeocodingService {
    func searchPlaces(query: String) async throws -> [Place] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let mockPlaces = [
            Place(
                name: "San Francisco International Airport",
                coordinate: Coordinate(latitude: 37.6213, longitude: -122.3790),
                address: "San Francisco, CA 94128"
            ),
            Place(
                name: "Golden Gate Bridge",
                coordinate: Coordinate(latitude: 37.8199, longitude: -122.4783),
                address: "San Francisco, CA 94129"
            ),
            Place(
                name: "Fisherman's Wharf",
                coordinate: Coordinate(latitude: 37.8080, longitude: -122.4177),
                address: "San Francisco, CA 94133"
            ),
            Place(
                name: "Alcatraz Island",
                coordinate: Coordinate(latitude: 37.8270, longitude: -122.4230),
                address: "San Francisco, CA 94133"
            ),
            Place(
                name: "Pier 39",
                coordinate: Coordinate(latitude: 37.8087, longitude: -122.4098),
                address: "San Francisco, CA 94133"
            )
        ]
        
        // Filter by query if provided
        if !query.isEmpty {
            return mockPlaces.filter { place in
                place.name.localizedCaseInsensitiveContains(query) ||
                (place.address?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        
        return mockPlaces
    }
}
