import Foundation

enum ParticipantRole: String, Codable, CaseIterable {
    case owner = "owner"
    case driver = "driver"
    case passenger = "passenger"
    case viewer = "viewer"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .driver: return "Driver"
        case .passenger: return "Passenger"
        case .viewer: return "Viewer"
        }
    }
    
    var canEditTrip: Bool {
        switch self {
        case .owner: return true
        case .driver, .passenger, .viewer: return false
        }
    }
    
    var canEditVehicle: Bool {
        switch self {
        case .owner, .driver: return true
        case .passenger, .viewer: return false
        }
    }
}

enum ParticipantStatus: String, Codable, CaseIterable {
    case invited = "invited"
    case joined = "joined"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .invited: return "Invited"
        case .joined: return "Joined"
        case .declined: return "Declined"
        }
    }
    
    var isActive: Bool {
        return self == .joined
    }
}

struct Participant: Codable, Identifiable, Equatable {
    let id: String
    let tripId: String
    let userId: String
    let role: ParticipantRole
    let vehicleId: String?
    let status: ParticipantStatus
    let joinedAt: Date?
    let declinedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        tripId: String,
        userId: String,
        role: ParticipantRole,
        vehicleId: String? = nil,
        status: ParticipantStatus = .invited,
        joinedAt: Date? = nil,
        declinedAt: Date? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.userId = userId
        self.role = role
        self.vehicleId = vehicleId
        self.status = status
        self.joinedAt = joinedAt
        self.declinedAt = declinedAt
    }
    
    // Computed properties
    var isAssignedToVehicle: Bool {
        return vehicleId != nil
    }
    
    var canBeAssignedToVehicle: Bool {
        return status == .joined && role != .owner
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "tripId": tripId,
            "userId": userId,
            "role": role.rawValue,
            "status": status.rawValue
        ]
        
        if let vehicleId = vehicleId {
            dict["vehicleId"] = vehicleId
        }
        if let joinedAt = joinedAt {
            dict["joinedAt"] = Timestamp(date: joinedAt)
        }
        if let declinedAt = declinedAt {
            dict["declinedAt"] = Timestamp(date: declinedAt)
        }
        
        return dict
    }
    
    static func from(_ dict: [String: Any]) -> Participant? {
        guard let id = dict["id"] as? String,
              let tripId = dict["tripId"] as? String,
              let userId = dict["userId"] as? String,
              let roleRaw = dict["role"] as? String,
              let role = ParticipantRole(rawValue: roleRaw),
              let statusRaw = dict["status"] as? String,
              let status = ParticipantStatus(rawValue: statusRaw) else {
            return nil
        }
        
        let vehicleId = dict["vehicleId"] as? String
        
        let joinedAt: Date?
        if let timestamp = dict["joinedAt"] as? Timestamp {
            joinedAt = timestamp.dateValue()
        } else {
            joinedAt = nil
        }
        
        let declinedAt: Date?
        if let timestamp = dict["declinedAt"] as? Timestamp {
            declinedAt = timestamp.dateValue()
        } else {
            declinedAt = nil
        }
        
        return Participant(
            id: id,
            tripId: tripId,
            userId: userId,
            role: role,
            vehicleId: vehicleId,
            status: status,
            joinedAt: joinedAt,
            declinedAt: declinedAt
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
