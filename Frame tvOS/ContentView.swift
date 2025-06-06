// Frame TV - tvOS App (Updated with Modular Components)
// Import the shared framework
import SwiftUI
import SwiftData
import FrameKit
import CoreLocation

// MARK: - Main Content View (Updated)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var contentService: ContentService?
    @State private var videoService: VideoService?
    @State private var selectedTab: Tab = .home
    
    enum Tab: CaseIterable {
        case home, trending, creators, search
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .trending: return "Trending"
            case .creators: return "Creators"
            case .search: return "Search"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dynamic Home View
            LocationAwareHomeView()
                .tabItem { Text("Home") }
                .tag(Tab.home)
                .environment(appState)
                .environment(locationService)
                .environment(contentService ?? ContentService(modelContext: modelContext))
            
            // Dynamic Trending View
            DynamicTrendingView()
                .tabItem { Text("Trending") }
                .tag(Tab.trending)
                .environment(appState)
                .environment(locationService)
                .environment(contentService ?? ContentService(modelContext: modelContext))
            
            // Dynamic Creators View
            DynamicCreatorsView()
                .tabItem { Text("Creators") }
                .tag(Tab.creators)
                .environment(appState)
                .environment(locationService)
                .environment(contentService ?? ContentService(modelContext: modelContext))
            
            // Dynamic Search View
            DynamicSearchView()
                .tabItem { Text("Search") }
                .tag(Tab.search)
                .environment(appState)
                .environment(locationService)
                .environment(contentService ?? ContentService(modelContext: modelContext))
        }
        .task {
            await initializeServices()
        }
    }
    
    private func initializeServices() async {
        // Initialize services
        if contentService == nil {
            contentService = ContentService(modelContext: modelContext)
        }
        
        if videoService == nil {
            videoService = VideoService(modelContext: modelContext)
            await videoService?.createMockDataIfNeeded()
        }
        
        // Set up location service
        locationService.requestLocationPermission()
        
        // Set initial region if available
        if let defaultRegion = locationService.availableRegions.first {
            contentService?.selectedRegion = defaultRegion
            appState.selectedLocation = defaultRegion.displayName
        }
    }
}

// MARK: - Dynamic Trending View
struct DynamicTrendingView: View {
    @Environment(ContentService.self) private var contentService
    @Environment(LocationService.self) private var locationService
    
    @State private var trendingVideos: [Video] = []
    @State private var timeFilter: TrendingTimeFilter = .today
    
    enum TrendingTimeFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
    }
    
    var currentRegionName: String {
        contentService.selectedRegion?.displayName ?? "Your Area"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header with Region
                VStack(spacing: 20) {
                    Text("Trending in \(currentRegionName)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Time Filter
                    Picker("Time Period", selection: $timeFilter) {
                        ForEach(TrendingTimeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 600)
                }
                .padding(.top, 40)
                
                // Trending Content
                DynamicContentSection(
                    title: "Most Popular",
                    subtitle: "What everyone's watching in \(currentRegionName)",
                    isLoading: contentService.isLoading
                ) {
                    DynamicVideoGrid(videos: trendingVideos, columns: 3)
                }
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .task {
            await loadTrendingContent()
        }
        .onChange(of: contentService.selectedRegion) { _, _ in
            Task { await loadTrendingContent() }
        }
        .onChange(of: timeFilter) { _, _ in
            Task { await loadTrendingContent() }
        }
    }
    
    private func loadTrendingContent() async {
        trendingVideos = await contentService.fetchTrendingVideos(
            for: contentService.selectedRegion,
            limit: 24
        )
    }
}

// MARK: - Dynamic Creators View
struct DynamicCreatorsView: View {
    @Environment(ContentService.self) private var contentService
    @Environment(LocationService.self) private var locationService
    
    @State private var allCreators: [Creator] = []
    @State private var verifiedCreators: [Creator] = []
    @State private var showVerifiedOnly = false
    
    var currentRegionName: String {
        contentService.selectedRegion?.displayName ?? "Your Area"
    }
    
    var displayedCreators: [Creator] {
        showVerifiedOnly ? verifiedCreators : allCreators
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Text("Creators in \(currentRegionName)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Filter Toggle
                    Toggle("Verified Only", isOn: $showVerifiedOnly)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                }
                .padding(.top, 40)
                
                // Creator Grid
                DynamicContentSection(
                    title: showVerifiedOnly ? "Verified Creators" : "All Creators",
                    subtitle: "\(displayedCreators.count) creators in \(currentRegionName)",
                    isLoading: contentService.isLoading
                ) {
                    if displayedCreators.isEmpty {
                        EmptyContentView(message: "No creators found in this area")
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 40) {
                            ForEach(displayedCreators, id: \.id) { creator in
                                TVCreatorCardView(creator: creator)
                            }
                        }
                        .padding(.horizontal, 90)
                    }
                }
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .task {
            await loadCreators()
        }
        .onChange(of: contentService.selectedRegion) { _, _ in
            Task { await loadCreators() }
        }
    }
    
    private func loadCreators() async {
        async let all = contentService.fetchCreators(for: contentService.selectedRegion)
        async let verified = contentService.fetchCreators(for: contentService.selectedRegion, verified: true)
        
        allCreators = await all
        verifiedCreators = await verified
    }
}

// MARK: - Usage Example Integration
struct ExampleUsage: View {
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var contentService: ContentService?
    
    var body: some View {
        VStack {
            if let contentService = contentService {
                // Show current region
                if let region = contentService.selectedRegion {
                    Text("Current Region: \(region.displayName)")
                        .font(.title)
                }
                
                // Show nearby regions
                Text("Nearby Areas:")
                ForEach(locationService.nearbyRegions(), id: \.id) { region in
                    Button(region.displayName) {
                        contentService.selectedRegion = region
                    }
                }
            }
        }
        .onAppear {
            if contentService == nil {
                contentService = ContentService(modelContext: modelContext)
            }
            
            // Request location access
            locationService.requestLocationPermission()
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(ModelContainer.shared)
    }
}
#endif
