import SwiftUI

struct MovieDetailView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    let movie: Movie
    
    @State private var isShowingRatingSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with poster and basic info
                ZStack(alignment: .bottom) {
                    // Background image (blurred poster)
                    AsyncImage(url: URL(string: movie.posterURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .blur(radius: 10)
                        default:
                            Color.gray.opacity(0.3)
                                .frame(height: 200)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 100)
                    
                    // Movie info overlay
                    HStack(alignment: .bottom, spacing: 15) {
                        // Poster
                        AsyncImage(url: URL(string: movie.posterURL)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 180)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 5)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 180)
                                    .overlay(Image(systemName: "photo"))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 120, height: 180)
                        .padding(.bottom, 15)
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(movie.year) • \(movie.runtime) min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(movie.director)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Rating
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", movie.rating))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Button {
                                    isShowingRatingSheet = true
                                } label: {
                                    Text("Rate")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.bottom, 15)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button {
                        viewModel.toggleWatchlist(for: movie)
                    } label: {
                        VStack {
                            Image(systemName: movie.inWatchlist ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                            Text(movie.inWatchlist ? "In Watchlist" : "Add to Watchlist")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        viewModel.toggleWatched(for: movie)
                    } label: {
                        VStack {
                            Image(systemName: movie.watched ? "eye.fill" : "eye")
                                .font(.title2)
                            Text(movie.watched ? "Watched" : "Mark as Watched")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        // Share functionality would be implemented here
                    } label: {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Genres
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(movie.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Overview")
                        .font(.headline)
                    
                    Text(movie.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // Similar movies would go here in a real app
                VStack(alignment: .leading, spacing: 10) {
                    Text("Similar Movies")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.movies.prefix(5)) { movie in
                                VStack(alignment: .leading) {
                                    AsyncImage(url: URL(string: movie.posterURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        default:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 100, height: 150)
                                                .overlay(Image(systemName: "photo"))
                                        }
                                    }
                                    .frame(width: 100, height: 150)
                                    
                                    Text(movie.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Text(String(movie.year))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Edit movie action
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isShowingRatingSheet) {
            // Rating sheet would be implemented here
            Text("Rate this movie")
                .font(.headline)
                .padding()
        }
    }
}
