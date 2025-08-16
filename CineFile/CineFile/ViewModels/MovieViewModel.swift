import Foundation
import Combine

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
        // Load NYTimes 100 Best Movies data
        self.movies = Movie.nyTimes100Best21stCentury
        
        // Initialize with empty watchlist
        self.watchlist = []
        
        // Initialize available movie lists
        var nyTimesList = MovieList.nyTimes100BestOf21stCentury
        nyTimesList.movieIDs = movies.filter { $0.listRankings.keys.contains(nyTimesList.id) }.map { $0.id }
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
}
