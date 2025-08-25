import Foundation

enum InviteMode: String, Codable, CaseIterable {
    case link = "link"
    case code = "code"
    
    var displayName: String {
        switch self {
        case .link: return "Link"
        case .code: return "Code"
        }
    }
}

struct Invitation: Codable, Identifiable, Equatable {
    let id: String
    let tripId: String
    let code: String
    let expiresAt: Date
    let createdBy: String
    let mode: InviteMode
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        tripId: String,
        code: String,
        expiresAt: Date,
        createdBy: String,
        mode: InviteMode,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.code = code
        self.expiresAt = expiresAt
        self.createdBy = createdBy
        self.mode = mode
        self.createdAt = createdAt
    }
    
    // Computed properties
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var formattedExpiry: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: expiresAt, relativeTo: Date())
    }
    
    // Firestore conversion helpers
    var asDictionary: [String: Any] {
        return [
            "id": id,
            "tripId": tripId,
            "code": code,
            "expiresAt": Timestamp(date: expiresAt),
            "createdBy": createdBy,
            "mode": mode.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    static func from(_ dict: [String: Any]) -> Invitation? {
        guard let id = dict["id"] as? String,
              let tripId = dict["tripId"] as? String,
              let code = dict["code"] as? String,
              let expiresAtTimestamp = dict["expiresAt"] as? Timestamp,
              let createdBy = dict["createdBy"] as? String,
              let modeRaw = dict["mode"] as? String,
              let mode = InviteMode(rawValue: modeRaw),
              let createdAtTimestamp = dict["createdAt"] as? Timestamp else {
            return nil
        }
        
        return Invitation(
            id: id,
            tripId: tripId,
            code: code,
            expiresAt: expiresAtTimestamp.dateValue(),
            createdBy: createdBy,
            mode: mode,
            createdAt: createdAtTimestamp.dateValue()
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
