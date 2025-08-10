import Foundation

struct MapBoxConfigTemplate {
    // MARK: - Configuration
    
    /// MapBox access token for API calls
    static var accessToken: String {
        // Priority order:
        // 1. Environment variable (most secure for CI/CD)
        // 2. Configuration file (for development)
        // 3. Hardcoded fallback (least secure, remove in production)
        
        if let envToken = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] {
            return envToken
        }
        
        #if DEBUG
        // Development configuration - replace with your token
        return "your_development_token_here"
        #else
        // Production - should always use environment variable
        fatalError("MAPBOX_ACCESS_TOKEN environment variable not set for production")
        #endif
    }
    
    /// MapBox style URL for the map
    static var mapStyleURL: String {
        return "mapbox://styles/mapbox/streets-v12"
    }
    
    /// Default map center coordinates (San Francisco)
    static var defaultCenter: (latitude: Double, longitude: Double) {
        return (37.7749, -122.4194)
    }
    
    /// Default map zoom level
    static var defaultZoom: Double {
        return 12.0
    }
    
    // MARK: - Validation
    
    /// Validates the access token format
    static var isTokenValid: Bool {
        let token = accessToken
        return !token.isEmpty && 
               token != "your_development_token_here" &&
               token.count > 20 // Basic validation
    }
    
    /// Returns a masked version of the token for logging
    static var maskedToken: String {
        let token = accessToken
        guard token.count > 8 else { return "***" }
        return "\(token.prefix(4))...\(token.suffix(4))"
    }
} 
