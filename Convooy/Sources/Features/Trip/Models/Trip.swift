import Foundation

enum TripState: String, Codable, CaseIterable {
    case draft = "draft"
    case ready = "ready"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .ready: return "Ready"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .draft, .ready: return true
        case .active, .completed, .cancelled: return false
        }
    }
    
    var canStart: Bool {
        return self == .ready
    }
}

enum TripVisibility: String, Codable, CaseIterable {
    case `private` = "private"
    case inviteOnly = "invite_only"
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .inviteOnly: return "Invite Only"
        }
    }
}

struct Trip: Codable, Identifiable, Equatable {
    let id: String
    let ownerId: String
    let title: String
    let notes: String?
    let state: TripState
    let origin: Place?
    let destination: Place
    let checkpoints: [Checkpoint]
    let route: RouteSummary?
    let leaderVehicleId: String?
    let visibility: TripVisibility
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        ownerId: String,
        title: String,
        notes: String? = nil,
        state: TripState = .draft,
        origin: Place? = nil,
        destination: Place,
        checkpoints: [Checkpoint] = [],
        route: RouteSummary? = nil,
        leaderVehicleId: String? = nil,
        visibility: TripVisibility = .private,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.notes = notes
        self.state = state
        self.origin = origin
        self.destination = destination
        self.checkpoints = checkpoints
        self.route = route
        self.leaderVehicleId = leaderVehicleId
        self.visibility = visibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var isEditable: Bool {
        return state.canEdit
    }
    
    var canMarkReady: Bool {
        guard state == .draft else { return false }
        return destination != nil && !checkpoints.isEmpty && route != nil
    }
    
    var totalStops: Int {
        var count = 1 // destination
        if origin != nil { count += 1 }
        count += checkpoints.count
        return count
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "ownerId": ownerId,
            "title": title,
            "state": state.rawValue,
            "destination": destination.asDictionary,
            "checkpoints": checkpoints.map { $0.asDictionary },
            "visibility": visibility.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let notes = notes {
            dict["notes"] = notes
        }
        if let origin = origin {
            dict["origin"] = origin.asDictionary
        }
        if let route = route {
            dict["route"] = route.asDictionary
        }
        if let leaderVehicleId = leaderVehicleId {
            dict["leaderVehicleId"] = leaderVehicleId
        }
        
        return dict
    }
    
    static func from(_ dict: [String: Any]) -> Trip? {
        guard let id = dict["id"] as? String,
              let ownerId = dict["ownerId"] as? String,
              let title = dict["title"] as? String,
              let stateRaw = dict["state"] as? String,
              let state = TripState(rawValue: stateRaw),
              let destDict = dict["destination"] as? [String: Any],
              let destination = Place.from(destDict),
              let checkpointsArray = dict["checkpoints"] as? [[String: Any]],
              let visibilityRaw = dict["visibility"] as? String,
              let visibility = TripVisibility(rawValue: visibilityRaw),
              let createdAtTimestamp = dict["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dict["updatedAt"] as? Timestamp else {
            return nil
        }
        
        let notes = dict["notes"] as? String
        
        let origin: Place?
        if let originDict = dict["origin"] as? [String: Any] {
            origin = Place.from(originDict)
        } else {
            origin = nil
        }
        
        let checkpoints = checkpointsArray.compactMap { Checkpoint.from($0) }
        
        let route: RouteSummary?
        if let routeDict = dict["route"] as? [String: Any] {
            route = RouteSummary.from(routeDict)
        } else {
            route = nil
        }
        
        let leaderVehicleId = dict["leaderVehicleId"] as? String
        
        return Trip(
            id: id,
            ownerId: ownerId,
            title: title,
            notes: notes,
            state: state,
            origin: origin,
            destination: destination,
            checkpoints: checkpoints,
            route: route,
            leaderVehicleId: leaderVehicleId,
            visibility: visibility,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
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
