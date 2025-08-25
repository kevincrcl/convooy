import Foundation

struct Place: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: Coordinate
    let address: String?
    
    init(name: String, coordinate: Coordinate, address: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "coordinate": coordinate.asDictionary
        ]
        if let address = address {
            dict["address"] = address
        }
        return dict
    }
    
    static func from(_ dict: [String: Any]) -> Place? {
        guard let name = dict["name"] as? String,
              let coordDict = dict["coordinate"] as? [String: Any],
              let coordinate = Coordinate.from(coordDict) else {
            return nil
        }
        let address = dict["address"] as? String
        return Place(name: name, coordinate: coordinate, address: address)
    }
}
