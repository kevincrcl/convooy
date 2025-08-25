import Foundation

struct Checkpoint: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: Coordinate
    let etaHint: Date?
    let order: Int
    
    init(id: String = UUID().uuidString, name: String, coordinate: Coordinate, etaHint: Date? = nil, order: Int) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.etaHint = etaHint
        self.order = order
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "coordinate": coordinate.asDictionary,
            "order": order
        ]
        if let etaHint = etaHint {
            dict["etaHint"] = Timestamp(date: etaHint)
        }
        return dict
    }
    
    static func from(_ dict: [String: Any]) -> Checkpoint? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let coordDict = dict["coordinate"] as? [String: Any],
              let coordinate = Coordinate.from(coordDict),
              let order = dict["order"] as? Int else {
            return nil
        }
        
        let etaHint: Date?
        if let timestamp = dict["etaHint"] as? Timestamp {
            etaHint = timestamp.dateValue()
        } else {
            etaHint = nil
        }
        
        return Checkpoint(id: id, name: name, coordinate: coordinate, etaHint: etaHint, order: order)
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
