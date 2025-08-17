import Foundation

struct TMDBMovieSearchResult: Decodable {
    let page: Int
    let results: [TMDBMovieSummary]
}

struct TMDBMovieSummary: Decodable {
    let id: Int
    let title: String
    let release_date: String?
    let overview: String?
    let poster_path: String?
    let vote_average: Double
}

struct TMDBMovieDetails: Decodable {
    struct Genre: Decodable { let id: Int; let name: String }
    let id: Int
    let runtime: Int?
    let genres: [Genre]?
}

struct TMDBCredits: Decodable {
    struct Cast: Decodable { let name: String }
    struct Crew: Decodable { let job: String; let name: String }
    let cast: [Cast]
    let crew: [Crew]
}

final class TMDBService {
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    private let imageBaseURL = URL(string: "https://image.tmdb.org/t/p/w500")!

    private var apiKey: String? {
        // Read from Info.plist only
        if let k = Bundle.main.infoDictionary?["TMDB_API_KEY"] as? String, !k.isEmpty, k != "YOUR_TMDB_API_KEY" {
            return k
        }
        return nil
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        guard let apiKey, !apiKey.isEmpty, apiKey != "YOUR_TMDB_API_KEY" else {
            throw NSError(domain: "TMDBService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing TMDB API key. Set TMDB_API_KEY in Info.plist."])
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        var items = queryItems
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        return req
    }

    func search(query: String, year: Int? = nil, includeDetails: Bool = true, includeAdult: Bool = false) async throws -> [Movie] {
        var items = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "include_adult", value: includeAdult ? "true" : "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1")
        ]
        if let year { items.append(URLQueryItem(name: "year", value: String(year))) }
        let request = try makeRequest(path: "search/movie", queryItems: items)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(TMDBMovieSearchResult.self, from: data)
        // If caller doesn't want details: map summaries only (fast, fewer calls)
        if includeDetails == false {
            return decoded.results.map { summary in
                self.mapToMovie(summary: summary, details: nil, credits: nil)
            }
        }

        // Otherwise enrich with details & credits in parallel (best-effort)
        var movies: [Movie] = []
        movies.reserveCapacity(decoded.results.count)
        await withTaskGroup(of: Movie?.self) { group in
            for summary in decoded.results {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        let details = try await self.details(id: summary.id)
                        let credits = try await self.credits(id: summary.id)
                        return self.mapToMovie(summary: summary, details: details, credits: credits)
                    } catch {
                        return self.mapToMovie(summary: summary, details: nil, credits: nil)
                    }
                }
            }
            for await maybe in group { if let movie = maybe { movies.append(movie) } }
        }
        return movies
    }

    private func details(id: Int) async throws -> TMDBMovieDetails {
        let req = try makeRequest(path: "movie/\(id)", queryItems: [])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDBMovieDetails.self, from: data)
    }

    private func credits(id: Int) async throws -> TMDBCredits {
        let req = try makeRequest(path: "movie/\(id)/credits", queryItems: [])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDBCredits.self, from: data)
    }

    private func mapToMovie(summary: TMDBMovieSummary, details: TMDBMovieDetails?, credits: TMDBCredits?) -> Movie {
        // Year from release_date (yyyy-MM-dd)
        let year: Int = {
            guard let dateStr = summary.release_date, let y = Int(dateStr.prefix(4)) else { return 0 }
            return y
        }()
        // Director from crew
        let director: String = {
            guard let crew = credits?.crew else { return "" }
            return crew.first(where: { $0.job == "Director" })?.name ?? ""
        }()
        // Poster full URL
        let posterURL: String = {
            guard let path = summary.poster_path else { return "" }
            return imageBaseURL.appendingPathComponent(path).absoluteString
        }()
        let genres = details?.genres?.map { $0.name } ?? []
        let runtime = details?.runtime ?? 0
        let cast = Array(credits?.cast.prefix(5).map { $0.name } ?? [])

        return Movie(
            id: String(summary.id),
            title: summary.title,
            year: year,
            director: director,
            posterURL: posterURL,
            overview: summary.overview ?? "",
            criticRating: summary.vote_average,
            userRating: nil,
            watched: false,
            inWatchlist: false,
            genres: genres,
            runtime: runtime,
            cast: cast,
            listRankings: [:]
        )
    }
}
