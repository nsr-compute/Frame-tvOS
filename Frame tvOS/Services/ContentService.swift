import SwiftUI
import SwiftData
import FrameKit
import CoreLocation


// MARK: - Content Service
@MainActor
@Observable
class ContentService {
    private let modelContext: ModelContext
    
    // Dynamic filters
    var selectedRegion: Region?
    var selectedCategories: Set<String> = []
    var searchQuery: String = ""
    var sortOption: SortOption = .newest
    
    // Content state
    var isLoading: Bool = false
    var error: ContentError?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Dynamic Content Fetching
    
    func fetchVideos(for region: Region? = nil, category: String? = nil, limit: Int? = nil) async -> [Video] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var predicate = #Predicate<Video> { video in
                video.isPublished == true
            }
            
            // Apply region filter
            if let region = region ?? selectedRegion {
                predicate = #Predicate<Video> { video in
                    video.isPublished == true && video.location == region.displayName
                }
            }
            
            // Apply category filter
            if let category = category, category != "All" {
                if let region = region ?? selectedRegion {
                    predicate = #Predicate<Video> { video in
                        video.isPublished == true &&
                        video.location == region.displayName &&
                        video.category == category
                    }
                } else {
                    predicate = #Predicate<Video> { video in
                        video.isPublished == true && video.category == category
                    }
                }
            }
            
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.sortBy = sortOption.sortDescriptors
            
            if let limit = limit {
                descriptor.fetchLimit = limit
            }
            
            let allVideos = try modelContext.fetch(descriptor)
            
            // Apply search filter in memory (since SwiftData predicates don't support localizedCaseInsensitiveContains)
            if !searchQuery.isEmpty {
                return allVideos.filter { video in
                    video.title.localizedCaseInsensitiveContains(searchQuery) ||
                    video.videoDescription.localizedCaseInsensitiveContains(searchQuery) ||
                    video.creator?.name.localizedCaseInsensitiveContains(searchQuery) == true
                }
            }
            
            return allVideos
        } catch {
            self.error = .fetchFailed(error)
            return []
        }
    }
    
    func fetchTrendingVideos(for region: Region? = nil, limit: Int = 20) async -> [Video] {
        let videos = await fetchVideos(for: region, limit: limit)
        return videos.sorted { $0.views > $1.views }
    }
    
    func fetchCreators(for region: Region? = nil, verified: Bool? = nil) async -> [Creator] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var predicate = #Predicate<Creator> { _ in true }
            
            if let region = region ?? selectedRegion {
                predicate = #Predicate<Creator> { creator in
                    creator.location == region.displayName
                }
            }
            
            if let verified = verified {
                predicate = #Predicate<Creator> { creator in
                    creator.isVerified == verified
                }
            }
            
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\Creator.subscriberCount, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            self.error = .fetchFailed(error)
            return []
        }
    }
    
    // MARK: - Content Categories
    
    func getAvailableCategories(for region: Region? = nil) async -> [String] {
        let videos = await fetchVideos(for: region)
        let categories = Set(videos.map { $0.category })
        return ["All"] + Array(categories).sorted()
    }
    
    // MARK: - Search and Filtering
    
    func searchContent(_ query: String, in region: Region? = nil) async -> ContentSearchResults {
        searchQuery = query
        
        // First get all videos and creators, then filter in memory
        async let allVideos = fetchVideos(for: region)
        async let allCreators = fetchCreators(for: region)
        
        let videos = await allVideos
        let creators = await allCreators
        
        let videoResults = videos.filter { video in
            video.title.localizedCaseInsensitiveContains(query) ||
            video.videoDescription.localizedCaseInsensitiveContains(query) ||
            video.creator?.name.localizedCaseInsensitiveContains(query) == true ||
            video.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        
        let creatorResults = creators.filter { creator in
            creator.name.localizedCaseInsensitiveContains(query) ||
            creator.bio.localizedCaseInsensitiveContains(query)
        }
        
        return ContentSearchResults(videos: videoResults, creators: creatorResults, query: query)
    }
    
    // MARK: - Dynamic Content Updates
    
    func refreshContent() async {
        // Simulate API refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // In real app, this would fetch from API
    }
    
    func updateVideoRegion(_ video: Video, to region: Region) {
        video.location = region.displayName
        try? modelContext.save()
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case mostViewed = "Most Viewed"
    case mostLiked = "Most Liked"
    case alphabetical = "A-Z"
    
    var sortDescriptors: [SortDescriptor<Video>] {
        switch self {
        case .newest:
            return [SortDescriptor(\Video.uploadDate, order: .reverse)]
        case .oldest:
            return [SortDescriptor(\Video.uploadDate, order: .forward)]
        case .mostViewed:
            return [SortDescriptor(\Video.views, order: .reverse)]
        case .mostLiked:
            return [SortDescriptor(\Video.likes, order: .reverse)]
        case .alphabetical:
            return [SortDescriptor(\Video.title, order: .forward)]
        }
    }
}

enum ContentError: LocalizedError {
    case fetchFailed(Error)
    case networkUnavailable
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch content: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

struct ContentSearchResults {
    let videos: [Video]
    let creators: [Creator]
    let query: String
    
    var isEmpty: Bool {
        videos.isEmpty && creators.isEmpty
    }
    
    var totalResults: Int {
        videos.count + creators.count
    }
}
