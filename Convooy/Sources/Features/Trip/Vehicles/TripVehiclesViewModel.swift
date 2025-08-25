import Foundation
import SwiftUI

@MainActor
class TripVehiclesViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var participants: [Participant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let vehicleRepository: VehicleRepository
    private let participantRepository: ParticipantRepository
    private let tripId: String
    
    init(
        tripId: String,
        vehicleRepository: VehicleRepository = MockVehicleRepository(),
        participantRepository: ParticipantRepository = MockParticipantRepository()
    ) {
        self.tripId = tripId
        self.vehicleRepository = vehicleRepository
        self.participantRepository = participantRepository
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let vehiclesTask = loadVehicles()
        async let participantsTask = loadParticipants()
        
        do {
            let (vehicles, participants) = try await (vehiclesTask, participantsTask)
            self.vehicles = vehicles
            self.participants = participants
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addVehicle(_ vehicle: Vehicle) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newVehicle = Vehicle(
                tripId: tripId,
                label: vehicle.label,
                driverUserId: vehicle.driverUserId,
                capacity: vehicle.capacity,
                notes: vehicle.notes
            )
            
            try await vehicleRepository.addVehicle(newVehicle)
            
            // Add driver as participant if not already present
            await ensureParticipantExists(userId: vehicle.driverUserId, role: .driver)
            
        } catch {
            errorMessage = "Failed to add vehicle: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateVehicle(_ vehicle: Vehicle) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await vehicleRepository.updateVehicle(vehicle)
        } catch {
            errorMessage = "Failed to update vehicle: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteVehicle(_ vehicle: Vehicle) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Remove all passengers from this vehicle
            for participant in participants where participant.vehicleId == vehicle.id {
                let updatedParticipant = Participant(
                    id: participant.id,
                    tripId: participant.tripId,
                    userId: participant.userId,
                    role: participant.role,
                    vehicleId: nil,
                    status: participant.status,
                    joinedAt: participant.joinedAt,
                    declinedAt: participant.declinedAt
                )
                try await participantRepository.updateParticipant(updatedParticipant)
            }
            
            try await vehicleRepository.deleteVehicle(id: vehicle.id)
            
        } catch {
            errorMessage = "Failed to delete vehicle: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func assignParticipantToVehicle(_ participant: Participant, vehicleId: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedParticipant = Participant(
                id: participant.id,
                tripId: participant.tripId,
                userId: participant.userId,
                role: participant.role,
                vehicleId: vehicleId,
                status: participant.status,
                joinedAt: participant.joinedAt,
                declinedAt: participant.declinedAt
            )
            
            try await participantRepository.updateParticipant(updatedParticipant)
            
        } catch {
            errorMessage = "Failed to assign participant: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadVehicles() async throws -> [Vehicle] {
        let stream = vehicleRepository.streamVehicles(tripId: tripId)
        var vehicles: [Vehicle] = []
        
        for try await vehicleList in stream {
            vehicles = vehicleList
            break // Just get the first value for now
        }
        
        return vehicles
    }
    
    private func loadParticipants() async throws -> [Participant] {
        let stream = participantRepository.streamParticipants(tripId: tripId)
        var participants: [Participant] = []
        
        for try await participantList in stream {
            participants = participantList
            break // Just get the first value for now
        }
        
        return participants
    }
    
    private func ensureParticipantExists(userId: String, role: ParticipantRole) async {
        // Check if participant already exists
        if participants.contains(where: { $0.userId == userId }) {
            return
        }
        
        // Create new participant
        let participant = Participant(
            tripId: tripId,
            userId: userId,
            role: role,
            status: .joined
        )
        
        do {
            try await participantRepository.addParticipant(participant)
        } catch {
            // Log error but don't fail the vehicle creation
            print("Failed to create participant: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var availableParticipants: [Participant] {
        participants.filter { participant in
            participant.status == .joined && 
            participant.role != .owner &&
            !participant.isAssignedToVehicle
        }
    }
    
    var totalCapacity: Int {
        vehicles.reduce(0) { $0 + $1.capacity }
    }
    
    var totalOccupied: Int {
        vehicles.reduce(0) { $0 + $1.passengerUserIds.count + 1 } // +1 for driver
    }
    
    var totalAvailable: Int {
        totalCapacity - totalOccupied
    }
}

// MARK: - Preview Helper

extension TripVehiclesViewModel {
    static func preview() -> TripVehiclesViewModel {
        let viewModel = TripVehiclesViewModel(tripId: "mock-trip-1")
        viewModel.vehicles = [
            Vehicle(
                tripId: "mock-trip-1",
                label: "Alex's Car",
                driverUserId: "alex",
                capacity: 4,
                notes: "SUV with good trunk space"
            ),
            Vehicle(
                tripId: "mock-trip-1",
                label: "Sarah's Van",
                driverUserId: "sarah",
                capacity: 7,
                notes: "Minivan for larger groups"
            )
        ]
        viewModel.participants = [
            Participant(
                tripId: "mock-trip-1",
                userId: "alex",
                role: .driver,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "sarah",
                role: .driver,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "mike",
                role: .passenger,
                status: .joined
            )
        ]
        return viewModel
    }
}
