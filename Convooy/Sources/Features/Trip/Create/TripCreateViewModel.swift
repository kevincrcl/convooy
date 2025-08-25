import Foundation
import SwiftUI

@MainActor
class TripCreateViewModel: ObservableObject {
    @Published var title = ""
    @Published var notes = ""
    @Published var origin: Place?
    @Published var destination: Place?
    @Published var checkpoints: [Checkpoint] = []
    @Published var visibility: TripVisibility = .private
    @Published var route: RouteSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tripRepository: TripRepository
    private let routingService: RoutingService
    private let currentUserId: String
    
    init(
        tripRepository: TripRepository = MockTripRepository(),
        routingService: RoutingService = MockRoutingService(),
        currentUserId: String = "mock-user-1"
    ) {
        self.tripRepository = tripRepository
        self.routingService = routingService
        self.currentUserId = currentUserId
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        !title.isEmpty && destination != nil
    }
    
    var canComputeRoute: Bool {
        destination != nil && !checkpoints.isEmpty
    }
    
    var totalStops: Int {
        var count = 1 // destination
        if origin != nil { count += 1 }
        count += checkpoints.count
        return count
    }
    
    // MARK: - Public Methods
    
    func addCheckpoint(_ checkpoint: Checkpoint) {
        checkpoints.append(checkpoint)
        
        // Auto-compute route if we have enough stops
        if canComputeRoute {
            Task {
                await computeRoute()
            }
        }
    }
    
    func removeCheckpoint(_ checkpoint: Checkpoint) {
        checkpoints.removeAll { $0.id == checkpoint.id }
        
        // Reorder remaining checkpoints
        for (index, checkpoint) in checkpoints.enumerated() {
            checkpoints[index] = Checkpoint(
                id: checkpoint.id,
                name: checkpoint.name,
                coordinate: checkpoint.coordinate,
                etaHint: checkpoint.etaHint,
                order: index
            )
        }
        
        // Recompute route if needed
        if canComputeRoute {
            Task {
                await computeRoute()
            }
        } else {
            route = nil
        }
    }
    
    func reorderCheckpoints(_ newOrder: [Checkpoint]) {
        checkpoints = newOrder.enumerated().map { index, checkpoint in
            Checkpoint(
                id: checkpoint.id,
                name: checkpoint.name,
                coordinate: checkpoint.coordinate,
                etaHint: checkpoint.etaHint,
                order: index
            )
        }
        
        // Recompute route if we have one
        if route != nil && canComputeRoute {
            Task {
                await computeRoute()
            }
        }
    }
    
    func computeRoute() async {
        guard canComputeRoute else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newRoute = try await routingService.computeRoute(
                origin: origin?.coordinate,
                destination: destination!.coordinate,
                checkpoints: checkpoints.map { $0.coordinate }
            )
            
            route = newRoute
        } catch {
            errorMessage = "Failed to compute route: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveTrip() async -> Trip? {
        guard canSave else { return nil }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let trip = Trip(
                ownerId: currentUserId,
                title: title,
                notes: notes.isEmpty ? nil : notes,
                origin: origin,
                destination: destination!,
                checkpoints: checkpoints,
                route: route,
                visibility: visibility
            )
            
            let savedTrip = try await tripRepository.createTrip(trip)
            isLoading = false
            return savedTrip
            
        } catch {
            errorMessage = "Failed to save trip: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Validation
    
    func validateTrip() -> [String] {
        var errors: [String] = []
        
        if title.isEmpty {
            errors.append("Trip title is required")
        }
        
        if destination == nil {
            errors.append("Destination is required")
        }
        
        if checkpoints.isEmpty {
            errors.append("At least one checkpoint is required")
        }
        
        if route == nil {
            errors.append("Route must be computed")
        }
        
        return errors
    }
}

// MARK: - Preview Helper

extension TripCreateViewModel {
    static func preview() -> TripCreateViewModel {
        let viewModel = TripCreateViewModel()
        viewModel.title = "Weekend Trip to Napa"
        viewModel.notes = "Wine tasting weekend with friends"
        viewModel.origin = Place(
            name: "San Francisco",
            coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        viewModel.destination = Place(
            name: "Napa Valley",
            coordinate: Coordinate(latitude: 38.2975, longitude: -122.2869)
        )
        viewModel.checkpoints = [
            Checkpoint(
                name: "Golden Gate Bridge",
                coordinate: Coordinate(latitude: 37.8199, longitude: -122.4783),
                order: 0
            )
        ]
        viewModel.visibility = .inviteOnly
        return viewModel
    }
}
