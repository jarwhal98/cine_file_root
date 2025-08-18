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
    private let userListsKey = "userCreatedLists"
    
    init() {
        // Initialize collections
        self.movies = []
        self.watchlist = []
        self.movieLists = []

    // Defer preload to startup (Splash will show progress)

        // First-launch defaults: NYT list, ascending by rank (so #1 is at the top)
        if UserDefaults.standard.object(forKey: "hasLaunchedOnce") == nil || UserDefaults.standard.bool(forKey: "hasLaunchedOnce") == false {
            UserDefaults.standard.set(MovieSortOption.listRank.rawValue, forKey: "sortOption")
            UserDefaults.standard.set(true, forKey: "sortAscending") // ascending for list rank
            UserDefaults.standard.set("nytimes-100-21st-century", forKey: "selectedListID")
            UserDefaults.standard.set(true, forKey: "hasLaunchedOnce")
            sortOption = .listRank
            sortAscending = true
        }

        // Restore sort option & selected list if available
        if let savedSort = UserDefaults.standard.string(forKey: "sortOption"), let parsed = MovieSortOption(rawValue: savedSort) {
            sortOption = parsed
        }
        if UserDefaults.standard.object(forKey: "sortAscending") != nil {
            sortAscending = UserDefaults.standard.bool(forKey: "sortAscending")
        }
        if let savedListID = UserDefaults.standard.string(forKey: "selectedListID") {
            Task { @MainActor in self.selectList(savedListID) }
        } else if let first = movieLists.first {
            Task { @MainActor in self.selectList(first.id) }
        }
    // Load user-created lists from persistence before first update
    loadUserLists()
    Task { @MainActor in self.updateSelectedListMovies() }
    }

    private struct PreloadList: Decodable { let id: String; let name: String; let description: String; let source: String; let year: Int; let type: String; let resource: String; let preload: Bool? }
    private struct PreloadConfig: Decodable { let lists: [PreloadList] }
    struct PreloadListUI: Identifiable { let id: String; let name: String; let description: String; let source: String; let year: Int }
    // Import row with optional director (for better disambiguation)
    struct ImportRow {
        let rank: Int
        let title: String
        let year: Int
        let director: String? // pass when known (e.g., TSPDT), else nil
    }

    @MainActor
    func startInitialPreloadIfNeeded() {
    // Always check resources and drive status; if movies exist we still treat as complete quickly
        isImporting = true
        importProgress = 0
        preloadStatus = "Preparing…"

        Task { @MainActor in
            // Note: keep progress/status only; no local succeeded flag needed
            defer {
                self.isImporting = false
                // Always allow proceeding past splash once the attempt finishes (even on failure)
                self.preloadCompleted = true
                self.reconcileUserListMembership()
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
                let initialItems = cfg.lists.filter { $0.preload != false }
                self.movieLists = initialItems.map { MovieList(id: $0.id, name: $0.name, description: $0.description, source: $0.source, year: $0.year, movieIDs: []) }
                // Normalize any existing list metadata from catalog
                self.syncMovieListsWithCatalog()
                // Respect saved selection if present
                if let savedListID = UserDefaults.standard.string(forKey: "selectedListID"), self.movieLists.contains(where: { $0.id == savedListID }) {
                    self.selectList(savedListID)
                }

                // Determine overall total for a smoother progress ramp
                var totalRows = 0
                for item in initialItems {
                    switch item.type {
                    case "csv-nyt21": totalRows += (try? CSVImporter.loadNYT21(fileName: item.resource).count) ?? 0
                    case "csv-afi": totalRows += (try? CSVImporter.loadAFI(fileName: item.resource).count) ?? 0
                    case "csv-tspdt": totalRows += (try? CSVImporter.loadTSPDT(fileName: item.resource).count) ?? 0
                    default: break
                    }
                }
                var processedRows = 0

                for (idx, item) in initialItems.enumerated() {
                    if importCancelled { break }
                    self.preloadStatus = "Importing \(item.name)…"
                    let rows: [ImportRow]
                    switch item.type {
                    case "csv-nyt21":
                        rows = try CSVImporter.loadNYT21(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }
                    case "csv-afi":
                        rows = try CSVImporter.loadAFI(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }
                    case "csv-tspdt":
                        rows = try CSVImporter.loadTSPDT(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: $0.director) }
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

                    // Select first list after it’s ready only if no saved selection exists
                    if idx == 0 && UserDefaults.standard.string(forKey: "selectedListID") == nil {
                        Task { @MainActor in self.selectList(item.id) }
                    }
                }
                let importedCount = self.movies.count - initialMovieCount
                if importedCount > 0 {
                    self.preloadStatus = "Ready"
                } else {
                    self.preloadStatus = "No titles imported"
                }
            } catch {
                self.logger.error("Preload failed: \(error.localizedDescription)")
                self.preloadStatus = "Failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Preload Catalog helpers
    private func loadPreloadConfig() -> PreloadConfig? {
        guard let url = Bundle.main.url(forResource: "preloaded_lists", withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PreloadConfig.self, from: data)
        } catch {
            logger.error("Failed to load preloaded_lists: \(error.localizedDescription)")
            return nil
        }
    }

    func uninstalledPreloadItems() -> [PreloadListUI] {
        guard let cfg = loadPreloadConfig() else { return [] }
        let installedIDs = Set(movieLists.map { $0.id })
        return cfg.lists
            .filter { !installedIDs.contains($0.id) }
            .map { PreloadListUI(id: $0.id, name: $0.name, description: $0.description, source: $0.source, year: $0.year) }
            .sorted { $0.name < $1.name }
    }

    @MainActor
    func importPreloadLists(ids: [String]) async {
        guard let cfg = loadPreloadConfig() else { return }
        let items = cfg.lists.filter { ids.contains($0.id) }
        guard !items.isEmpty else { return }
        isImporting = true
        importProgress = 0
        preloadStatus = "Importing…"
        var totalRows = 0
        for item in items {
            switch item.type {
            case "csv-nyt21": totalRows += (try? CSVImporter.loadNYT21(fileName: item.resource).count) ?? 0
            case "csv-afi": totalRows += (try? CSVImporter.loadAFI(fileName: item.resource).count) ?? 0
            case "csv-tspdt": totalRows += (try? CSVImporter.loadTSPDT(fileName: item.resource).count) ?? 0
            default: break
            }
        }
        var processedRows = 0
        for item in items {
            if importCancelled { break }
            // Ensure list metadata exists before import (prevents wrong labels)
            ensureListMetadata(for: item.id)
            preloadStatus = "Importing \(item.name)…"
            let rows: [ImportRow]
            switch item.type {
            case "csv-nyt21":
                rows = (try? CSVImporter.loadNYT21(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }) ?? []
            case "csv-afi":
                rows = (try? CSVImporter.loadAFI(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }) ?? []
            case "csv-tspdt":
                rows = (try? CSVImporter.loadTSPDT(fileName: item.resource).map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: $0.director) }) ?? []
            default:
                rows = []
            }
            do {
                try await importList(rows: rows, listID: item.id, progress: { local in
                    let completedWithinList = Double(processedRows) + local * Double(rows.count)
                    self.importProgress = totalRows == 0 ? 1.0 : completedWithinList / Double(totalRows)
                })
            } catch {
                logger.error("Import failed for \(item.id): \(error.localizedDescription)")
            }
            processedRows += rows.count
        }
    isImporting = false
    preloadStatus = "Ready"
    // Normalize labels from catalog and refresh movies
    syncMovieListsWithCatalog()
    reconcileUserListMembership()
    updateSelectedListMovies()
    }
    
    // MARK: - List Management
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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

    @MainActor
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
                    .map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }
                try await importList(rows: rows, listID: "nytimes-100-21st-century")
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
                    .map { ImportRow(rank: $0.rank, title: $0.title, year: $0.year, director: nil) }
                try await importList(rows: rows, listID: "afi-100-2007")
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func importList(rows: [ImportRow], listID: String, progress: ((Double) -> Void)? = nil) async throws {
        await MainActor.run { self.isImporting = true }
        importProgress = 0
        let total = max(rows.count, 1)
        defer {
            Task { @MainActor in self.isImporting = false }
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
                let row = next
                let task = Task<Movie?, Error> {
            let includeAdult = UserDefaults.standard.bool(forKey: "showAdultContent")
            // Fetch with details so we have director/runtime/genres for list rows
            let results = try await tmdb.search(query: row.title, year: row.year, includeDetails: true, includeAdult: includeAdult)
            // Pick best candidate
            if let best = self.pickBestMatch(from: results, for: row) {
                var m = best
                m.listRankings[listID] = row.rank
                return m
            }
            return nil
                }
                inFlight.append(task)
            }
        }

    // Prime initial batch so there is work to process
    for _ in 0..<min(maxConcurrent, rows.count) { launchNext() }

        // Process sequentially to avoid Swift 6 captured var issues
        while !inFlight.isEmpty {
            let t = inFlight.removeFirst()
            do {
                if let movie = try await t.value {
                    imported.append(movie)
                }
            } catch {
                // Ignore individual fetch errors; continue processing others
            }
            completed += 1
            let local = Double(completed) / Double(total)
            await MainActor.run {
                if let cb = progress { cb(local) } else { self.importProgress = local }
            }
            if importCancelled { inFlight.removeAll(); break }
            launchNext()
        }

        // Merge into existing movies: prefer ID match, fallback to title+year to avoid duplicates
        await MainActor.run {
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
            // Don’t override user/saved selection during bulk imports; only set if nothing is selected and none saved
            let hasSavedSelection = UserDefaults.standard.string(forKey: "selectedListID") != nil
            if selectedList == nil && !hasSavedSelection {
                if let list = movieLists.first(where: { $0.id == listID }) {
                    selectList(list.id)
                } else {
                    // Add list metadata from catalog if missing (avoid hardcoded fallbacks)
                    ensureListMetadata(for: listID)
                    if let list = movieLists.first(where: { $0.id == listID }) {
                        selectList(list.id)
                    }
                }
            }
        }
    }

    // MARK: - Matching Heuristics
    private func normalizeTitle(_ s: String) -> String {
        let lowered = s.lowercased()
        let stripped = lowered.replacingOccurrences(of: "[\\p{Punct}]", with: "", options: .regularExpression)
        return stripped.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func directorLastName(_ s: String) -> String {
        return s.split(separator: " ").last.map(String.init) ?? s
    }

    private func pickBestMatch(from results: [Movie], for row: ImportRow) -> Movie? {
        guard !results.isEmpty else { return nil }
        let queryNorm = normalizeTitle(row.title)
        let forbidden = ["making of", "making-of", "behind the scenes", "behind-the-scenes", "the making of", "@"]

        func score(_ m: Movie) -> Int {
            var sc = 0
            let titleNorm = normalizeTitle(m.title)
            if titleNorm == queryNorm { sc += 100 }
            if m.year == row.year { sc += 50 }
            if abs(m.year - row.year) == 1 { sc += 10 }
            if let dir = row.director, !dir.isEmpty {
                let ln = directorLastName(dir.lowercased())
                let md = m.director.lowercased()
                if !md.isEmpty {
                    if md.contains(ln) { sc += 50 }
                    else if md.split(separator: " ").contains(where: { $0 == Substring(ln) }) { sc += 30 }
                }
            }
            let lowerTitle = m.title.lowercased()
            if forbidden.contains(where: { lowerTitle.contains($0) }) { sc -= 60 }
            return sc
        }

        // Prefer highest score; tie-breaker by criticRating descending
        let scored = results.map { ($0, score($0)) }
        if let best = scored.max(by: { (a, b) in
            if a.1 == b.1 { return a.0.criticRating < b.0.criticRating }
            return a.1 < b.1
        }), best.1 > -1000 {
            return best.0
        }
        // Fallback to previous behavior
        return results.first(where: { $0.year == row.year }) ?? results.first
    }

    func cancelImport() {
        importCancelled = true
    }

    // MARK: - Helpers
    private func ensureListMetadata(for id: String) {
        if movieLists.contains(where: { $0.id == id }) { return }
        // Try catalog first
        if let cfg = loadPreloadConfig(), let item = cfg.lists.first(where: { $0.id == id }) {
            movieLists.append(MovieList(id: item.id, name: item.name, description: item.description, source: item.source, year: item.year, movieIDs: []))
            return
        }
        // Fallback minimal entry if catalog missing
        movieLists.append(MovieList(id: id, name: id, description: id, source: "", year: Calendar.current.component(.year, from: Date()), movieIDs: []))
    }

    private func syncMovieListsWithCatalog() {
        guard let cfg = loadPreloadConfig() else { return }
        var map: [String: PreloadList] = [:]
        for item in cfg.lists { map[item.id] = item }
        movieLists = movieLists.map { ml in
            if let item = map[ml.id] {
                // Preserve user-created flag when present
                return MovieList(id: ml.id, name: item.name, description: item.description, source: item.source, year: item.year, movieIDs: ml.movieIDs, isUserCreated: ml.isUserCreated)
            }
            return ml
        }
    }

    // Apply user list membership to movies based on stored movieIDs
    @MainActor
    private func reconcileUserListMembership() {
        let userLists = movieLists.filter { $0.isUserCreated == true }
        guard !userLists.isEmpty, !movies.isEmpty else { return }
        var rankMaps: [String: [String: Int]] = [:] // listID -> movieID -> rank
        for ul in userLists {
            var m: [String: Int] = [:]
            for (idx, mid) in ul.movieIDs.enumerated() { m[mid] = idx + 1 }
            rankMaps[ul.id] = m
        }
        for i in movies.indices {
            for (listID, map) in rankMaps {
                if let rank = map[movies[i].id] {
                    movies[i].listRankings[listID] = rank
                }
            }
        }
    }

    // MARK: - User-created Lists
    @MainActor
    func createUserList(name: String, description: String = "") {
        let id = "user-\(UUID().uuidString.lowercased())"
        let list = MovieList(id: id, name: name, description: description, source: "My Lists", year: Calendar.current.component(.year, from: Date()), movieIDs: [], isUserCreated: true)
        movieLists.insert(list, at: 0)
        persistUserLists()
    }

    @MainActor
    func renameUserList(id: String, newName: String) {
        guard let idx = movieLists.firstIndex(where: { $0.id == id && ($0.isUserCreated ?? false) }) else { return }
        movieLists[idx].name = newName
        persistUserLists()
    }

    @MainActor
    func deleteUserList(id: String) {
        // If deleting currently selected list, fallback to All Lists
        if selectedList?.id == id { selectList(Self.allListsID) }
        movieLists.removeAll { $0.id == id && ($0.isUserCreated ?? false) }
        // Also remove listRanking keys from movies for cleanliness
        for i in movies.indices {
            _ = movies[i].listRankings.removeValue(forKey: id)
        }
        persistUserLists()
        updateSelectedListMovies()
    }

    @MainActor
    func addMovie(_ movie: Movie, toListID id: String) {
        guard let idx = movieLists.firstIndex(where: { $0.id == id }) else { return }
        if !movieLists[idx].movieIDs.contains(movie.id) {
            movieLists[idx].movieIDs.append(movie.id)
        }
        // Assign a rank if not present; use append position as rank
        if let mIdx = movies.firstIndex(where: { $0.id == movie.id }) {
            if movies[mIdx].listRankings[id] == nil {
                let rank = (movieLists[idx].movieIDs.firstIndex(of: movie.id).map { $0 + 1 }) ?? 1
                movies[mIdx].listRankings[id] = rank
            }
        }
        persistUserLists()
        updateSelectedListMovies()
    }

    @MainActor
    func removeMovie(_ movie: Movie, fromListID id: String) {
        guard let idx = movieLists.firstIndex(where: { $0.id == id }) else { return }
        movieLists[idx].movieIDs.removeAll { $0 == movie.id }
        if let mIdx = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[mIdx].listRankings.removeValue(forKey: id)
        }
        persistUserLists()
        updateSelectedListMovies()
    }

    // Persist only user-created lists
    private func persistUserLists() {
        do {
            let userLists = movieLists.filter { $0.isUserCreated == true }
            let data = try JSONEncoder().encode(userLists)
            UserDefaults.standard.set(data, forKey: userListsKey)
        } catch {
            logger.error("Failed to persist user lists: \(error.localizedDescription)")
        }
    }

    private func loadUserLists() {
        guard let data = UserDefaults.standard.data(forKey: userListsKey) else { return }
        do {
            let lists = try JSONDecoder().decode([MovieList].self, from: data)
            // Merge with existing (avoid duplicates by id)
            let existingIDs = Set(movieLists.map { $0.id })
            let toAdd = lists.filter { !existingIDs.contains($0.id) }
            movieLists.append(contentsOf: toAdd)
            if !movies.isEmpty {
                Task { @MainActor in
                    self.reconcileUserListMembership()
                    self.updateSelectedListMovies()
                }
            }
        } catch {
            logger.error("Failed to decode user lists: \(error.localizedDescription)")
        }
    }
}
