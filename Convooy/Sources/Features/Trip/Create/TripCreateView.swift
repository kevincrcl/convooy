import SwiftUI

struct TripCreateView: View {
    @StateObject private var viewModel = TripCreateViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Trip Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trip Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            TextField("Trip Title", text: $viewModel.title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    // Origin Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Origin (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        PlaceSearchField(
                            searchText: .constant(""),
                            selectedPlace: $viewModel.origin,
                            placeholder: "Search for starting point..."
                        ) { place in
                            viewModel.origin = place
                            // Recompute route if we have destination and checkpoints
                            if viewModel.canComputeRoute {
                                Task {
                                    await viewModel.computeRoute()
                                }
                            }
                        }
                    }
                    
                    // Destination Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Destination")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        PlaceSearchField(
                            searchText: .constant(""),
                            selectedPlace: $viewModel.destination,
                            placeholder: "Search for destination..."
                        ) { place in
                            viewModel.destination = place
                            // Recompute route if we have checkpoints
                            if viewModel.canComputeRoute {
                                Task {
                                    await viewModel.computeRoute()
                                }
                            }
                        }
                    }
                    
                    // Checkpoints Section
                    CheckpointList(
                        checkpoints: $viewModel.checkpoints,
                        onCheckpointAdded: { checkpoint in
                            viewModel.addCheckpoint(checkpoint)
                        },
                        onCheckpointDeleted: { checkpoint in
                            viewModel.removeCheckpoint(checkpoint)
                        },
                        onCheckpointsReordered: { newOrder in
                            viewModel.reorderCheckpoints(newOrder)
                        }
                    )
                    
                    // Route Summary Section
                    RouteSummaryCard(
                        route: viewModel.route,
                        onRecompute: {
                            Task {
                                await viewModel.computeRoute()
                            }
                        },
                        isLoading: viewModel.isLoading
                    )
                    
                    // Visibility Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Visibility")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Visibility", selection: $viewModel.visibility) {
                            ForEach(TripVisibility.allCases, id: \.self) { visibility in
                                Text(visibility.displayName)
                                    .tag(visibility)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Save Button
                    Button(action: saveTrip) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("Save Draft")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.canSave ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoading)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Trip Created", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your trip has been saved as a draft.")
            }
        }
    }
    
    private func saveTrip() {
        Task {
            if let _ = await viewModel.saveTrip() {
                showingSaveSuccess = true
            }
        }
    }
}

#Preview {
    TripCreateView()
}
