import Foundation

struct RouteSummary: Codable, Identifiable, Equatable {
    let id = UUID()
    let polyline: String
    let distanceMeters: Int
    let durationSeconds: Int
    let computedAt: Date
    
    init(polyline: String, distanceMeters: Int, durationSeconds: Int, computedAt: Date = Date()) {
        self.polyline = polyline
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.computedAt = computedAt
    }
    
    // Computed properties
    var distanceKilometers: Double {
        return Double(distanceMeters) / 1000.0
    }
    
    var durationMinutes: Int {
        return durationSeconds / 60
    }
    
    var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(distanceMeters)m"
        } else {
            return String(format: "%.1fkm", distanceKilometers)
        }
    }
    
    var formattedDuration: String {
        if durationSeconds < 60 {
            return "\(durationSeconds)s"
        } else if durationMinutes < 60 {
            return "\(durationMinutes)m"
        } else {
            let hours = durationMinutes / 60
            let minutes = durationMinutes % 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        return [
            "polyline": polyline,
            "distanceMeters": distanceMeters,
            "durationSeconds": durationSeconds,
            "computedAt": Timestamp(date: computedAt)
        ]
    }
    
    static func from(_ dict: [String: Any]) -> RouteSummary? {
        guard let polyline = dict["polyline"] as? String,
              let distanceMeters = dict["distanceMeters"] as? Int,
              let durationSeconds = dict["durationSeconds"] as? Int,
              let timestamp = dict["computedAt"] as? Timestamp else {
            return nil
        }
        
        return RouteSummary(
            polyline: polyline,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            computedAt: timestamp.dateValue()
        )
    }
}

// Firestore Timestamp helper
private struct Timestamp {
    let date: Date
    
    init(date: Date) {
        self.date = date
    }
    
    func dateValue() -> Date {
        return date
    }
}
