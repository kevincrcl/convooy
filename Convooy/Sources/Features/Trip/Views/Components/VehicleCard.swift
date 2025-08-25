import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    let participants: [Participant]
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.label)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Driver: \(vehicle.driverUserId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Capacity and occupancy
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Capacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(vehicle.capacity)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(vehicle.availableSeats)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(vehicle.availableSeats > 0 ? .green : .red)
                }
            }
            
            // Occupancy bar
            ProgressView(value: vehicle.occupancyPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: vehicle.isFull ? .red : .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Passengers
            if !vehicle.passengerUserIds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Passengers")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(vehicle.passengerUserIds, id: \.self) { userId in
                        if let participant = participants.first(where: { $0.userId == userId }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text(participant.userId)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(participant.role.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Notes
            if let notes = vehicle.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
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

struct VehicleList: View {
    @Binding var vehicles: [Vehicle]
    let participants: [Participant]
    let onVehicleAdded: (Vehicle) -> Void
    let onVehicleEdited: (Vehicle) -> Void
    let onVehicleDeleted: (Vehicle) -> Void
    
    @State private var showingAddVehicle = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vehicles")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingAddVehicle = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            if vehicles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No vehicles added")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Add vehicles to organize transportation")
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
                    ForEach(vehicles) { vehicle in
                        VehicleCard(
                            vehicle: vehicle,
                            participants: participants
                        ) {
                            onVehicleEdited(vehicle)
                        } onDelete: {
                            onVehicleDeleted(vehicle)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleSheet(
                vehicles: $vehicles,
                onVehicleAdded: onVehicleAdded
            )
        }
    }
}

struct AddVehicleSheet: View {
    @Binding var vehicles: [Vehicle]
    let onVehicleAdded: (Vehicle) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var driverUserId = ""
    @State private var capacity = 4
    @State private var notes = ""
    
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
                    Button("Add Vehicle") {
                        let vehicle = Vehicle(
                            tripId: "temp-trip-id", // Will be set by parent
                            label: label,
                            driverUserId: driverUserId,
                            capacity: capacity,
                            notes: notes.isEmpty ? nil : notes
                        )
                        vehicles.append(vehicle)
                        onVehicleAdded(vehicle)
                        dismiss()
                    }
                    .disabled(label.isEmpty || driverUserId.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Vehicle")
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
    VehicleList(
        vehicles: .constant([
            Vehicle(
                tripId: "mock-trip-1",
                label: "Alex's Car",
                driverUserId: "alex",
                capacity: 4,
                notes: "SUV with good trunk space"
            )
        ]),
        participants: [
            Participant(
                tripId: "mock-trip-1",
                userId: "alex",
                role: .driver,
                status: .joined
            ),
            Participant(
                tripId: "mock-trip-1",
                userId: "sarah",
                role: .passenger,
                status: .joined
            )
        ]
    ) { vehicle in
        print("Added: \(vehicle.label)")
    } onVehicleEdited: { vehicle in
        print("Edited: \(vehicle.label)")
    } onVehicleDeleted: { vehicle in
        print("Deleted: \(vehicle.label)")
    }
    .padding()
}
