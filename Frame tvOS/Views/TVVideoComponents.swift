import SwiftUI
import FrameKit

// MARK: - TV Video Card
struct TVVideoCardView: View {
    let video: Video
    @Environment(\.isFocused) private var isFocused
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Thumbnail
            ZStack {
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                }
                .frame(width: 400, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                // Duration Badge
                VStack {
                    HStack {
                        Spacer()
                        Text(video.formattedDuration)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                }
                .padding(15)
            }
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(radius: isFocused ? 20 : 5)
            .animation(.easeInOut(duration: 0.3), value: isFocused)
            
            // Video Info
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: 400, alignment: .leading)
                
                if let creator = video.creator {
                    HStack {
                        Text(creator.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if creator.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    Label("\(video.views)", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(video.likes)", systemImage: "heart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(video.formattedUploadDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 400)
        .onTapGesture {
            playVideo()
        }
    }
    
    private func playVideo() {
        let videoService = VideoService(modelContext: modelContext)
        videoService.incrementViews(for: video, user: appState.currentUser)
        appState.currentPlayingVideo = video
        
        // TODO: Present video player
        print("Playing video: \(video.title)")
    }
}

// MARK: - TV Creator Card
struct TVCreatorCardView: View {
    let creator: Creator
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: creator.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            VStack(spacing: 8) {
                HStack {
                    Text(creator.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if creator.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                Text("\(creator.formattedSubscriberCount) subscribers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(creator.videoCount) videos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Follow") {
                // Follow action
            }
            .buttonStyle(.borderedProminent)
            #if !os(tvOS)
            .controlSize(.large)
            #endif
        }
        .frame(width: 200)
    }
}

// MARK: - Hero Video Section
struct HeroVideoSectionView: View {
    let video: Video
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @FocusState private var playButtonFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            // Large Video Thumbnail
            ZStack {
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.gray)
                        }
                }
                .frame(height: 600)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                
                // Play Button
                Button {
                    playVideo()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .focused($playButtonFocused)
                .scaleEffect(playButtonFocused ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: playButtonFocused)
            }
            
            // Video Information
            VStack(spacing: 20) {
                Text(video.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let creator = video.creator {
                    HStack(spacing: 15) {
                        Text("by \(creator.name)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if creator.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Text(video.videoDescription)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 100)
                
                HStack(spacing: 40) {
                    Label("\(video.views) views", systemImage: "eye.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Label("\(video.likes) likes", systemImage: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Label(video.formattedDuration, systemImage: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func playVideo() {
        let videoService = VideoService(modelContext: modelContext)
        videoService.incrementViews(for: video, user: appState.currentUser)
        appState.currentPlayingVideo = video
        
        // TODO: Present full-screen video player
        print("Playing video: \(video.title)")
    }
}

// MARK: - TV Section (Horizontal Scrolling)
struct TVSectionView: View {
    let title: String
    let videos: [Video]
    @FocusState private var focusedVideoID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text(title)
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 90)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(videos, id: \.id) { video in
                        TVVideoCardView(video: video)
                            .focused($focusedVideoID, equals: video.id)
                    }
                }
                .padding(.horizontal, 90)
            }
        }
    }
}

// MARK: - TV Creator Section
struct TVCreatorSectionView: View {
    let creators: [Creator]
    @FocusState private var focusedCreatorID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Featured Local Creators")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 90)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(creators, id: \.id) { creator in
                        TVCreatorCardView(creator: creator)
                            .focused($focusedCreatorID, equals: creator.id)
                    }
                }
                .padding(.horizontal, 90)
            }
        }
    }
}

// MARK: - Category Section
struct CategorySectionView: View {
    @FocusState private var focusedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Browse by Category")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 90)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 30) {
                ForEach(AppState.categories, id: \.self) { category in
                    CategoryCardView(category: category)
                        .focused($focusedCategory, equals: category)
                }
            }
            .padding(.horizontal, 90)
        }
    }
}

// MARK: - Category Card
struct CategoryCardView: View {
    let category: String
    @Environment(\.isFocused) private var isFocused
    
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
        VStack(spacing: 20) {
            Image(systemName: categoryIcon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(category)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(isFocused ? 0.2 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
