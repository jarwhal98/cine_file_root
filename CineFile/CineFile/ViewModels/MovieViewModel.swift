import Foundation
import Combine
import SwiftUI

// Add MovieList struct directly in the file since the import seems to be failing
struct MovieList: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var source: String // e.g., "NYTimes", "AFI", etc.
    var year: Int // Year the list was published
    var movieIDs: [String] // IDs of movies in this list
    
    // Optional fields
    var imageURL: String?
    var sourceURL: String?
    
    // Computed property to get completion percentage
    var completionPercentage: Double {
        0.0 // This will be implemented based on watched status of movies
    }
    
    static func == (lhs: MovieList, rhs: MovieList) -> Bool {
        lhs.id == rhs.id
    }
    
    // NY Times 100 Best Movies of the 21st Century sample data
    static var nyTimes100BestOf21stCentury: MovieList {
        MovieList(
            id: "nytimes-100-21st-century",
            name: "NYTimes 100 Best Movies of the 21st Century",
            description: "The New York Times' critics rank the 100 greatest movies of the 21st century.",
            source: "The New York Times",
            year: 2025,
            movieIDs: [], // Will be populated when we create the actual movies
            sourceURL: "https://www.nytimes.com/interactive/2025/movies/best-movies-21st-century.html"
        )
    }
}

// Add MovieSortOption enum directly in the file
enum MovieSortOption: String, CaseIterable {
    case listRank = "List Ranking"
    case title = "Title"
    case year = "Year"
    case director = "Director"
    case criticRating = "Critic Rating"
    case userRating = "My Rating"
}

class MovieViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var watchlist: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var movieLists: [MovieList] = []
    @Published var selectedList: MovieList?
    @Published var selectedListMovies: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var sortOption: MovieSortOption = .listRank
    
    init() {
        // Create empty arrays temporarily to fix build issues
        self.movies = []
        
        // Initialize with empty watchlist
        self.watchlist = []
        
        // Initialize available movie lists
        var nyTimesList = MovieList.nyTimes100BestOf21stCentury
        // No need to filter movie IDs from an empty array
        self.movieLists = [nyTimesList]
        
        // Set the default selected list
        selectList(nyTimesList.id)
    }
    
    // MARK: - List Management
    
    func selectList(_ listID: String) {
        guard let list = movieLists.first(where: { $0.id == listID }) else { return }
        
        selectedList = list
        updateSelectedListMovies()
    }
    
    func updateSelectedListMovies() {
        guard let list = selectedList else {
            selectedListMovies = []
            return
        }
        
        // Get movies that are part of this list
        let listMovies = movies.filter { movie in
            movie.listRankings.keys.contains(list.id)
        }
        
        // Sort according to current sort option
        selectedListMovies = sortMovies(listMovies, by: sortOption, in: list.id)
    }
    
    func sortMovies(_ moviesToSort: [Movie], by option: MovieSortOption, in listID: String) -> [Movie] {
        switch option {
        case .listRank:
            return moviesToSort.sorted { 
                $0.listRankings[listID, default: 999] < $1.listRankings[listID, default: 999] 
            }
        case .title:
            return moviesToSort.sorted { $0.title < $1.title }
        case .year:
            return moviesToSort.sorted { $0.year < $1.year }
        case .director:
            return moviesToSort.sorted { $0.directorLastName < $1.directorLastName }
        case .criticRating:
            return moviesToSort.sorted { $0.criticRating > $1.criticRating }
        case .userRating:
            return moviesToSort.sorted { 
                guard let rating0 = $0.userRating, let rating1 = $1.userRating else {
                    if $0.userRating != nil { return true }
                    if $1.userRating != nil { return false }
                    return false
                }
                return rating0 > rating1
            }
        }
    }
    
    func setSortOption(_ option: MovieSortOption) {
        sortOption = option
        updateSelectedListMovies()
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
            
            // Update the movie in selectedListMovies if it exists there
            if let listIndex = selectedListMovies.firstIndex(where: { $0.id == movie.id }) {
                selectedListMovies[listIndex].inWatchlist = movies[index].inWatchlist
            }
        }
    }
    
    func toggleWatched(for movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index].watched.toggle()
            
            // Also update in watchlist if present
            if let watchlistIndex = watchlist.firstIndex(where: { $0.id == movie.id }) {
                watchlist[watchlistIndex].watched = movies[index].watched
            }
            
            // Update the movie in selectedListMovies if it exists there
            if let listIndex = selectedListMovies.firstIndex(where: { $0.id == movie.id }) {
                selectedListMovies[listIndex].watched = movies[index].watched
            }
        }
    }
    
    func rateMovie(_ movie: Movie, rating: Double) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index].userRating = rating
            
            // Also update in watchlist if present
            if let watchlistIndex = watchlist.firstIndex(where: { $0.id == movie.id }) {
                watchlist[watchlistIndex].userRating = rating
            }
            
            // Update the movie in selectedListMovies if it exists there
            if let listIndex = selectedListMovies.firstIndex(where: { $0.id == movie.id }) {
                selectedListMovies[listIndex].userRating = rating
            }
        }
    }
    
    // MARK: - Search Methods
    
    func searchMovies(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Search across all movies, not just the current list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchResults = self.movies.filter { 
                $0.title.lowercased().contains(query.lowercased()) ||
                $0.director.lowercased().contains(query.lowercased()) ||
                $0.overview.lowercased().contains(query.lowercased()) ||
                $0.genres.contains(where: { $0.lowercased().contains(query.lowercased()) }) ||
                $0.cast.contains(where: { $0.lowercased().contains(query.lowercased()) })
            }
            self.isLoading = false
        }
    }
    
    // MARK: - List Completion
    
    func calculateListCompletion(for listID: String) -> (watched: Int, total: Int) {
        let listMovies = movies.filter { $0.listRankings.keys.contains(listID) }
        let watchedCount = listMovies.filter { $0.watched }.count
        return (watchedCount, listMovies.count)
    }
    
    func calculateListProgress(for listID: String) -> Double {
        let (watched, total) = calculateListCompletion(for: listID)
        guard total > 0 else { return 0.0 }
        return Double(watched) / Double(total)
    }
    
    // MARK: - Detail Methods
    
    func fetchMovieDetails(id: String) -> Movie? {
        return movies.first(where: { $0.id == id })
    }
}
