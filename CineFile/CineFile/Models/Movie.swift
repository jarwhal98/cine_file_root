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
}
    
    // Sample movie data for development
    static let sampleMovies = [
        Movie(id: "1", title: "The Godfather", year: 1972, director: "Francis Ford Coppola", 
              posterURL: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg", 
              overview: "The aging patriarch of an organized crime dynasty transfers control to his reluctant son.",
              rating: 9.2, genres: ["Crime", "Drama"], runtime: 175),
        
        Movie(id: "2", title: "The Shawshank Redemption", year: 1994, director: "Frank Darabont", 
              posterURL: "https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg", 
              overview: "Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.",
              rating: 9.3, genres: ["Drama"], runtime: 142),
        
        Movie(id: "3", title: "Pulp Fiction", year: 1994, director: "Quentin Tarantino", 
              posterURL: "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg", 
              overview: "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.",
              rating: 8.9, genres: ["Crime", "Drama"], runtime: 154),
        
        Movie(id: "4", title: "The Dark Knight", year: 2008, director: "Christopher Nolan", 
              posterURL: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg", 
              overview: "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.",
              rating: 9.0, genres: ["Action", "Crime", "Drama", "Thriller"], runtime: 152),
        
        Movie(id: "5", title: "Inception", year: 2010, director: "Christopher Nolan", 
              posterURL: "https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg", 
              overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
              rating: 8.8, genres: ["Action", "Sci-Fi", "Thriller"], runtime: 148)
    ]
}
