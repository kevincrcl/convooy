import SwiftUI

struct CheckpointRow: View {
    let checkpoint: Checkpoint
    let isFirst: Bool
    let isLast: Bool
    let onDelete: () -> Void
    let onReorder: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Order indicator
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("\(checkpoint.order + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Checkpoint info
            VStack(alignment: .leading, spacing: 4) {
                Text(checkpoint.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let etaHint = checkpoint.etaHint {
                    Text("ETA: \(formatTime(etaHint))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CheckpointList: View {
    @Binding var checkpoints: [Checkpoint]
    let onCheckpointAdded: (Checkpoint) -> Void
    let onCheckpointDeleted: (Checkpoint) -> Void
    let onCheckpointsReordered: ([Checkpoint]) -> Void
    
    @State private var showingAddCheckpoint = false
    @State private var newCheckpointName = ""
    @State private var selectedPlace: Place?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Checkpoints")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingAddCheckpoint = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            if checkpoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No checkpoints added")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Add checkpoints to plan your route")
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
                    ForEach(Array(checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                        CheckpointRow(
                            checkpoint: checkpoint,
                            isFirst: index == 0,
                            isLast: index == checkpoints.count - 1
                        ) {
                            onCheckpointDeleted(checkpoint)
                        } onReorder: { newOrder in
                            var updatedCheckpoints = checkpoints
                            updatedCheckpoints.remove(at: index)
                            updatedCheckpoints.insert(checkpoint, at: newOrder)
                            onCheckpointsReordered(updatedCheckpoints)
                        }
                    }
                    .onMove { from, to in
                        checkpoints.move(fromOffsets: from, toOffset: to)
                        onCheckpointsReordered(checkpoints)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCheckpoint) {
            AddCheckpointSheet(
                checkpoints: $checkpoints,
                onCheckpointAdded: onCheckpointAdded
            )
        }
    }
}

struct AddCheckpointSheet: View {
    @Binding var checkpoints: [Checkpoint]
    let onCheckpointAdded: (Checkpoint) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedPlace: Place?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                PlaceSearchField(
                    searchText: $searchText,
                    selectedPlace: $selectedPlace,
                    placeholder: "Search for a checkpoint..."
                ) { place in
                    selectedPlace = place
                }
                
                if let place = selectedPlace {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Place:")
                            .font(.headline)
                        
                        Text(place.name)
                            .font(.body)
                        
                        if let address = place.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Add Checkpoint") {
                            let checkpoint = Checkpoint(
                                name: place.name,
                                coordinate: place.coordinate,
                                order: checkpoints.count
                            )
                            checkpoints.append(checkpoint)
                            onCheckpointAdded(checkpoint)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Checkpoint")
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
    CheckpointList(
        checkpoints: .constant([
            Checkpoint(name: "Golden Gate Bridge", coordinate: Coordinate(latitude: 37.8199, longitude: -122.4783), order: 0),
            Checkpoint(name: "Fisherman's Wharf", coordinate: Coordinate(latitude: 37.8080, longitude: -122.4177), order: 1)
        ])
    ) { checkpoint in
        print("Added: \(checkpoint.name)")
    } onCheckpointDeleted: { checkpoint in
        print("Deleted: \(checkpoint.name)")
    } onCheckpointsReordered: { checkpoints in
        print("Reordered: \(checkpoints.count) checkpoints")
    }
    .padding()
}
