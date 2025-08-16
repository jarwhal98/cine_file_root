import Foundation
import Combine
import SwiftUI
import os.log

// Using MovieList and MovieSortOption from Models/MovieList.swift

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
    @Published var isImporting: Bool = false
    @Published var importProgress: Double = 0.0
    private let tmdb = TMDBService()
    private let logger = Logger(subsystem: "com.cinefile.app", category: "MovieViewModel")
    
    init() {
    // Initialize with empty lists
    self.movies = []
        self.watchlist = []
        
        // Initialize available movie lists
        var nyTimesList = MovieList.nyTimes100BestOf21stCentury
    self.movieLists = [nyTimesList]
        
        // Set the default selected list
        selectList(nyTimesList.id)

    // Seed with static NYTimes sample data so UI has content immediately
    self.movies = Movie.nyTimes100Best21stCentury
    self.updateSelectedListMovies()
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

        Task { @MainActor in
            do {
                let results = try await tmdb.search(query: query)
                self.searchResults = results
                self.isLoading = false
            } catch {
                self.logger.error("Search failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
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

    // MARK: - Importers

    func importNYT21FromCSV() {
        Task { @MainActor in
            do {
                let rows = try CSVImporter.loadNYT21(fileName: "nyt_best_movies_21st_century")
                try await importList(rows: rows.map { ($0.rank, $0.title, $0.year) }, listID: "nytimes-100-21st-century")
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func importAFIFromCSV() {
        Task { @MainActor in
            do {
                let rows = try CSVImporter.loadAFI(fileName: "afi_top_100_2007")
                try await importList(rows: rows.map { ($0.rank, $0.title, $0.year) }, listID: "afi-100-2007")
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func importList(rows: [(Int, String, Int)], listID: String) async throws {
        isImporting = true
        importProgress = 0
        let total = max(rows.count, 1)
        defer {
            isImporting = false
        }
        var imported: [Movie] = []

        // Limit concurrency to avoid timeouts/rate limits
        let maxConcurrent = 6
        var iterator = rows.makeIterator()
        var inFlight: [Task<Movie?, Error>] = []
        var completed = 0
        func launchNext() {
            if let next = iterator.next() {
                let (rank, title, year) = next
                let task = Task<Movie?, Error> {
                    let results = try await tmdb.search(query: title, year: year, includeDetails: false)
                    if let movie = results.first(where: { $0.year == year }) ?? results.first {
                        var m = movie
                        m.listRankings[listID] = rank
                        return m
                    }
                    return nil
                }
                inFlight.append(task)
            }
        }

        // Prime initial batch
        for _ in 0..<min(maxConcurrent, rows.count) { launchNext() }
        while !inFlight.isEmpty {
            let finished = await withTaskGroup(of: (Int, Movie?).self) { group -> [(Int, Movie?)] in
                for (i, t) in inFlight.enumerated() {
                    group.addTask { (i, try? await t.value) }
                }
                var results: [(Int, Movie?)] = []
                for await val in group { results.append(val) }
                return results
            }
            inFlight.removeAll()
            for (_, maybe) in finished {
                if let movie = maybe { imported.append(movie) }
                completed += 1
                await MainActor.run { self.importProgress = Double(completed) / Double(total) }
                launchNext()
            }
        }

        // Merge into existing movies: prefer highest data richness by ID
        for m in imported {
            if let idx = movies.firstIndex(where: { $0.id == m.id }) {
                var existing = movies[idx]
                var merged = m
                // Preserve local toggles
                merged.watched = existing.watched
                merged.inWatchlist = existing.inWatchlist
                merged.userRating = existing.userRating
                // Merge rankings
                merged.listRankings.merge(existing.listRankings) { new, old in new }
                movies[idx] = merged
            } else {
                movies.append(m)
            }
        }
        updateSelectedListMovies()
        if let list = movieLists.first(where: { $0.id == listID }) {
            selectList(list.id)
        } else {
            // Add list metadata if missing
            let listName = (listID == "nytimes-100-21st-century") ? "NYTimes 100 Best Movies of the 21st Century" : "AFI 100 Greatest Films (2007)"
            let newList = MovieList(id: listID, name: listName, description: listName, source: listID.contains("afi") ? "AFI" : "The New York Times", year: listID.contains("nytimes") ? 2025 : 2007, movieIDs: [])
            movieLists.append(newList)
            selectList(newList.id)
        }
    }
}
