import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    let id = UUID()
    var name: String
    var stops: [TripStop]
    var createdAt: Date
    
    init(name: String, stops: [TripStop] = []) {
        self.name = name
        self.stops = stops
        self.createdAt = Date()
    }
}

struct TripStop: Identifiable, Codable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
    var order: Int
    
    init(name: String, coordinate: CLLocationCoordinate2D, order: Int) {
        self.name = name
        self.coordinate = coordinate
        self.order = order
    }
}

// MARK: - CLLocationCoordinate2D Codable conformance
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
} 