import Foundation
import SwiftUI

@MainActor
class TripInvitesViewModel: ObservableObject {
    @Published var invitations: [Invitation] = []
    @Published var participants: [Participant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let invitationRepository: InvitationRepository
    private let participantRepository: ParticipantRepository
    private let tripId: String
    
    init(
        tripId: String = "mock-trip-1",
        invitationRepository: InvitationRepository = MockInvitationRepository(),
        participantRepository: ParticipantRepository = MockParticipantRepository()
    ) {
        self.tripId = tripId
        self.invitationRepository = invitationRepository
        self.participantRepository = participantRepository
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let invitationsTask = loadInvitations()
        async let participantsTask = loadParticipants()
        
        do {
            let (invitations, participants) = try await (invitationsTask, participantsTask)
            self.invitations = invitations
            self.participants = participants
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createInvitation(mode: InviteMode) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let invitation = try await invitationRepository.createInvite(tripId: tripId, mode: mode)
            // The invitation will be added to the list via the stream
        } catch {
            errorMessage = "Failed to create invitation: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func revokeInvite(invitationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await invitationRepository.revokeInvite(tripId: tripId, invitationId: invitationId)
            // The invitation will be removed from the list via the stream
        } catch {
            errorMessage = "Failed to revoke invitation: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadInvitations() async throws -> [Invitation] {
        let stream = invitationRepository.streamInvitations(tripId: tripId)
        var invitations: [Invitation] = []
        
        for try await invitationList in stream {
            invitations = invitationList
            break // Just get the first value for now
        }
        
        return invitations
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
    
    var activeInvitations: [Invitation] {
        invitations.filter { !$0.isExpired }
    }
    
    var expiredInvitations: [Invitation] {
        invitations.filter { $0.isExpired }
    }
    
    var pendingParticipants: [Participant] {
        participants.filter { $0.status == .invited }
    }
    
    var joinedParticipants: [Participant] {
        participants.filter { $0.status == .joined }
    }
    
    var declinedParticipants: [Participant] {
        participants.filter { $0.status == .declined }
    }
}

// MARK: - Preview Helper

extension TripInvitesViewModel {
    static func preview() -> TripInvitesViewModel {
        let viewModel = TripInvitesViewModel()
        viewModel.invitations = [
            Invitation(
                tripId: "mock-trip-1",
                code: "ABC123",
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                createdBy: "mock-user-1",
                mode: .code
            ),
            Invitation(
                tripId: "mock-trip-1",
                code: "XYZ789",
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                createdBy: "mock-user-1",
                mode: .link
            )
        ]
        viewModel.participants = [
            Participant(
                tripId: "mock-trip-1",
                userId: "alex.smith",
                role: .owner,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "sarah.jones",
                role: .driver,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "mike.wilson",
                role: .passenger,
                status: .invited
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "jane.doe",
                role: .passenger,
                status: .declined
            )
        ]
        return viewModel
    }
}
