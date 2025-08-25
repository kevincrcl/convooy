import Foundation

protocol TripRepository {
    func createTrip(_ draft: Trip) async throws -> Trip
    func updateTrip(_ trip: Trip) async throws
    func streamTrip(id: String) -> AsyncThrowingStream<Trip, Error>
    func markReady(tripId: String) async throws
    func deleteTrip(id: String) async throws
}

// Mock implementation for previews and testing
class MockTripRepository: TripRepository {
    private var trips: [String: Trip] = [:]
    private var tripStreams: [String: AsyncThrowingStream<Trip, Error>.Continuation] = [:]
    
    func createTrip(_ draft: Trip) async throws -> Trip {
        let trip = Trip(
            id: draft.id,
            ownerId: draft.ownerId,
            title: draft.title,
            notes: draft.notes,
            state: draft.state,
            origin: draft.origin,
            destination: draft.destination,
            checkpoints: draft.checkpoints,
            route: draft.route,
            leaderVehicleId: draft.leaderVehicleId,
            visibility: draft.visibility,
            createdAt: draft.createdAt,
            updatedAt: Date()
        )
        
        trips[trip.id] = trip
        notifyTripUpdate(trip)
        
        return trip
    }
    
    func updateTrip(_ trip: Trip) async throws {
        let updatedTrip = Trip(
            id: trip.id,
            ownerId: trip.ownerId,
            title: trip.title,
            notes: trip.notes,
            state: trip.state,
            origin: trip.origin,
            destination: trip.destination,
            checkpoints: trip.checkpoints,
            route: trip.route,
            leaderVehicleId: trip.leaderVehicleId,
            visibility: trip.visibility,
            createdAt: trip.createdAt,
            updatedAt: Date()
        )
        
        trips[trip.id] = updatedTrip
        notifyTripUpdate(updatedTrip)
    }
    
    func streamTrip(id: String) -> AsyncThrowingStream<Trip, Error> {
        return AsyncThrowingStream { continuation in
            tripStreams[id] = continuation
            
            // Send current trip if it exists
            if let trip = trips[id] {
                continuation.yield(trip)
            }
            
            continuation.onTermination = { _ in
                self.tripStreams.removeValue(forKey: id)
            }
        }
    }
    
    func markReady(tripId: String) async throws {
        guard var trip = trips[tripId] else {
            throw MockError.tripNotFound
        }
        
        // Validate requirements
        guard trip.destination != nil,
              !trip.checkpoints.isEmpty,
              trip.route != nil else {
            throw MockError.validationFailed
        }
        
        let updatedTrip = Trip(
            id: trip.id,
            ownerId: trip.ownerId,
            title: trip.title,
            notes: trip.notes,
            state: .ready,
            origin: trip.origin,
            destination: trip.destination,
            checkpoints: trip.checkpoints,
            route: trip.route,
            leaderVehicleId: trip.leaderVehicleId,
            visibility: trip.visibility,
            createdAt: trip.createdAt,
            updatedAt: Date()
        )
        
        trips[tripId] = updatedTrip
        notifyTripUpdate(updatedTrip)
    }
    
    func deleteTrip(id: String) async throws {
        trips.removeValue(forKey: id)
        tripStreams[id]?.finish()
        tripStreams.removeValue(forKey: id)
    }
    
    private func notifyTripUpdate(_ trip: Trip) {
        tripStreams[trip.id]?.yield(trip)
    }
    
    // Helper method for testing
    func seedMockData() {
        let mockTrip = Trip(
            ownerId: "mock-user-1",
            title: "Weekend Trip to Napa",
            notes: "Wine tasting weekend with friends",
            origin: Place(
                name: "San Francisco",
                coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)
            ),
            destination: Place(
                name: "Napa Valley",
                coordinate: Coordinate(latitude: 38.2975, longitude: -122.2869)
            ),
            checkpoints: [
                Checkpoint(
                    name: "Golden Gate Bridge",
                    coordinate: Coordinate(latitude: 37.8199, longitude: -122.4783),
                    order: 0
                )
            ],
            visibility: .inviteOnly
        )
        
        trips[mockTrip.id] = mockTrip
    }
}

enum MockError: Error, LocalizedError {
    case tripNotFound
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .tripNotFound:
            return "Trip not found"
        case .validationFailed:
            return "Trip validation failed"
        }
    }
}
