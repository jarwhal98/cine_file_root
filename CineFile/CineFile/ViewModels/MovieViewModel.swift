import Foundation
import Combine
import SwiftUI
import os.log

// Using MovieList and MovieSortOption from Models/MovieList.swift

class MovieViewModel: ObservableObject {
    static let allListsID = "all-lists"
    @Published var movies: [Movie] = []
    @Published var watchlist: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var movieLists: [MovieList] = []
    @Published var selectedList: MovieList?
    @Published var selectedListMovies: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var sortOption: MovieSortOption = .listRank
    @Published var sortAscending: Bool = true // true = baseline direction, false = reversed
    @Published var isImporting: Bool = false
    @Published var importProgress: Double = 0.0
    @Published var importCancelled: Bool = false
    // Preload lifecycle
    @Published var preloadCompleted: Bool = false
    @Published var preloadStatus: String = ""
    private let tmdb = TMDBService()
    private let logger = Logger(subsystem: "com.cinefile.app", category: "MovieViewModel")
    
    init() {
        // Initialize collections
        self.movies = []
        self.watchlist = []
        self.movieLists = []

    // Defer preload to startup (Splash will show progress)

        // Restore sort option & selected list if available
        if let savedSort = UserDefaults.standard.string(forKey: "sortOption"), let parsed = MovieSortOption(rawValue: savedSort) {
            sortOption = parsed
        }
        if UserDefaults.standard.object(forKey: "sortAscending") != nil {
            sortAscending = UserDefaults.standard.bool(forKey: "sortAscending")
        }
        if let savedListID = UserDefaults.standard.string(forKey: "selectedListID") {
            selectList(savedListID)
        } else if let first = movieLists.first {
            selectList(first.id)
        }
        self.updateSelectedListMovies()
    }

    private struct PreloadList: Decodable { let id: String; let name: String; let description: String; let source: String; let year: Int; let type: String; let resource: String }
    private struct PreloadConfig: Decodable { let lists: [PreloadList] }

    @MainActor
    func startInitialPreloadIfNeeded() {
    // Always check resources and drive status; if movies exist we still treat as complete quickly
        isImporting = true
        importProgress = 0
        preloadStatus = "Preparing…"

        Task { @MainActor in
            var succeeded = false
            defer {
                self.isImporting = false
                self.preloadCompleted = succeeded
                self.updateSelectedListMovies()
            }
            // Config is bundled at root; no subdirectory in app bundle
            guard let url = Bundle.main.url(forResource: "preloaded_lists", withExtension: "json") else {
                self.logger.error("Missing preloaded_lists.json in bundle root")
                self.preloadStatus = "Failed to find preloaded lists"
                return
            }
            do {
                let initialMovieCount = self.movies.count
                let data = try Data(contentsOf: url)
                let cfg = try JSONDecoder().decode(PreloadConfig.self, from: data)
                self.movieLists = cfg.lists.map { MovieList(id: $0.id, name: $0.name, description: $0.description, source: $0.source, year: $0.year, movieIDs: []) }

                // Determine overall total for a smoother progress ramp
                var totalRows = 0
                for item in cfg.lists {
                    switch item.type {
                    case "csv-nyt21": totalRows += (try? CSVImporter.loadNYT21(fileName: item.resource).count) ?? 0
                    case "csv-afi": totalRows += (try? CSVImporter.loadAFI(fileName: item.resource).count) ?? 0
                    case "csv-tspdt": totalRows += (try? CSVImporter.loadTSPDT(fileName: item.resource).count) ?? 0
                    default: break
                    }
                }
                var processedRows = 0

                for (idx, item) in cfg.lists.enumerated() {
                    if importCancelled { break }
                    self.preloadStatus = "Importing \(item.name)…"
                    let rows: [(Int, String, Int)]
                    switch item.type {
                    case "csv-nyt21":
                        rows = (try CSVImporter.loadNYT21(fileName: item.resource)).map { ($0.rank, $0.title, $0.year) }
                    case "csv-afi":
                        rows = (try CSVImporter.loadAFI(fileName: item.resource)).map { ($0.rank, $0.title, $0.year) }
                    case "csv-tspdt":
                        rows = (try CSVImporter.loadTSPDT(fileName: item.resource)).map { ($0.rank, $0.title, $0.year) }
                    default:
                        rows = []
                    }

                    // Overall progress: processedRows + (local * rows.count) over totalRows
                    try await importList(rows: rows, listID: item.id, progress: { local in
                        let completedWithinList = Double(processedRows) + local * Double(rows.count)
                        let overall = totalRows == 0 ? 1.0 : completedWithinList / Double(totalRows)
                        self.importProgress = overall
                    })
                    processedRows += rows.count

                    // Select first list after it’s ready
                    if idx == 0 { self.selectList(item.id) }
                }
                let importedCount = self.movies.count - initialMovieCount
                if importedCount > 0 {
                    self.preloadStatus = "Ready"
                    succeeded = true
                } else {
                    self.preloadStatus = "No titles imported"
                    succeeded = false
                }
            } catch {
                self.logger.error("Preload failed: \(error.localizedDescription)")
                self.preloadStatus = "Failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - List Management
    
    func selectList(_ listID: String) {
        if listID == Self.allListsID {
            selectedList = MovieList(
                id: Self.allListsID,
                name: "All Lists",
                description: "Combined view of all lists",
                source: "Combined",
                year: Calendar.current.component(.year, from: Date()),
                movieIDs: []
            )
        } else {
            guard let list = movieLists.first(where: { $0.id == listID }) else { return }
            selectedList = list
        }
    UserDefaults.standard.set(listID, forKey: "selectedListID")
        updateSelectedListMovies()
    }
    
    func updateSelectedListMovies() {
        guard let list = selectedList else {
            selectedListMovies = []
            return
        }
        
        // Get movies for this list (or all lists)
        let listMovies: [Movie] = {
            if list.id == Self.allListsID {
                return movies.filter { !$0.listRankings.isEmpty }
            } else {
                return movies.filter { $0.listRankings.keys.contains(list.id) }
            }
        }()
        
    // Sort according to current sort option and direction
    selectedListMovies = sortMovies(listMovies, by: sortOption, in: list.id)
    }
    
    func sortMovies(_ moviesToSort: [Movie], by option: MovieSortOption, in listID: String) -> [Movie] {
        // Baseline sorting for each option; some baselines are ascending (rank/title/year/director),
        // others are descending (critic/user rating). We reverse the baseline when sortAscending == false.
        let baselineSorted: [Movie]
        switch option {
        case .listRank:
            baselineSorted = moviesToSort.sorted {
                let lhsRank = (listID == Self.allListsID) ? ($0.listRankings.values.min() ?? 9999) : $0.listRankings[listID, default: 9999]
                let rhsRank = (listID == Self.allListsID) ? ($1.listRankings.values.min() ?? 9999) : $1.listRankings[listID, default: 9999]
                if lhsRank == rhsRank {
                    // tie-breaker: sum of ranks, then title
                    let lhsSum = $0.listRankings.values.reduce(0, +)
                    let rhsSum = $1.listRankings.values.reduce(0, +)
                    if lhsSum == rhsSum { return $0.title < $1.title }
                    return lhsSum < rhsSum
                }
                return lhsRank < rhsRank
            }
        case .title:
            baselineSorted = moviesToSort.sorted { $0.title < $1.title }
        case .year:
            baselineSorted = moviesToSort.sorted { $0.year < $1.year }
        case .director:
            baselineSorted = moviesToSort.sorted { $0.directorLastName < $1.directorLastName }
        case .criticRating:
            // Baseline: highest first
            baselineSorted = moviesToSort.sorted { $0.criticRating > $1.criticRating }
        case .userRating:
            // Baseline: highest first (rated items first)
            baselineSorted = moviesToSort.sorted { 
                guard let rating0 = $0.userRating, let rating1 = $1.userRating else {
                    if $0.userRating != nil { return true }
                    if $1.userRating != nil { return false }
                    return false
                }
                return rating0 > rating1
            }
        }
        // Reverse if toggled off baseline
        return sortAscending ? baselineSorted : baselineSorted.reversed()
    }
    
    func setSortOption(_ option: MovieSortOption) {
        if option == sortOption {
            // Toggle direction
            sortAscending.toggle()
            UserDefaults.standard.set(sortAscending, forKey: "sortAscending")
        } else {
            sortOption = option
            UserDefaults.standard.set(option.rawValue, forKey: "sortOption")
            // Keep current direction as-is to avoid surprise
        }
        updateSelectedListMovies()
    }

    // For UI: whether the effective current order is ascending visually for a given option
    func isEffectiveAscending(for option: MovieSortOption) -> Bool {
        switch option {
        case .criticRating, .userRating:
            // Baseline is descending; invert
            return !sortAscending
        default:
            return sortAscending
        }
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

    func setWatchedDate(for movie: Movie, date: Date) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index].watchedDate = date
            // mirror to watchlist/selected if present
            if let watchlistIndex = watchlist.firstIndex(where: { $0.id == movie.id }) {
                watchlist[watchlistIndex].watchedDate = date
            }
            if let listIndex = selectedListMovies.firstIndex(where: { $0.id == movie.id }) {
                selectedListMovies[listIndex].watchedDate = date
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
        let includeAdult = UserDefaults.standard.bool(forKey: "showAdultContent")
        let results = try await tmdb.search(query: query, year: nil, includeDetails: true, includeAdult: includeAdult)
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
        let listMovies: [Movie]
        if listID == Self.allListsID {
            listMovies = movies.filter { !$0.listRankings.isEmpty }
        } else {
            listMovies = movies.filter { $0.listRankings.keys.contains(listID) }
        }
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
                self.importCancelled = false
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
                self.importCancelled = false
                let rows = try CSVImporter.loadAFI(fileName: "afi_top_100_2007")
                try await importList(rows: rows.map { ($0.rank, $0.title, $0.year) }, listID: "afi-100-2007")
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func importList(rows: [(Int, String, Int)], listID: String, progress: ((Double) -> Void)? = nil) async throws {
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
        if importCancelled { return }
            if let next = iterator.next() {
                let (rank, title, year) = next
                let task = Task<Movie?, Error> {
            let includeAdult = UserDefaults.standard.bool(forKey: "showAdultContent")
            let results = try await tmdb.search(query: title, year: year, includeDetails: false, includeAdult: includeAdult)
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
        let local = Double(completed) / Double(total)
        await MainActor.run {
            if let cb = progress {
                cb(local)
            } else {
                self.importProgress = local
            }
        }
                if importCancelled {
                    inFlight.removeAll()
                    break
                }
                launchNext()
            }
            if importCancelled { break }
        }

        // Merge into existing movies: prefer ID match, fallback to title+year to avoid duplicates
        for m in imported {
            if let idx = movies.firstIndex(where: { $0.id == m.id }) {
                let existing = movies[idx]
                var merged = m
                merged.watched = existing.watched
                merged.inWatchlist = existing.inWatchlist
                merged.userRating = existing.userRating
                merged.listRankings.merge(existing.listRankings) { new, old in new }
                movies[idx] = merged
            } else if let idx2 = movies.firstIndex(where: { $0.title.caseInsensitiveCompare(m.title) == .orderedSame && $0.year == m.year }) {
                var existing = movies[idx2]
                // Merge rankings into existing record and preserve its ID
                existing.listRankings.merge(m.listRankings) { new, old in new }
                // Optionally fill missing metadata from m if existing lacks it
                if existing.director.isEmpty { existing.director = m.director }
                if existing.posterURL.isEmpty { existing.posterURL = m.posterURL }
                if existing.overview.isEmpty { existing.overview = m.overview }
                if existing.runtime == 0 { existing.runtime = m.runtime }
                if existing.genres.isEmpty { existing.genres = m.genres }
                if existing.cast.isEmpty { existing.cast = m.cast }
                movies[idx2] = existing
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

    func cancelImport() {
        importCancelled = true
    }
}
