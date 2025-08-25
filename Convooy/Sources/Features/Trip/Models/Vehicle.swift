import Foundation

struct Vehicle: Codable, Identifiable, Equatable {
    let id: String
    let tripId: String
    let label: String
    let driverUserId: String
    let capacity: Int
    let notes: String?
    let passengerUserIds: [String]
    
    init(
        id: String = UUID().uuidString,
        tripId: String,
        label: String,
        driverUserId: String,
        capacity: Int,
        notes: String? = nil,
        passengerUserIds: [String] = []
    ) {
        self.id = id
        self.tripId = tripId
        self.label = label
        self.driverUserId = driverUserId
        self.capacity = capacity
        self.notes = notes
        self.passengerUserIds = passengerUserIds
    }
    
    // Computed properties
    var availableSeats: Int {
        return max(0, capacity - passengerUserIds.count - 1) // -1 for driver
    }
    
    var isFull: Bool {
        return availableSeats == 0
    }
    
    var occupancyPercentage: Double {
        let occupied = Double(passengerUserIds.count + 1) // +1 for driver
        return min(100.0, (occupied / Double(capacity)) * 100.0)
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "tripId": tripId,
            "label": label,
            "driverUserId": driverUserId,
            "capacity": capacity,
            "passengerUserIds": passengerUserIds
        ]
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
    
    static func from(_ dict: [String: Any]) -> Vehicle? {
        guard let id = dict["id"] as? String,
              let tripId = dict["tripId"] as? String,
              let label = dict["label"] as? String,
              let driverUserId = dict["driverUserId"] as? String,
              let capacity = dict["capacity"] as? Int,
              let passengerUserIds = dict["passengerUserIds"] as? [String] else {
            return nil
        }
        
        let notes = dict["notes"] as? String
        
        return Vehicle(
            id: id,
            tripId: tripId,
            label: label,
            driverUserId: driverUserId,
            capacity: capacity,
            notes: notes,
            passengerUserIds: passengerUserIds
        )
    }
}
