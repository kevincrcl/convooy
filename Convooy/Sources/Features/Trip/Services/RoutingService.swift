import Foundation

protocol RoutingService {
    func computeRoute(origin: Coordinate?, destination: Coordinate, checkpoints: [Coordinate]) async throws -> RouteSummary
}

// Mock implementation for previews and testing
class MockRoutingService: RoutingService {
    func computeRoute(origin: Coordinate?, destination: Coordinate, checkpoints: [Coordinate]) async throws -> RouteSummary {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Calculate mock distance and duration based on coordinates
        let totalDistance = calculateMockDistance(origin: origin, destination: destination, checkpoints: checkpoints)
        let totalDuration = Int(Double(totalDistance) / 1000.0 * 60.0) // Rough estimate: 1km = 1 minute
        
        return RouteSummary(
            polyline: generateMockPolyline(origin: origin, destination: destination, checkpoints: checkpoints),
            distanceMeters: totalDistance,
            durationSeconds: totalDuration
        )
    }
    
    private func calculateMockDistance(origin: Coordinate?, destination: Coordinate, checkpoints: [Coordinate]) -> Int {
        var totalDistance = 0
        var previousCoordinate = origin ?? Coordinate(latitude: 37.7749, longitude: -122.4194) // Default SF
        
        // Add distance from origin to first checkpoint
        if let firstCheckpoint = checkpoints.first {
            totalDistance += calculateDistance(from: previousCoordinate, to: firstCheckpoint)
            previousCoordinate = firstCheckpoint
        }
        
        // Add distances between checkpoints
        for checkpoint in checkpoints.dropFirst() {
            totalDistance += calculateDistance(from: previousCoordinate, to: checkpoint)
            previousCoordinate = checkpoint
        }
        
        // Add distance from last checkpoint to destination
        totalDistance += calculateDistance(from: previousCoordinate, to: destination)
        
        return totalDistance
    }
    
    private func calculateDistance(from: Coordinate, to: Coordinate) -> Int {
        // Simple Euclidean distance calculation (not accurate for real-world routing)
        let latDiff = from.latitude - to.latitude
        let lngDiff = from.longitude - to.longitude
        let distance = sqrt(latDiff * latDiff + lngDiff * lngDiff)
        
        // Convert to meters (rough approximation)
        return Int(distance * 111000) // 1 degree ≈ 111km
    }
    
    private func generateMockPolyline(origin: Coordinate?, destination: Coordinate, checkpoints: [Coordinate]) -> String {
        // Generate a simple mock polyline string
        var coordinates: [Coordinate] = []
        
        if let origin = origin {
            coordinates.append(origin)
        }
        
        coordinates.append(contentsOf: checkpoints)
        coordinates.append(destination)
        
        // Create a simple polyline representation
        let polyline = coordinates.map { coord in
            "\(coord.latitude),\(coord.longitude)"
        }.joined(separator: "|")
        
        return polyline
    }
}
