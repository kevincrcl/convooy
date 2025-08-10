import Foundation
import MapboxMaps

class MapBoxService: ObservableObject {
    static let shared = MapBoxService()
    
    @Published var isConfigured = false
    @Published var configurationError: String?
    
    private init() {}
    
    func configureMapBox() {
        guard let accessToken = MapBoxConfig.accessToken else {
            configurationError = "No MapBox access token found"
            return
        }
        
        // Configure MapBox with the access token
        ResourceOptionsManager.default.resourceOptions.accessToken = accessToken
        
        // Set default options
        let options = ResourceOptions(accessToken: accessToken)
        ResourceOptionsManager.default.resourceOptions = options
        
        isConfigured = true
        print("✅ MapBox SDK configured successfully")
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