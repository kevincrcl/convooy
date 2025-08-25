import Foundation

protocol ParticipantRepository {
    func addParticipant(_ participant: Participant) async throws
    func updateParticipant(_ participant: Participant) async throws
    func removeParticipant(id: String) async throws
    func streamParticipants(tripId: String) -> AsyncThrowingStream<[Participant], Error>
}

// Mock implementation for previews and testing
class MockParticipantRepository: ParticipantRepository {
    private var participants: [String: Participant] = [:]
    private var tripParticipants: [String: [String]] = [:] // tripId -> [participantIds]
    private var participantStreams: [String: AsyncThrowingStream<[Participant], Error>.Continuation] = [:]
    
    func addParticipant(_ participant: Participant) async throws {
        participants[participant.id] = participant
        
        if tripParticipants[participant.tripId] == nil {
            tripParticipants[participant.tripId] = []
        }
        tripParticipants[participant.tripId]?.append(participant.id)
        
        notifyParticipantsUpdate(tripId: participant.tripId)
    }
    
    func updateParticipant(_ participant: Participant) async throws {
        participants[participant.id] = participant
        notifyParticipantsUpdate(tripId: participant.tripId)
    }
    
    func removeParticipant(id: String) async throws {
        guard let participant = participants[id] else { return }
        
        participants.removeValue(forKey: id)
        tripParticipants[participant.tripId]?.removeAll { $0 == id }
        
        notifyParticipantsUpdate(tripId: participant.tripId)
    }
    
    func streamParticipants(tripId: String) -> AsyncThrowingStream<[Participant], Error> {
        return AsyncThrowingStream { continuation in
            participantStreams[tripId] = continuation
            
            // Send current participants if they exist
            let currentParticipants = self.getParticipantsForTrip(tripId)
            continuation.yield(currentParticipants)
            
            continuation.onTermination = { _ in
                self.participantStreams.removeValue(forKey: tripId)
            }
        }
    }
    
    private func getParticipantsForTrip(_ tripId: String) -> [Participant] {
        guard let participantIds = tripParticipants[tripId] else { return [] }
        return participantIds.compactMap { participants[$0] }
    }
    
    private func notifyParticipantsUpdate(tripId: String) {
        let updatedParticipants = getParticipantsForTrip(tripId)
        participantStreams[tripId]?.yield(updatedParticipants)
    }
    
    // Helper method for testing
    func seedMockData() {
        let mockParticipants = [
            Participant(
                tripId: "mock-trip-1",
                userId: "mock-user-1",
                role: .owner,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "mock-user-2",
                role: .driver,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "mock-user-3",
                role: .passenger,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "mock-user-4",
                role: .passenger,
                status: .invited
            )
        ]
        
        for participant in mockParticipants {
            participants[participant.id] = participant
            if tripParticipants[participant.tripId] == nil {
                tripParticipants[participant.tripId] = []
            }
            tripParticipants[participant.tripId]?.append(participant.id)
        }
    }
}
