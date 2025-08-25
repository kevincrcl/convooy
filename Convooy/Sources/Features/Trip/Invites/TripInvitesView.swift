import SwiftUI

struct TripInvitesView: View {
    let tripId: String
    @StateObject private var viewModel = TripInvitesViewModel()
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Invitation Links Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Invitation Links")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if viewModel.invitations.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "link.badge.plus")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("No invitations created")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("Create invitation links to share with others")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.invitations) { invitation in
                                InvitationCard(
                                    invitation: invitation,
                                    onRevoke: {
                                        Task {
                                            await viewModel.revokeInvite(invitationId: invitation.id)
                                        }
                                    },
                                    onShare: {
                                        shareURL = URL(string: "https://convooy.app/join/\(invitation.code)")
                                        showingShareSheet = true
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Create New Invitation Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create New Invitation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Button(action: createLinkInvitation) {
                            HStack {
                                Image(systemName: "link")
                                Text("Link Invitation")
                            }
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: createCodeInvitation) {
                            HStack {
                                Image(systemName: "number")
                                Text("Code Invitation")
                            }
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Participants Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Participants")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ParticipantList(
                        participants: viewModel.participants
                    ) { participant in
                        // Handle participant tap
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Invites")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private func createLinkInvitation() {
        Task {
            await viewModel.createInvitation(mode: .link)
        }
    }
    
    private func createCodeInvitation() {
        Task {
            await viewModel.createInvitation(mode: .code)
        }
    }
}

struct InvitationCard: View {
    let invitation: Invitation
    let onRevoke: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: invitation.mode == .link ? "link" : "number")
                            .foregroundColor(invitation.mode == .link ? .blue : .green)
                        
                        Text(invitation.mode.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Created by \(invitation.createdBy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRevoke) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Code/URL
            HStack {
                Text(invitation.code)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Expiry info
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Expires \(invitation.formattedExpiry)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if invitation.isExpired {
                    Text("EXPIRED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        TripInvitesView(tripId: "mock-trip-1")
    }
}
