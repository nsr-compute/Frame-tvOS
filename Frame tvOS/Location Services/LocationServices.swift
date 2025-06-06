import Foundation
import SwiftUI
import FrameKit

// MARK: - Simplified Location Service (tvOS Optimized)
@MainActor
@Observable
class LocationService {
    // Current selected region
    var currentRegion: Region?
    var availableRegions: [Region] = []
    var isLocationEnabled: Bool = false
    
    init() {
        loadDefaultRegions()
        // Set default region
        currentRegion = availableRegions.first
    }
    
    // MARK: - Public Methods
    
    func selectRegion(_ region: Region) {
        currentRegion = region
    }
    
    func requestLocationPermission() {
        // For tvOS, we'll just mark as enabled since we're using manual selection
        isLocationEnabled = true
    }
    
    private func loadDefaultRegions() {
        availableRegions = [
            Region(city: "New York", state: "NY", country: "US"),
            Region(city: "Los Angeles", state: "CA", country: "US"),
            Region(city: "Chicago", state: "IL", country: "US"),
            Region(city: "Austin", state: "TX", country: "US"),
            Region(city: "Portland", state: "OR", country: "US"),
            Region(city: "Miami", state: "FL", country: "US"),
            Region(city: "Seattle", state: "WA", country: "US"),
            Region(city: "Denver", state: "CO", country: "US"),
            Region(city: "Atlanta", state: "GA", country: "US"),
            Region(city: "Boston", state: "MA", country: "US")
        ]
    }
    
    // MARK: - Region Management
    
    func nearbyRegions(within radius: Double = 100000) -> [Region] {
        // For tvOS, just return all available regions
        return availableRegions
    }
    
    func getPopularRegions() -> [Region] {
        // Return the most popular regions first
        return Array(availableRegions.prefix(6))
    }
}

// MARK: - Simplified Region Model
struct Region: Identifiable, Codable, Hashable, Equatable {
    let id = UUID()
    let city: String
    let state: String
    let country: String
    
    var displayName: String {
        "\(city), \(state)"
    }
    
    var fullName: String {
        "\(city), \(state), \(country)"
    }
    
    // MARK: - Initializers
    
    init(city: String, state: String, country: String) {
        self.city = city
        self.state = state
        self.country = country
    }
    
    // MARK: - Protocol Conformance
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case city, state, country
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(city)
        hasher.combine(state)
        hasher.combine(country)
    }
    
    // Equatable conformance
    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.city == rhs.city &&
               lhs.state == rhs.state &&
               lhs.country == rhs.country
    }
}

// MARK: - Video Location Extensions
extension Video {
    var region: Region? {
        // Parse the location string to create a Region
        let components = location.components(separatedBy: ", ")
        if components.count >= 2 {
            return Region(
                city: components[0],
                state: components[1],
                country: components.count > 2 ? components[2] : "US"
            )
        }
        return nil
    }
    
    func updateLocationFromRegion(_ region: Region) {
        self.location = region.displayName
    }
}
