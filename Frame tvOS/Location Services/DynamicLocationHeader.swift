import SwiftUI
import SwiftData
import FrameKit
import CoreLocation

// MARK: - Dynamic Location Header Component (Simplified for tvOS)
struct DynamicLocationHeader: View {
    @Environment(LocationService.self) private var locationService
    @Environment(ContentService.self) private var contentService
    @Environment(AppState.self) private var appState
    
    @FocusState private var locationFocused: Bool
    @State private var showLocationPicker = false
    
    var body: some View {
        HStack {
            // App Logo/Title
            HStack(spacing: 20) {
                Image(systemName: "tv.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Frame")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Dynamic Location Selector
            locationSelectorView
        }
    }
    
    @ViewBuilder
    private var locationSelectorView: some View {
        Menu {
            locationMenuContent
        } label: {
            HStack(spacing: 15) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentLocationText)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if let region = contentService.selectedRegion {
                        Text(region.fullName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .focused($locationFocused)
    }
    
    @ViewBuilder
    private var locationMenuContent: some View {
        // Current Location Section
        if let currentRegion = locationService.currentRegion {
            Section("Current Location") {
                Button(action: { selectRegion(currentRegion) }) {
                    Label(currentRegion.displayName, systemImage: "location.fill")
                }
            }
        }
        
        // Popular Regions Section
        let popularRegions = locationService.getPopularRegions()
        if !popularRegions.isEmpty {
            Section("Popular Areas") {
                ForEach(popularRegions, id: \.id) { region in
                    Button(action: { selectRegion(region) }) {
                        HStack {
                            Text(region.displayName)
                            if region.id == contentService.selectedRegion?.id {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        
        // All Available Regions
        Section("All Locations") {
            ForEach(locationService.availableRegions, id: \.id) { region in
                Button(action: { selectRegion(region) }) {
                    HStack {
                        Text(region.displayName)
                        if region.id == contentService.selectedRegion?.id {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var currentLocationText: String {
        if let selectedRegion = contentService.selectedRegion {
            return selectedRegion.displayName
        } else if let currentRegion = locationService.currentRegion {
            return currentRegion.displayName
        } else {
            return "Select Location"
        }
    }
    
    private func selectRegion(_ region: Region) {
        // Update services
        contentService.selectedRegion = region
        appState.selectedLocation = region.displayName
        locationService.selectRegion(region)
        
        // Trigger content refresh
        Task {
            await contentService.refreshContent()
        }
    }
}

// MARK: - Location Status Indicator (Simplified)
struct LocationStatusIndicator: View {
    @Environment(LocationService.self) private var locationService
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("Manual Selection")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Region Quick Selector (Simplified)
struct RegionQuickSelector: View {
    @Environment(LocationService.self) private var locationService
    @Environment(ContentService.self) private var contentService
    
    let maxRegions: Int
    
    init(maxRegions: Int = 5) {
        self.maxRegions = maxRegions
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(locationService.getPopularRegions().prefix(maxRegions), id: \.id) { region in
                    RegionChip(region: region)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RegionChip: View {
    let region: Region
    @Environment(ContentService.self) private var contentService
    @Environment(LocationService.self) private var locationService
    @Environment(\.isFocused) private var isFocused
    
    var isSelected: Bool {
        region.id == contentService.selectedRegion?.id
    }
    
    var body: some View {
        Button(region.displayName) {
            contentService.selectedRegion = region
            locationService.selectRegion(region)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.white.opacity(0.1))
        .foregroundColor(isSelected ? .white : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
