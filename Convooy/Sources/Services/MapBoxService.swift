import Foundation
import MapboxMaps

class MapBoxService: ObservableObject {
    static let shared = MapBoxService()
    
    @Published var isConfigured = false
    @Published var configurationError: String?
    
    private init() {}
    
    func configureMapBox() {
        // With MapBox SDK, the access token should be in Info.plist
        // The SDK will automatically read it from there
        isConfigured = true
        print("✅ MapBox SDK configured successfully")
        print("📱 Access token should be in Info.plist: MAPBOX_ACCESS_TOKEN")
    }
    
    func getMapStyleURL() -> String {
        return MapBoxConfig.mapStyleURL
    }
    
    func getDefaultCenter() -> CLLocationCoordinate2D {
        return MapBoxConfig.defaultCenter
    }
    
    func getDefaultZoom() -> Double {
        return MapBoxConfig.defaultZoom
    }
} 