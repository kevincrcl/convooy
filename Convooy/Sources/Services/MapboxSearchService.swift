import Foundation
import Combine

// MARK: - Mapbox Search Models
struct MapboxSearchResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let fullAddress: String
    let coordinate: Coordinate
    let type: SearchResultType
    let relevance: Double
    
    enum SearchResultType: String, CaseIterable {
        case address = "address"
        case poi = "poi"
        case postcode = "postcode"
        case neighborhood = "neighborhood"
        case city = "city"
        case country = "country"
        
        var displayName: String {
            switch self {
            case .address: return "Address"
            case .poi: return "Point of Interest"
            case .postcode: return "Postcode"
            case .neighborhood: return "Neighborhood"
            case .city: return "City"
            case .country: return "Country"
            }
        }
        
        var icon: String {
            switch self {
            case .address: return "house.fill"
            case .poi: return "mappin.circle.fill"
            case .postcode: return "envelope.fill"
            case .neighborhood: return "building.2.fill"
            case .city: return "building.fill"
            case .country: return "globe"
            }
        }
    }
}

// Import the Trip models to use the existing Coordinate
import Foundation

// MARK: - Search Service Protocol
protocol SearchServiceProtocol: ObservableObject {
    var searchText: String { get set }
    var searchResults: [MapboxSearchResult] { get set }
    var isSearching: Bool { get set }
    var errorMessage: String? { get set }
    
    func performSearch(query: String)
    func clearSearch()
}

// MARK: - Mapbox Search Service
class MapboxSearchService: SearchServiceProtocol {
    @Published var searchText = ""
    @Published var searchResults: [MapboxSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: Timer?
    
    // Mapbox configuration - these should come from environment variables or config
    private let accessToken = MapboxConfig.accessToken
    private let baseURL = MapboxConfig.geocodingEndpoint
    
    init() {
        setupSearchDebouncing()
    }
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(MapboxConfig.searchDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        guard query.count >= 2 else { return }
        
        isSearching = true
        errorMessage = nil
        
        // Build search URL with parameters
        var components = URLComponents(string: "\(baseURL)/\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "types", value: MapboxConfig.supportedTypes),
            URLQueryItem(name: "country", value: MapboxConfig.defaultCountry),
            URLQueryItem(name: "limit", value: "\(MapboxConfig.searchLimit)"),
            URLQueryItem(name: "autocomplete", value: "true")
        ]
        
        guard let url = components?.url else {
            isSearching = false
            errorMessage = "Invalid search URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                self?.parseSearchResults(data: data)
            }
        }.resume()
    }
    
    private func parseSearchResults(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let features = json?["features"] as? [[String: Any]] else {
                errorMessage = "Invalid response format"
                return
            }
            
            searchResults = features.compactMap { feature -> MapboxSearchResult? in
                guard let properties = feature["properties"] as? [String: Any],
                      let geometry = feature["geometry"] as? [String: Any],
                      let coordinates = geometry["coordinates"] as? [Double],
                      coordinates.count >= 2 else {
                    return nil
                }
                
                let name = properties["name"] as? String ?? properties["text"] as? String ?? "Unknown Location"
                let fullAddress = buildFullAddress(from: properties)
                let type = determineResultType(from: properties)
                let relevance = feature["relevance"] as? Double ?? 0.0
                
                return MapboxSearchResult(
                    name: name,
                    fullAddress: fullAddress,
                    coordinate: Coordinate(
                        latitude: coordinates[1], // Mapbox uses [longitude, latitude] order
                        longitude: coordinates[0]
                    ),
                    type: type,
                    relevance: relevance
                )
            }
            .sorted { $0.relevance > $1.relevance }
            
        } catch {
            errorMessage = "Failed to parse search results: \(error.localizedDescription)"
        }
    }
    
    private func buildFullAddress(from properties: [String: Any]) -> String {
        var addressComponents: [String] = []
        
        if let houseNumber = properties["housenumber"] as? String {
            addressComponents.append(houseNumber)
        }
        
        if let street = properties["street"] as? String {
            addressComponents.append(street)
        }
        
        if let postcode = properties["postcode"] as? String {
            addressComponents.append(postcode)
        }
        
        if let city = properties["city"] as? String {
            addressComponents.append(city)
        }
        
        if let country = properties["country"] as? String {
            addressComponents.append(country)
        }
        
        return addressComponents.isEmpty ? "No address available" : addressComponents.joined(separator: ", ")
    }
    
    private func determineResultType(from properties: [String: Any]) -> MapboxSearchResult.SearchResultType {
        if properties["postcode"] != nil {
            return .postcode
        } else if properties["poi"] != nil {
            return .poi
        } else if properties["address"] != nil {
            return .address
        } else if properties["neighborhood"] != nil {
            return .neighborhood
        } else if properties["city"] != nil {
            return .city
        } else {
            return .address // Default fallback
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
    }
}

// MARK: - Mock Implementation for Development
class MockMapboxSearchService: SearchServiceProtocol {
    @Published var searchText = ""
    @Published var searchResults: [MapboxSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    init() {
        // Mock implementation for development
    }
    
    func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        guard query.count >= 2 else { return }
        
        isSearching = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSearching = false
            
            // Generate mock results based on query
            let mockResults = self?.generateMockResults(for: query) ?? []
            self?.searchResults = mockResults
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
    }
    
    private func generateMockResults(for query: String) -> [MapboxSearchResult] {
        let lowerQuery = query.lowercased()
        var results: [MapboxSearchResult] = []
        
        // Mock postcode results
        if lowerQuery.contains("e3") || lowerQuery.contains("e1") || lowerQuery.contains("sw1") {
            results.append(MapboxSearchResult(
                name: "E3 5AB",
                fullAddress: "E3 5AB, London, UK",
                coordinate: Coordinate(latitude: 51.5074, longitude: -0.1278),
                type: .postcode,
                relevance: 0.95
            ))
        }
        
        // Mock POI results
        if lowerQuery.contains("coffee") || lowerQuery.contains("cafe") {
            results.append(MapboxSearchResult(
                name: "Starbucks Coffee",
                fullAddress: "123 High Street, London, E1 6AB, UK",
                coordinate: Coordinate(latitude: 51.5074, longitude: -0.1278),
                type: .poi,
                relevance: 0.9
            ))
        }
        
        // Mock address results
        if lowerQuery.contains("street") || lowerQuery.contains("road") {
            results.append(MapboxSearchResult(
                name: "123 High Street",
                fullAddress: "123 High Street, London, E1 6AB, UK",
                coordinate: Coordinate(latitude: 51.5074, longitude: -0.1278),
                type: .address,
                relevance: 0.85
            ))
        }
        
        // Generic results for any query
        if results.isEmpty {
            results.append(MapboxSearchResult(
                name: "\(query.capitalized) Location",
                fullAddress: "\(query.capitalized), London, UK",
                coordinate: Coordinate(latitude: 51.5074, longitude: -0.1278),
                type: .poi,
                relevance: 0.7
            ))
        }
        
        return results
    }
}
