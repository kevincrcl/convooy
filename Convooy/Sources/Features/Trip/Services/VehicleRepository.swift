import Foundation

protocol VehicleRepository {
    func addVehicle(_ vehicle: Vehicle) async throws
    func updateVehicle(_ vehicle: Vehicle) async throws
    func deleteVehicle(id: String) async throws
    func streamVehicles(tripId: String) -> AsyncThrowingStream<[Vehicle], Error>
}

// Mock implementation for previews and testing
class MockVehicleRepository: VehicleRepository {
    private var vehicles: [String: Vehicle] = [:]
    private var tripVehicles: [String: [String]] = [:] // tripId -> [vehicleIds]
    private var vehicleStreams: [String: AsyncThrowingStream<[Vehicle], Error>.Continuation] = [:]
    
    func addVehicle(_ vehicle: Vehicle) async throws {
        vehicles[vehicle.id] = vehicle
        
        if tripVehicles[vehicle.tripId] == nil {
            tripVehicles[vehicle.tripId] = []
        }
        tripVehicles[vehicle.tripId]?.append(vehicle.id)
        
        notifyVehiclesUpdate(tripId: vehicle.tripId)
    }
    
    func updateVehicle(_ vehicle: Vehicle) async throws {
        vehicles[vehicle.id] = vehicle
        notifyVehiclesUpdate(tripId: vehicle.tripId)
    }
    
    func deleteVehicle(id: String) async throws {
        guard let vehicle = vehicles[id] else { return }
        
        vehicles.removeValue(forKey: id)
        tripVehicles[vehicle.tripId]?.removeAll { $0 == id }
        
        notifyVehiclesUpdate(tripId: vehicle.tripId)
    }
    
    func streamVehicles(tripId: String) -> AsyncThrowingStream<[Vehicle], Error> {
        return AsyncThrowingStream { continuation in
            vehicleStreams[tripId] = continuation
            
            // Send current vehicles if they exist
            let currentVehicles = self.getVehiclesForTrip(tripId)
            continuation.yield(currentVehicles)
            
            continuation.onTermination = { _ in
                self.vehicleStreams.removeValue(forKey: tripId)
            }
        }
    }
    
    private func getVehiclesForTrip(_ tripId: String) -> [Vehicle] {
        guard let vehicleIds = tripVehicles[tripId] else { return [] }
        return vehicleIds.compactMap { vehicles[$0] }
    }
    
    private func notifyVehiclesUpdate(tripId: String) {
        let updatedVehicles = getVehiclesForTrip(tripId)
        vehicleStreams[tripId]?.yield(updatedVehicles)
    }
    
    // Helper method for testing
    func seedMockData() {
        let mockVehicles = [
            Vehicle(
                tripId: "mock-trip-1",
                label: "Alex's Car",
                driverUserId: "mock-user-1",
                capacity: 4,
                notes: "SUV with good trunk space"
            ),
            Vehicle(
                tripId: "mock-trip-1",
                label: "Sarah's Van",
                driverUserId: "mock-user-2",
                capacity: 7,
                notes: "Minivan for larger groups"
            )
        ]
        
        for vehicle in mockVehicles {
            vehicles[vehicle.id] = vehicle
            if tripVehicles[vehicle.tripId] == nil {
                tripVehicles[vehicle.tripId] = []
            }
            tripVehicles[vehicle.tripId]?.append(vehicle.id)
        }
    }
}
