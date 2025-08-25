import SwiftUI

struct TripVehiclesView: View {
    @StateObject private var viewModel: TripVehiclesViewModel
    @State private var showingAddVehicle = false
    @State private var selectedVehicle: Vehicle?
    @State private var showingEditVehicle = false
    
    init(tripId: String) {
        self._viewModel = StateObject(wrappedValue: TripVehiclesViewModel(tripId: tripId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transportation Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        SummaryMetricView(
                            icon: "car.fill",
                            value: "\(viewModel.vehicles.count)",
                            label: "Vehicles"
                        )
                        
                        SummaryMetricView(
                            icon: "person.3.fill",
                            value: "\(viewModel.totalCapacity)",
                            label: "Total Capacity"
                        )
                        
                        SummaryMetricView(
                            icon: "person.badge.plus",
                            value: "\(viewModel.totalAvailable)",
                            label: "Available Seats"
                        )
                    }
                }
                
                // Vehicles Section
                VehicleList(
                    vehicles: $viewModel.vehicles,
                    participants: viewModel.participants
                ) { vehicle in
                    Task {
                        await viewModel.addVehicle(vehicle)
                    }
                } onVehicleEdited: { vehicle in
                    selectedVehicle = vehicle
                    showingEditVehicle = true
                } onVehicleDeleted: { vehicle in
                    Task {
                        await viewModel.deleteVehicle(vehicle)
                    }
                }
                
                // Available Participants Section
                if !viewModel.availableParticipants.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Participants")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.availableParticipants) { participant in
                                AvailableParticipantRow(
                                    participant: participant,
                                    vehicles: viewModel.vehicles
                                ) { vehicleId in
                                    Task {
                                        await viewModel.assignParticipantToVehicle(participant, vehicleId: vehicleId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Vehicles")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddVehicle = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleSheet(
                vehicles: $viewModel.vehicles,
                onVehicleAdded: { vehicle in
                    Task {
                        await viewModel.addVehicle(vehicle)
                    }
                }
            )
        }
        .sheet(isPresented: $showingEditVehicle) {
            if let vehicle = selectedVehicle {
                EditVehicleSheet(
                    vehicle: vehicle,
                    onVehicleUpdated: { updatedVehicle in
                        Task {
                            await viewModel.updateVehicle(updatedVehicle)
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadData()
        }
    }
}

struct SummaryMetricView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AvailableParticipantRow: View {
    let participant: Participant
    let vehicles: [Vehicle]
    let onAssign: (String?) -> Void
    
    @State private var showingVehiclePicker = false
    
    var body: some View {
        HStack {
            // Participant info
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.userId)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(participant.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Assign button
            Button(action: { showingVehiclePicker = true }) {
                Text("Assign")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .actionSheet(isPresented: $showingVehiclePicker) {
            ActionSheet(
                title: Text("Assign to Vehicle"),
                message: Text("Choose a vehicle for \(participant.userId)"),
                buttons: [
                    .cancel(),
                    .destructive(Text("Remove Assignment")) {
                        onAssign(nil)
                    }
                ] + vehicles.map { vehicle in
                    .default(Text(vehicle.label)) {
                        onAssign(vehicle.id)
                    }
                }
            )
        }
    }
}

struct EditVehicleSheet: View {
    let vehicle: Vehicle
    let onVehicleUpdated: (Vehicle) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var label: String
    @State private var driverUserId: String
    @State private var capacity: Int
    @State private var notes: String
    
    init(vehicle: Vehicle, onVehicleUpdated: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onVehicleUpdated = onVehicleUpdated
        self._label = State(initialValue: vehicle.label)
        self._driverUserId = State(initialValue: vehicle.driverUserId)
        self._capacity = State(initialValue: vehicle.capacity)
        self._notes = State(initialValue: vehicle.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Details") {
                    TextField("Vehicle Label", text: $label)
                    TextField("Driver User ID", text: $driverUserId)
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...12)
                    TextField("Notes (Optional)", text: $notes)
                }
                
                Section {
                    Button("Update Vehicle") {
                        let updatedVehicle = Vehicle(
                            id: vehicle.id,
                            tripId: vehicle.tripId,
                            label: label,
                            driverUserId: driverUserId,
                            capacity: capacity,
                            notes: notes.isEmpty ? nil : notes,
                            passengerUserIds: vehicle.passengerUserIds
                        )
                        onVehicleUpdated(updatedVehicle)
                        dismiss()
                    }
                    .disabled(label.isEmpty || driverUserId.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TripVehiclesView(tripId: "mock-trip-1")
    }
}
