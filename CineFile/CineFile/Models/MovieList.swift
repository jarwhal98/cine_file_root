import Foundation

struct MovieList: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var source: String // e.g., "NYTimes", "AFI", etc.
    var year: Int // Year the list was published
    var movieIDs: [String] // IDs of movies in this list
    // Mark lists created by the user; optional for backward-compatible decoding
    var isUserCreated: Bool? = nil
    
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
}

// Sort options for movie lists
enum MovieSortOption: String, CaseIterable {
    case listRank = "List Ranking"
    case title = "Title"
    case year = "Year"
    case director = "Director"
    case criticRating = "Critic Rating"
    case userRating = "My Rating"
}

// NY Times 100 Best Movies of the 21st Century sample data
extension MovieList {
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
