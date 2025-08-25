import Foundation

struct Coordinate: Codable, Equatable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        return [
            "latitude": latitude,
            "longitude": longitude
        ]
    }
    
    static func from(_ dict: [String: Any]) -> Coordinate? {
        guard let lat = dict["latitude"] as? Double,
              let lng = dict["longitude"] as? Double else {
            return nil
        }
        return Coordinate(latitude: lat, longitude: lng)
    }
}
