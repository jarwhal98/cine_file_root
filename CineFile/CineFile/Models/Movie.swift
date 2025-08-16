import Foundation

struct Movie: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var year: Int
    var director: String
    var posterURL: String
    var overview: String
    var criticRating: Double // Critical rating (e.g. from NYTimes)
    var userRating: Double? // User's personal rating
    var watched: Bool = false
    var inWatchlist: Bool = false
    var genres: [String]
    var runtime: Int // in minutes
    var cast: [String] = []
    
    // List rankings - key is list ID, value is rank in that list
    var listRankings: [String: Int] = [:]
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper function to get director's last name for sorting
    var directorLastName: String {
        let components = director.split(separator: " ")
        return components.last?.description ?? director
    }
    
    // Add rating computed property that returns criticRating
    var rating: Double {
        return criticRating
    }
}
