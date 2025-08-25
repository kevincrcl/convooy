import SwiftUI

struct RouteSummaryCard: View {
    let route: RouteSummary?
    let onRecompute: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Route Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onRecompute) {
                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Recompute")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .disabled(isLoading)
                .buttonStyle(PlainButtonStyle())
            }
            
            if let route = route {
                // Route details
                HStack(spacing: 20) {
                    RouteMetricView(
                        icon: "ruler",
                        value: route.formattedDistance,
                        label: "Distance"
                    )
                    
                    RouteMetricView(
                        icon: "clock",
                        value: route.formattedDuration,
                        label: "Duration"
                    )
                    
                    RouteMetricView(
                        icon: "calendar",
                        value: formatDate(route.computedAt),
                        label: "Updated"
                    )
                }
                
                // Route preview placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Route Preview")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 60)
                        .overlay(
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                Text("Route visualization will appear here")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                        )
                }
            } else {
                // No route state
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No route computed")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Set destination and checkpoints to compute route")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(10)
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
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RouteMetricView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RouteValidationView: View {
    let trip: Trip
    let onMarkReady: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to Start?")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ValidationRow(
                    isValid: trip.destination != nil,
                    text: "Destination set"
                )
                
                ValidationRow(
                    isValid: !trip.checkpoints.isEmpty,
                    text: "Checkpoints added"
                )
                
                ValidationRow(
                    isValid: trip.route != nil,
                    text: "Route computed"
                )
            }
            
            if trip.canMarkReady {
                Button(action: onMarkReady) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Ready")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("Complete all requirements to mark trip as ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
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

struct ValidationRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .primary : .secondary)
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RouteSummaryCard(
            route: RouteSummary(
                polyline: "mock-polyline",
                distanceMeters: 25000,
                durationSeconds: 1800
            ),
            onRecompute: {},
            isLoading: false
        )
        
        RouteValidationView(
            trip: Trip(
                ownerId: "mock-user",
                title: "Test Trip",
                destination: Place(
                    name: "Test Destination",
                    coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)
                ),
                checkpoints: [
                    Checkpoint(name: "Test Checkpoint", coordinate: Coordinate(latitude: 37.8199, longitude: -122.4783), order: 0)
                ],
                route: RouteSummary(polyline: "mock", distanceMeters: 1000, durationSeconds: 600)
            ),
            onMarkReady: {}
        )
    }
    .padding()
}
