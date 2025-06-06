import SwiftUI
import SwiftData
import FrameKit
import CoreLocation

// MARK: - Dynamic Content Section
struct DynamicContentSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let isLoading: Bool
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        isLoading: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isLoading = isLoading
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Spacer()
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 90)
            
            // Content
            if isLoading {
                LoadingContentView()
            } else {
                content()
            }
        }
    }
}

// MARK: - Dynamic Video Grid
struct DynamicVideoGrid: View {
    @Environment(ContentService.self) private var contentService
    
    let videos: [Video]
    let columns: Int
    let spacing: CGFloat
    
    init(videos: [Video], columns: Int = 3, spacing: CGFloat = 40) {
        self.videos = videos
        self.columns = columns
        self.spacing = spacing
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        if videos.isEmpty {
            EmptyContentView(message: "No videos found in this area")
        } else {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(videos, id: \.id) { video in
                    TVVideoCardView(video: video)
                }
            }
            .padding(.horizontal, 90)
        }
    }
}

// MARK: - Dynamic Horizontal Scroll
struct DynamicHorizontalScroll<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content
    
    init(
        items: [Item],
        spacing: CGFloat = 40,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if items.isEmpty {
            EmptyContentView(message: "No content available")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, 90)
            }
        }
    }
}

// MARK: - Location-Aware Home View
struct LocationAwareHomeView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(ContentService.self) private var contentService
    @Environment(\.modelContext) private var modelContext
    
    @State private var recentVideos: [Video] = []
    @State private var trendingVideos: [Video] = []
    @State private var featuredCreators: [Creator] = []
    @State private var categories: [String] = []
    
    var currentRegionName: String {
        contentService.selectedRegion?.displayName ?? "Your Area"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // Dynamic Header
                DynamicLocationHeader()
                
                // Hero Section
                if let heroVideo = recentVideos.first {
                    HeroVideoSectionView(video: heroVideo)
                }
                
                // Continue Watching (personalized)
                DynamicContentSection(
                    title: "Continue Watching",
                    isLoading: contentService.isLoading
                ) {
                    DynamicHorizontalScroll(items: Array(recentVideos.prefix(6))) { video in
                        TVVideoCardView(video: video)
                    }
                }
                
                // Recently Added in Region
                DynamicContentSection(
                    title: "Recently Added in \(currentRegionName)",
                    subtitle: "Fresh content from your area",
                    isLoading: contentService.isLoading
                ) {
                    DynamicHorizontalScroll(items: Array(recentVideos.prefix(8))) { video in
                        TVVideoCardView(video: video)
                    }
                }
                
                // Trending in Region
                DynamicContentSection(
                    title: "Trending in \(currentRegionName)",
                    subtitle: "What's popular near you",
                    isLoading: contentService.isLoading
                ) {
                    DynamicHorizontalScroll(items: Array(trendingVideos.prefix(8))) { video in
                        TVVideoCardView(video: video)
                    }
                }
                
                // Featured Local Creators
                if !featuredCreators.isEmpty {
                    DynamicContentSection(
                        title: "Featured Local Creators",
                        subtitle: "Creators making waves in \(currentRegionName)"
                    ) {
                        DynamicHorizontalScroll(items: Array(featuredCreators.prefix(6))) { creator in
                            TVCreatorCardView(creator: creator)
                        }
                    }
                }
                
                // Dynamic Categories
                DynamicContentSection(
                    title: "Browse by Category",
                    subtitle: "Discover content by interest"
                ) {
                    DynamicCategoryGrid(categories: categories)
                }
                
                // Region Quick Selector
                if locationService.nearbyRegions().count > 1 {
                    DynamicContentSection(
                        title: "Explore Nearby Areas"
                    ) {
                        RegionQuickSelector(maxRegions: 5)
                    }
                }
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 60)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .task {
            await loadContent()
        }
        .onChange(of: contentService.selectedRegion) { _, newRegion in
            Task {
                await loadContent()
            }
        }
    }
    
    private func loadContent() async {
        async let videos = contentService.fetchVideos(for: contentService.selectedRegion, limit: 20)
        async let trending = contentService.fetchTrendingVideos(for: contentService.selectedRegion, limit: 15)
        async let creators = contentService.fetchCreators(for: contentService.selectedRegion, verified: true)
        async let availableCategories = contentService.getAvailableCategories(for: contentService.selectedRegion)
        
        recentVideos = await videos
        trendingVideos = await trending
        featuredCreators = await creators
        categories = await availableCategories
    }
}

// MARK: - Dynamic Category Grid
struct DynamicCategoryGrid: View {
    let categories: [String]
    @Environment(ContentService.self) private var contentService
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 4)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 30) {
            ForEach(categories.filter { $0 != "All" }, id: \.self) { category in
                DynamicCategoryCard(category: category)
            }
        }
        .padding(.horizontal, 90)
    }
}

struct DynamicCategoryCard: View {
    let category: String
    @Environment(ContentService.self) private var contentService
    @Environment(\.isFocused) private var isFocused
    @State private var videoCount: Int = 0
    
    var categoryIcon: String {
        switch category {
        case "Documentary": return "doc.text.fill"
        case "Lifestyle": return "house.fill"
        case "Music": return "music.note"
        case "Food": return "fork.knife"
        case "Art": return "paintbrush.fill"
        case "Community": return "person.3.fill"
        case "Business": return "briefcase.fill"
        default: return "rectangle.grid.2x2"
        }
    }
    
    var body: some View {
        Button {
            selectCategory()
        } label: {
            VStack(spacing: 20) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(spacing: 4) {
                    Text(category)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if videoCount > 0 {
                        Text("\(videoCount) videos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(isFocused ? 0.2 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .task {
            await loadVideoCount()
        }
    }
    
    private func selectCategory() {
        contentService.selectedCategories = [category]
        // Navigate to category view or filter current content
    }
    
    private func loadVideoCount() async {
        let videos = await contentService.fetchVideos(for: contentService.selectedRegion, category: category)
        videoCount = videos.count
    }
}

// MARK: - Loading States
struct LoadingContentView: View {
    var body: some View {
        HStack(spacing: 40) {
            ForEach(0..<3) { _ in
                VStack(alignment: .leading, spacing: 15) {
                    // Thumbnail placeholder
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 400, height: 225)
                    
                    // Text placeholders
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(maxWidth: 200)
                    }
                }
                .frame(width: 400)
            }
        }
        .padding(.horizontal, 90)
        .opacity(0.6)
    }
}

struct EmptyContentView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh Content") {
                // Refresh action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error States
struct ErrorContentView: View {
    let error: ContentError
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dynamic Search View
struct DynamicSearchView: View {
    @Environment(ContentService.self) private var contentService
    @Environment(LocationService.self) private var locationService
    
    @State private var searchText = ""
    @State private var searchResults: ContentSearchResults?
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Search Header
            VStack(spacing: 20) {
                Text("Search")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Discover content in \(contentService.selectedRegion?.displayName ?? "your area")")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Search Bar
            searchBarView
            
            // Search Results
            if let results = searchResults {
                searchResultsView(results)
            } else if !searchText.isEmpty && !isSearching {
                EmptyContentView(message: "No results found for '\(searchText)'")
            } else if searchText.isEmpty {
                searchSuggestionsView
            }
            
            Spacer()
        }
        .padding(.horizontal, 90)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var searchBarView: some View {
        HStack(spacing: 20) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search videos, creators, or topics...", text: $searchText)
                    .font(.title2)
                    .foregroundColor(.white)
                    .onSubmit {
                        performSearch()
                    }
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .frame(maxWidth: 800)
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                searchResults = nil
            }
        }
    }
    
    @ViewBuilder
    private func searchResultsView(_ results: ContentSearchResults) -> some View {
        ScrollView {
            VStack(spacing: 40) {
                if !results.videos.isEmpty {
                    DynamicContentSection(
                        title: "Videos (\(results.videos.count))"
                    ) {
                        DynamicVideoGrid(videos: results.videos)
                    }
                }
                
                if !results.creators.isEmpty {
                    DynamicContentSection(
                        title: "Creators (\(results.creators.count))"
                    ) {
                        DynamicHorizontalScroll(items: results.creators) { creator in
                            TVCreatorCardView(creator: creator)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchSuggestionsView: some View {
        VStack(spacing: 30) {
            Text("Start typing to search for videos...")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Quick suggestions based on current region
            if let region = contentService.selectedRegion {
                DynamicContentSection(
                    title: "Popular in \(region.displayName)"
                ) {
                    // Show trending content as suggestions
                    Text("Loading suggestions...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 100)
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        Task {
            let results = await contentService.searchContent(searchText, in: contentService.selectedRegion)
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}
