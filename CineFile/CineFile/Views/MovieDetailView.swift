import SwiftUI

struct MovieDetailView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    let movie: Movie
    
    @State private var isShowingRatingSheet = false
    @State private var userRating: Double = 0
    @State private var updatedMovie: Movie
    
    init(movie: Movie) {
        self.movie = movie
        self._updatedMovie = State(initialValue: movie)
        self._userRating = State(initialValue: movie.userRating ?? 0)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with poster and basic info
                ZStack(alignment: .bottom) {
                    // Background image (blurred poster)
                    AsyncImage(url: URL(string: updatedMovie.posterURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .blur(radius: 10)
                        default:
                            Color.gray.opacity(0.3)
                                .frame(height: 200)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 100)
                    
                    // Movie info overlay
                    HStack(alignment: .bottom, spacing: 15) {
                        // Poster
                        AsyncImage(url: URL(string: updatedMovie.posterURL)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 180)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 5)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 180)
                                    .overlay(Image(systemName: "photo"))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 120, height: 180)
                        .padding(.bottom, 15)
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(updatedMovie.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                // Show rank if this movie is part of a list
                                if let listID = viewModel.selectedList?.id,
                                   let rank = updatedMovie.listRankings[listID] {
                                    Text("#\(rank)")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.7))
                                        .cornerRadius(4)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("\(updatedMovie.year) • \(updatedMovie.runtime) min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(updatedMovie.director)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Ratings
                            HStack {
                                // Critic rating
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", updatedMovie.criticRating))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                // User rating if available
                                if updatedMovie.userRating != nil {
                                    HStack {
                                        Image(systemName: "person.fill.checkmark")
                                            .foregroundColor(.orange)
                                        Text(String(format: "%.1f", updatedMovie.userRating!))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Button {
                                    isShowingRatingSheet = true
                                } label: {
                                    Text("Rate")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.bottom, 15)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button {
                        viewModel.toggleWatchlist(for: updatedMovie)
                        updatedMovie.inWatchlist.toggle()
                    } label: {
                        VStack {
                            Image(systemName: updatedMovie.inWatchlist ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                            Text(updatedMovie.inWatchlist ? "In Watchlist" : "Add to Watchlist")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        viewModel.toggleWatched(for: updatedMovie)
                        updatedMovie.watched.toggle()
                        if updatedMovie.watched { isShowingRatingSheet = true }
                    } label: {
                        VStack {
                            Image(systemName: updatedMovie.watched ? "eye.fill" : "eye")
                                .font(.title2)
                            Text(" ")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        // Share functionality would be implemented here
                    } label: {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Genres
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(movie.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Overview")
                        .font(.headline)
                    
                    Text(updatedMovie.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // Cast section (if available)
                if !updatedMovie.cast.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cast")
                            .font(.headline)
                        
                        Text(updatedMovie.cast.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Lists this movie appears on
                if !updatedMovie.listRankings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Featured In")
                            .font(.headline)
                        
                        ForEach(viewModel.movieLists.filter { list in
                            updatedMovie.listRankings.keys.contains(list.id)
                        }, id: \.id) { list in
                            if let rank = updatedMovie.listRankings[list.id] {
                                HStack {
                                    Text("#\(rank)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .frame(width: 40)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Text(list.name)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text(String(list.year))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Similar movies would go here in a real app
                VStack(alignment: .leading, spacing: 10) {
                    Text("Similar Movies")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.movies.filter { $0.id != updatedMovie.id }.prefix(5)) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(alignment: .leading) {
                                        AsyncImage(url: URL(string: movie.posterURL)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 150)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            default:
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 100, height: 150)
                                                    .overlay(Image(systemName: "photo"))
                                            }
                                        }
                                        .frame(width: 100, height: 150)
                                        
                                        Text(movie.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 100, alignment: .leading)
                                        
                                        Text(String(movie.year))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingRatingSheet = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Rate")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingRatingSheet) {
            MovieRatingView(movie: updatedMovie, userRating: $userRating, isPresented: $isShowingRatingSheet)
        }
    }
}

struct MovieRatingView: View {
    let movie: Movie
    @Binding var userRating: Double
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var watchedDate: Date? = nil
    @State private var tempDate: Date = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: movie.posterURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo"))
                    }
                }
                .frame(height: 200)
                .padding(.top)
                
                Text(movie.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(movie.year) • \(movie.director)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Tap to Rate (half-stars)")
                    .font(.headline)
                    .padding(.top)
                
                // Star rating in 0.5 increments (0..10)
                HStack(spacing: 8) {
                    ForEach(0..<20, id: \.self) { idx in
                        let value = Double(idx + 1) * 0.5
                        let symbol: String
                        if userRating >= value {
                            symbol = (value.truncatingRemainder(dividingBy: 1.0) == 0) ? "star.fill" : "star.leadinghalf.filled"
                        } else {
                            symbol = "star"
                        }
                        Image(systemName: symbol)
                            .font(.title2)
                            .foregroundColor(userRating >= value ? .yellow : .gray)
                            .onTapGesture { userRating = value }
                    }
                }
                .padding()
                
                Text(String(format: "Your Rating: %.1f / 10", userRating))
                    .font(.title3)
                    .fontWeight(.semibold)

                // Optional watched date
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Add watched date", isOn: Binding(
                        get: { watchedDate != nil },
                        set: { on in watchedDate = on ? tempDate : nil }
                    ))
                    if watchedDate != nil {
                        DatePicker("Watched on", selection: Binding(get: { watchedDate ?? tempDate }, set: { d in watchedDate = d; tempDate = d }), displayedComponents: .date)
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rate This Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if userRating > 0 {
                            viewModel.rateMovie(movie, rating: userRating)
                        }
                        if let d = watchedDate {
                            // ensure watched is toggled on and store date
                            if viewModel.fetchMovieDetails(id: movie.id)?.watched == false {
                                viewModel.toggleWatched(for: movie)
                            }
                            viewModel.setWatchedDate(for: movie, date: d)
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}
