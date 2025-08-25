import SwiftUI

struct ParticipantAvatarRow: View {
    let participant: Participant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 40, height: 40)
                    
                    Text(avatarInitials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Participant info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(participant.userId)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(participant.role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(roleColor.opacity(0.1))
                            .foregroundColor(roleColor)
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text(participant.status.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if participant.isAssignedToVehicle {
                            Image(systemName: "car.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var avatarColor: Color {
        switch participant.role {
        case .owner:
            return .purple
        case .driver:
            return .blue
        case .passenger:
            return .green
        case .viewer:
            return .gray
        }
    }
    
    private var roleColor: Color {
        switch participant.role {
        case .owner:
            return .purple
        case .driver:
            return .blue
        case .passenger:
            return .green
        case .viewer:
            return .gray
        }
    }
    
    private var avatarInitials: String {
        let components = participant.userId.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

struct ParticipantList: View {
    let participants: [Participant]
    let onParticipantTapped: (Participant) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Participants")
                .font(.headline)
                .fontWeight(.semibold)
            
            if participants.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No participants yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Participants will appear here once they join")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(participants) { participant in
                        ParticipantAvatarRow(participant: participant) {
                            onParticipantTapped(participant)
                        }
                    }
                }
            }
        }
    }
}

struct ParticipantStatusBadge: View {
    let status: ParticipantStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .invited:
            return .orange
        case .joined:
            return .green
        case .declined:
            return .red
        }
    }
}

#Preview {
    ParticipantList(
        participants: [
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
            )
        ]
    ) { participant in
        print("Tapped: \(participant.userId)")
    }
    .padding()
}
