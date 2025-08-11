import Foundation
import MapboxMaps

class MapBoxService: ObservableObject {
    static let shared = MapBoxService()
    
    private var accessToken: String {
        // Read from Info.plist using MBXAccessToken key
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let token = plist["MBXAccessToken"] as? String else {
            fatalError("MBXAccessToken not found in Info.plist. Please add your MapBox access token to Info.plist with key 'MBXAccessToken'")
        }
        return token
    }
    
    private init() {
        // Initialize MapBox with access token from Info.plist
        MapboxOptions.accessToken = accessToken
    }
    
    func getMapOptions() -> MapInitOptions {
        // Use the simplest initialization possible
        return MapInitOptions()
    }
}
