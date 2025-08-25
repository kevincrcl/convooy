import Foundation

protocol InvitationRepository {
    func createInvite(tripId: String, mode: InviteMode) async throws -> Invitation
    func revokeInvite(tripId: String, invitationId: String) async throws
    func resolveCode(_ code: String) async throws -> String /* tripId */
    func streamInvitations(tripId: String) -> AsyncThrowingStream<[Invitation], Error>
}

// Mock implementation for previews and testing
class MockInvitationRepository: InvitationRepository {
    private var invitations: [String: Invitation] = [:]
    private var tripInvitations: [String: [String]] = [:] // tripId -> [invitationIds]
    private var codeToTripId: [String: String] = [:] // code -> tripId
    private var invitationStreams: [String: AsyncThrowingStream<[Invitation], Error>.Continuation] = [:]
    
    func createInvite(tripId: String, mode: InviteMode) async throws -> Invitation {
        let code = generateCode()
        let invitation = Invitation(
            tripId: tripId,
            code: code,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            createdBy: "mock-user-1",
            mode: mode
        )
        
        invitations[invitation.id] = invitation
        
        if tripInvitations[tripId] == nil {
            tripInvitations[tripId] = []
        }
        tripInvitations[tripId]?.append(invitation.id)
        
        codeToTripId[code] = tripId
        
        notifyInvitationsUpdate(tripId: tripId)
        
        return invitation
    }
    
    func revokeInvite(tripId: String, invitationId: String) async throws {
        guard let invitation = invitations[invitationId] else { return }
        
        // Remove code mapping
        codeToTripId.removeValue(forKey: invitation.code)
        
        // Remove invitation
        invitations.removeValue(forKey: invitationId)
        tripInvitations[tripId]?.removeAll { $0 == invitationId }
        
        notifyInvitationsUpdate(tripId: tripId)
    }
    
    func resolveCode(_ code: String) async throws -> String {
        guard let tripId = codeToTripId[code] else {
            throw InvitationMockError.invalidCode
        }
        
        // Check if invitation is expired
        let invitation = invitations.values.first { $0.code == code }
        if let invitation = invitation, invitation.isExpired {
            throw InvitationMockError.expiredCode
        }
        
        return tripId
    }
    
    func streamInvitations(tripId: String) -> AsyncThrowingStream<[Invitation], Error> {
        return AsyncThrowingStream { continuation in
            invitationStreams[tripId] = continuation
            
            // Send current invitations if they exist
            let currentInvitations = self.getInvitationsForTrip(tripId)
            continuation.yield(currentInvitations)
            
            continuation.onTermination = { _ in
                self.invitationStreams.removeValue(forKey: tripId)
            }
        }
    }
    
    private func generateCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    private func getInvitationsForTrip(_ tripId: String) -> [Invitation] {
        guard let invitationIds = tripInvitations[tripId] else { return [] }
        return invitationIds.compactMap { invitations[$0] }
    }
    
    private func notifyInvitationsUpdate(tripId: String) {
        let updatedInvitations = getInvitationsForTrip(tripId)
        invitationStreams[tripId]?.yield(updatedInvitations)
    }
    
    // Helper method for testing
    func seedMockData() {
        let mockInvitation = Invitation(
            tripId: "mock-trip-1",
            code: "ABC123",
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            createdBy: "mock-user-1",
            mode: .code
        )
        
        invitations[mockInvitation.id] = mockInvitation
        
        if tripInvitations[mockInvitation.tripId] == nil {
            tripInvitations[mockInvitation.tripId] = []
        }
        tripInvitations[mockInvitation.tripId]?.append(mockInvitation.id)
        
        codeToTripId[mockInvitation.code] = mockInvitation.tripId
    }
}

enum InvitationMockError: Error, LocalizedError {
    case invalidCode
    case expiredCode
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid invitation code"
        case .expiredCode:
            return "Invitation code has expired"
        }
    }
}
