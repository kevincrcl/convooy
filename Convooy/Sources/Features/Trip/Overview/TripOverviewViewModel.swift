import Foundation
import SwiftUI

@MainActor
class TripOverviewViewModel: ObservableObject {
    @Published var trip: Trip?
    @Published var vehicles: [Vehicle] = []
    @Published var participants: [Participant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tripRepository: TripRepository
    private let vehicleRepository: VehicleRepository
    private let participantRepository: ParticipantRepository
    private let tripId: String
    
    init(
        tripId: String,
        tripRepository: TripRepository = MockTripRepository(),
        vehicleRepository: VehicleRepository = MockVehicleRepository(),
        participantRepository: ParticipantRepository = MockParticipantRepository()
    ) {
        self.tripId = tripId
        self.tripRepository = tripRepository
        self.vehicleRepository = vehicleRepository
        self.participantRepository = participantRepository
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let tripTask = loadTrip()
        async let vehiclesTask = loadVehicles()
        async let participantsTask = loadParticipants()
        
        do {
            let (trip, vehicles, participants) = try await (tripTask, vehiclesTask, participantsTask)
            self.trip = trip
            self.vehicles = vehicles
            self.participants = participants
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func markTripReady() async {
        guard let trip = trip, trip.canMarkReady else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await tripRepository.markReady(tripId: tripId)
            // The trip will be updated via the stream
        } catch {
            errorMessage = "Failed to mark trip as ready: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func setLeaderVehicle(_ vehicleId: String?) async {
        guard var trip = trip else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
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
                leaderVehicleId: vehicleId,
                visibility: trip.visibility,
                createdAt: trip.createdAt,
                updatedAt: Date()
            )
            
            try await tripRepository.updateTrip(updatedTrip)
            // The trip will be updated via the stream
            
        } catch {
            errorMessage = "Failed to set leader vehicle: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadTrip() async throws -> Trip {
        let stream = tripRepository.streamTrip(id: tripId)
        var trip: Trip?
        
        for try await tripData in stream {
            trip = tripData
            break // Just get the first value for now
        }
        
        guard let trip = trip else {
            throw MockError.tripNotFound
        }
        
        return trip
    }
    
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
    
    // MARK: - Computed Properties
    
    var canMarkReady: Bool {
        guard let trip = trip else { return false }
        return trip.canMarkReady
    }
    
    var tripStatus: TripState {
        trip?.state ?? .draft
    }
    
    var totalParticipants: Int {
        participants.count
    }
    
    var totalVehicles: Int {
        vehicles.count
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
    
    var hasLeaderVehicle: Bool {
        trip?.leaderVehicleId != nil
    }
    
    var leaderVehicle: Vehicle? {
        guard let leaderId = trip?.leaderVehicleId else { return nil }
        return vehicles.first { $0.id == leaderId }
    }
}

// MARK: - Preview Helper

extension TripOverviewViewModel {
    static func preview() -> TripOverviewViewModel {
        let viewModel = TripOverviewViewModel(tripId: "mock-trip-1")
        viewModel.trip = Trip(
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
            route: RouteSummary(
                polyline: "mock-polyline",
                distanceMeters: 50000,
                durationSeconds: 3600
            ),
            visibility: .inviteOnly
        )
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
                role: .owner,
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
