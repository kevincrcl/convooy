import SwiftUI

struct TripOverviewView: View {
    let tripId: String
    @StateObject private var viewModel: TripOverviewViewModel
    @State private var showingMarkReadyAlert = false
    
    init(tripId: String) {
        self.tripId = tripId
        self._viewModel = StateObject(wrappedValue: TripOverviewViewModel(tripId: tripId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Status Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trip Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        StatusBadge(status: viewModel.trip?.state ?? .draft)
                        
                        Spacer()
                        
                        if let trip = viewModel.trip, trip.canMarkReady {
                            Button(action: { showingMarkReadyAlert = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Ready")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Trip Details Section
                if let trip = viewModel.trip {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trip Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TripDetailsCard(trip: trip)
                    }
                }
                
                // Route Summary Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    RouteSummaryCard(
                        route: viewModel.trip?.route,
                        onRecompute: {
                            // Route recomputation handled by parent
                        },
                        isLoading: false
                    )
                }
                
                // Transportation Summary Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transportation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TransportationSummaryCard(
                        vehicles: viewModel.vehicles,
                        participants: viewModel.participants
                    )
                }
                
                // Leader Vehicle Section
                if let trip = viewModel.trip, !viewModel.vehicles.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Leader Vehicle")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LeaderVehicleSelector(
                            trip: trip,
                            vehicles: viewModel.vehicles,
                            onLeaderSelected: { vehicleId in
                                Task {
                                    await viewModel.setLeaderVehicle(vehicleId)
                                }
                            }
                        )
                    }
                }
                
                // Ready to Start Section
                if let trip = viewModel.trip {
                    RouteValidationView(
                        trip: trip,
                        onMarkReady: {
                            Task {
                                await viewModel.markTripReady()
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Trip Overview")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Mark Trip as Ready", isPresented: $showingMarkReadyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Ready") {
                Task {
                    await viewModel.markTripReady()
                }
            }
        } message: {
            Text("This will lock the trip structure and prevent further editing. Are you sure?")
        }
        .task {
            await viewModel.loadData()
        }
    }
}

struct StatusBadge: View {
    let status: TripState
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .draft:
            return .gray
        case .ready:
            return .green
        case .active:
            return .blue
        case .completed:
            return .purple
        case .cancelled:
            return .red
        }
    }
}

struct TripDetailsCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let notes = trip.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                if let origin = trip.origin {
                    TripLocationRow(
                        icon: "location.fill",
                        title: "Origin",
                        location: origin
                    )
                }
                
                TripLocationRow(
                    icon: "mappin.circle.fill",
                    title: "Destination",
                    location: trip.destination
                )
                
                if !trip.checkpoints.isEmpty {
                    CheckpointLocationRow(
                        icon: "mappin.and.ellipse",
                        title: "Checkpoints",
                        checkpoint: trip.checkpoints.first!,
                        additionalCount: trip.checkpoints.count - 1
                    )
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.visibility.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(trip.createdAt))
                        .font(.body)
                        .fontWeight(.medium)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct TripLocationRow: View {
    let icon: String
    let title: String
    let location: Place
    let additionalCount: Int?
    
    init(icon: String, title: String, location: Place, additionalCount: Int? = nil) {
        self.icon = icon
        self.title = title
        self.location = location
        self.additionalCount = additionalCount
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(location.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let address = location.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let additionalCount = additionalCount, additionalCount > 0 {
                    Text("+ \(additionalCount) more")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
    }
}

struct CheckpointLocationRow: View {
    let icon: String
    let title: String
    let checkpoint: Checkpoint
    let additionalCount: Int?
    
    init(icon: String, title: String, checkpoint: Checkpoint, additionalCount: Int? = nil) {
        self.icon = icon
        self.title = title
        self.checkpoint = checkpoint
        self.additionalCount = additionalCount
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(checkpoint.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let etaHint = checkpoint.etaHint {
                    Text("ETA: \(formatTime(etaHint))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let additionalCount = additionalCount, additionalCount > 0 {
                    Text("+ \(additionalCount) more")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TransportationSummaryCard: View {
    let vehicles: [Vehicle]
    let participants: [Participant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                SummaryMetricView(
                    icon: "car.fill",
                    value: "\(vehicles.count)",
                    label: "Vehicles"
                )
                
                SummaryMetricView(
                    icon: "person.3.fill",
                    value: "\(totalCapacity)",
                    label: "Total Capacity"
                )
                
                SummaryMetricView(
                    icon: "person.badge.plus",
                    value: "\(totalAvailable)",
                    label: "Available Seats"
                )
            }
            
            if !vehicles.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vehicle Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(vehicles) { vehicle in
                        HStack {
                            Text(vehicle.label)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(vehicle.passengerUserIds.count + 1)/\(vehicle.capacity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
    
    private var totalCapacity: Int {
        vehicles.reduce(0) { $0 + $1.capacity }
    }
    
    private var totalAvailable: Int {
        let totalOccupied = vehicles.reduce(0) { $0 + $1.passengerUserIds.count + 1 }
        return totalCapacity - totalOccupied
    }
}

struct LeaderVehicleSelector: View {
    let trip: Trip
    let vehicles: [Vehicle]
    let onLeaderSelected: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select the vehicle that will lead the convoy")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Leader Vehicle", selection: .constant(trip.leaderVehicleId ?? "none")) {
                Text("No Leader")
                    .tag("none")
                
                ForEach(vehicles) { vehicle in
                    Text(vehicle.label)
                        .tag(vehicle.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: trip.leaderVehicleId) { _, newValue in
                onLeaderSelected(newValue == "none" ? nil : newValue)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        TripOverviewView(tripId: "mock-trip-1")
    }
}
