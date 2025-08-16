import Foundation
import Combine

class MovieViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var watchlist: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiKey = "YOUR_API_KEY" // Replace with your TMDB API key
    
    init() {
        // Load sample data for development
        self.movies = Movie.sampleMovies
        
        // Add some sample movies to watchlist
        self.watchlist = [Movie.sampleMovies[0], Movie.sampleMovies[3]]
    }
    
    // MARK: - Movie Management
    
    func toggleWatchlist(for movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index].inWatchlist.toggle()
            
            if movies[index].inWatchlist {
                watchlist.append(movies[index])
            } else {
                watchlist.removeAll { $0.id == movie.id }
            }
        }
    }
    
    func toggleWatched(for movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index].watched.toggle()
        }
        
        if let watchlistIndex = watchlist.firstIndex(where: { $0.id == movie.id }) {
            watchlist[watchlistIndex].watched.toggle()
        }
    }
    
    // MARK: - API Methods
    
    func searchMovies(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // For now, just filter sample movies by title
        // In a real app, you'd call the API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchResults = self.movies.filter { $0.title.lowercased().contains(query.lowercased()) }
            self.isLoading = false
        }
    }
    
    // In a real app, you would implement these methods to fetch from TMDB API
    func fetchPopularMovies() {
        // Implementation would use URLSession to fetch from TMDB
    }
    
    func fetchMovieDetails(id: String) -> Movie? {
        return movies.first(where: { $0.id == id })
    }
}
