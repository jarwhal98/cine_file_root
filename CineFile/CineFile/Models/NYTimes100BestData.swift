import Foundation

// This file contains the data for the NYTimes 100 Best Movies of the 21st Century
// In a real app, this would be fetched from an API or a database

extension Movie {
    static let nyTimes100Best21stCentury: [Movie] = [
        Movie(
            id: "nyt1",
            title: "Parasite",
            year: 2019,
            director: "Bong Joon Ho",
            posterURL: "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
            overview: "All unemployed, Ki-taek's family takes peculiar interest in the wealthy and glamorous Parks for their livelihood until they get entangled in an unexpected incident.",
            criticRating: 9.5,
            genres: ["Comedy", "Drama", "Thriller"],
            runtime: 132,
            cast: ["Song Kang-ho", "Lee Sun-kyun", "Cho Yeo-jeong", "Choi Woo-shik"],
            listRankings: ["nytimes-100-21st-century": 1]
        ),
        Movie(
            id: "nyt2",
            title: "There Will Be Blood",
            year: 2007,
            director: "Paul Thomas Anderson",
            posterURL: "https://image.tmdb.org/t/p/w500/fa0RDkAlCec0STeMNAhPaF89q6U.jpg",
            overview: "A story of family, religion, hatred, oil and madness, focusing on a turn-of-the-century prospector in the early days of the business.",
            criticRating: 9.2,
            genres: ["Drama"],
            runtime: 158,
            cast: ["Daniel Day-Lewis", "Paul Dano", "Kevin J. O'Connor"],
            listRankings: ["nytimes-100-21st-century": 2]
        ),
        Movie(
            id: "nyt3",
            title: "Spirited Away",
            year: 2001,
            director: "Hayao Miyazaki",
            posterURL: "https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg",
            overview: "A young girl, Chihiro, becomes trapped in a strange new world of spirits. When her parents undergo a mysterious transformation, she must call upon the courage she never knew she had to free her family.",
            criticRating: 9.3,
            genres: ["Animation", "Family", "Fantasy"],
            runtime: 125,
            cast: ["Rumi Hiiragi", "Miyu Irino", "Mari Natsuki"],
            listRankings: ["nytimes-100-21st-century": 3]
        ),
        Movie(
            id: "nyt4",
            title: "In the Mood for Love",
            year: 2000,
            director: "Wong Kar-wai",
            posterURL: "https://image.tmdb.org/t/p/w500/iYypPT4bhqXfq1b7iJLxxGtNZly.jpg",
            overview: "Two neighbors, a woman and a man, form a strong bond after both suspect extramarital activities of their spouses. However, they agree to keep their bond platonic so as not to commit similar wrongs.",
            criticRating: 9.1,
            genres: ["Drama", "Romance"],
            runtime: 98,
            cast: ["Tony Leung Chiu-wai", "Maggie Cheung", "Rebecca Pan"],
            listRankings: ["nytimes-100-21st-century": 4]
        ),
        Movie(
            id: "nyt5",
            title: "Get Out",
            year: 2017,
            director: "Jordan Peele",
            posterURL: "https://image.tmdb.org/t/p/w500/qbaIHoJ9zNfTtUtyycKw5xvWnuY.jpg",
            overview: "Chris and his girlfriend Rose go upstate to visit her parents for the weekend. At first, Chris reads the family's overly accommodating behavior as nervous attempts to deal with their daughter's interracial relationship, but as the weekend progresses, a series of increasingly disturbing discoveries lead him to a truth that he never could have imagined.",
            criticRating: 8.9,
            genres: ["Horror", "Mystery", "Thriller"],
            runtime: 104,
            cast: ["Daniel Kaluuya", "Allison Williams", "Bradley Whitford", "Catherine Keener"],
            listRankings: ["nytimes-100-21st-century": 5]
        ),
        Movie(
            id: "nyt6",
            title: "Moonlight",
            year: 2016,
            director: "Barry Jenkins",
            posterURL: "https://image.tmdb.org/t/p/w500/93NN95a71MsQ4tR2zSLv8BdaeA7.jpg",
            overview: "The tender, heartbreaking story of a young man's struggle to find himself, told across three defining chapters in his life as he experiences the ecstasy, pain, and beauty of falling in love, while grappling with his own sexuality.",
            criticRating: 9.0,
            genres: ["Drama"],
            runtime: 111,
            cast: ["Trevante Rhodes", "André Holland", "Janelle Monáe", "Ashton Sanders"],
            listRankings: ["nytimes-100-21st-century": 6]
        ),
        Movie(
            id: "nyt7",
            title: "The Social Network",
            year: 2010,
            director: "David Fincher",
            posterURL: "https://image.tmdb.org/t/p/w500/n0ybibhJtQ5icDqTp8eRytcIHJx.jpg",
            overview: "On a fall night in 2003, Harvard undergrad and computer programming genius Mark Zuckerberg sits down at his computer and heatedly begins working on a new idea. In a fury of blogging and programming, what begins in his dorm room as a small site among friends soon becomes a global social network and a revolution in communication.",
            criticRating: 8.8,
            genres: ["Drama"],
            runtime: 120,
            cast: ["Jesse Eisenberg", "Andrew Garfield", "Justin Timberlake", "Rooney Mara"],
            listRankings: ["nytimes-100-21st-century": 7]
        ),
        Movie(
            id: "nyt8",
            title: "WALL·E",
            year: 2008,
            director: "Andrew Stanton",
            posterURL: "https://image.tmdb.org/t/p/w500/hbhFnRzzg6ZDmm8YAmxBnQpQIPh.jpg",
            overview: "WALL·E is the last robot left on an Earth that has been overrun with garbage and all humans have fled to outer space. For 700 years he has continued to try and clean up the planet, one piece of garbage at a time. But then, a new robot arrives - EVE. WALL·E falls in love with EVE. WALL·E rescues EVE from a dust storm and shows her a living plant he found amongst the garbage. Consistent with her 'directive', EVE takes the plant and automatically enters a deactivated state except for a blinking green beacon.",
            criticRating: 9.0,
            genres: ["Animation", "Family", "Science Fiction"],
            runtime: 98,
            cast: ["Ben Burtt", "Elissa Knight", "Jeff Garlin", "Fred Willard"],
            listRankings: ["nytimes-100-21st-century": 8]
        ),
        Movie(
            id: "nyt9",
            title: "Mulholland Drive",
            year: 2001,
            director: "David Lynch",
            posterURL: "https://image.tmdb.org/t/p/w500/oYEF00r6J5UQC6yUr8j9zj66TAC.jpg",
            overview: "After a car wreck on the winding Mulholland Drive renders a woman amnesiac, she and a perky Hollywood-hopeful search for clues and answers across Los Angeles in a twisting venture beyond dreams and reality.",
            criticRating: 8.7,
            genres: ["Drama", "Thriller", "Mystery"],
            runtime: 147,
            cast: ["Naomi Watts", "Laura Harring", "Justin Theroux", "Ann Miller"],
            listRankings: ["nytimes-100-21st-century": 9]
        ),
        Movie(
            id: "nyt10",
            title: "The Master",
            year: 2012,
            director: "Paul Thomas Anderson",
            posterURL: "https://image.tmdb.org/t/p/w500/pKIhKxZQz10Q3rvJ2PXgr5kLIv4.jpg",
            overview: "Freddie, a volatile, heavy-drinking veteran who suffers from post-traumatic stress disorder, finds some semblance of a family when he stumbles onto the ship of Lancaster Dodd, the charismatic leader of a new 'religion' he forms after World War II.",
            criticRating: 8.5,
            genres: ["Drama"],
            runtime: 137,
            cast: ["Joaquin Phoenix", "Philip Seymour Hoffman", "Amy Adams", "Laura Dern"],
            listRankings: ["nytimes-100-21st-century": 10]
        ),
        // For brevity, we're only including the top 10 here
        // In a real app, you would include all 100 movies
    ]
}
