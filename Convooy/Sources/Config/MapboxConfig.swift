import Foundation

// MARK: - Mapbox Configuration
struct MapboxConfig {
    // MARK: - API Configuration
    static let accessToken = "YOUR_MAPBOX_ACCESS_TOKEN" // TODO: Move to .xcconfig
    static let baseURL = "https://api.mapbox.com"
    
    // MARK: - Geocoding Configuration
    static let geocodingEndpoint = "\(baseURL)/geocoding/v5/mapbox.places"
    static let defaultCountry = "GB" // Default to UK
    static let searchLimit = 10
    static let searchDebounceMs = 300
    
    // MARK: - Supported Search Types
    static let supportedTypes = "poi,address,postcode,neighborhood,place"
    
    // MARK: - Routing Configuration (for future use)
    static let routingEndpoint = "\(baseURL)/directions/v5/mapbox/driving"
    
    // MARK: - Map Configuration (for future use)
    static let mapStyleURL = "mapbox://styles/mapbox/streets-v12"
    
    // MARK: - Validation
    static var isValid: Bool {
        return accessToken != "YOUR_MAPBOX_ACCESS_TOKEN" && !accessToken.isEmpty
    }
    
    // MARK: - Environment Check
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        // In a real app, you'd check environment variables or build settings
        return .production
        #endif
    }
    
    var mapboxToken: String {
        switch self {
        case .development:
            return "YOUR_DEV_MAPBOX_TOKEN"
        case .staging:
            return "YOUR_STAGING_MAPBOX_TOKEN"
        case .production:
            return "YOUR_PROD_MAPBOX_TOKEN"
        }
    }
}
