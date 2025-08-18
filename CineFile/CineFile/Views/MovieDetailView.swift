import SwiftUI

struct MovieDetailView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @Environment(\.dismiss) private var dismiss
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
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.7))
                                        .cornerRadius(4)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            let headerYear = String(updatedMovie.year)
                            Text(verbatim: "\(headerYear) • \(updatedMovie.runtime) min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            if !updatedMovie.director.isEmpty {
                                Text(updatedMovie.director)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
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
                // Top overlay with custom Back and Rate buttons
                .overlay(alignment: .top) {
                    GeometryReader { geo in
                        let topInset = geo.safeAreaInsets.top
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }

                            Spacer()

                            Button(action: { isShowingRatingSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                    Text("Rate")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, max(topInset, 12))
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                    }
                    .frame(height: 0) // use only for insets; content is positioned by padding
                }
                .zIndex(1)
                
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
                                HStack(spacing: 8) {
                                    Text("#\(rank)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(width: 44, alignment: .trailing)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Text(list.name)
                                        .font(.subheadline)
                                    SourceChip(text: list.source)
                                    Spacer()
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
                                        
                                        Text(verbatim: String(movie.year))
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
    .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingRatingSheet) {
            MovieRatingView(movie: updatedMovie, userRating: $userRating, isPresented: $isShowingRatingSheet)
                .background(AppColors.background)
        }
        // Make nav bar background transparent to avoid white strip at the top
        .onAppear {
            if #available(iOS 16.0, *) {
                // Use hidden toolbar background on iOS 16+
                UINavigationBar.appearance().scrollEdgeAppearance = {
                    let a = UINavigationBarAppearance()
                    a.configureWithTransparentBackground()
                    a.backgroundColor = .clear
                    a.shadowColor = .clear
                    return a
                }()
                UINavigationBar.appearance().standardAppearance = UINavigationBar.appearance().scrollEdgeAppearance!
            } else {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                // Header image (poster)
                AsyncImage(url: URL(string: movie.posterURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
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
                    .multilineTextAlignment(.leading)

                let sheetYear = String(movie.year)
                Text(verbatim: movie.director.isEmpty ? sheetYear : "\(sheetYear) • \(movie.director)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Drag or Tap to Rate (half-stars)")
                    .font(.headline)

                // Ten stars with half-star tap detection
                StarRatingView(rating: $userRating)
                    .padding(.vertical, 4)

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
                        DatePicker(
                            "Watched on",
                            selection: Binding(
                                get: { watchedDate ?? tempDate },
                                set: { d in watchedDate = d; tempDate = d }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                }
                // end main VStack
            }
            // end ScrollView
            .padding()
            .navigationTitle("Rate This Movie")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Save") {
                    if userRating > 0 { viewModel.rateMovie(movie, rating: userRating) }
                    if let d = watchedDate {
                        if viewModel.fetchMovieDetails(id: movie.id)?.watched == false {
                            viewModel.toggleWatched(for: movie)
                        }
                        viewModel.setWatchedDate(for: movie, date: d)
                    }
                    isPresented = false
                }
            )
    }
    .background(AppColors.background)
    }
}

// MARK: - Compact 10-star rating with half-star taps
private struct StarRatingView: View {
    @Binding var rating: Double // 0...10 in 0.5 steps
    var maxStars: Int = 10
    var starSize: CGFloat = 26
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<maxStars, id: \.self) { index in
                StarView(index: index, rating: $rating)
                    .frame(width: starSize, height: starSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(String(format: "%.1f out of 10", rating))
        // Allow sliding across the entire row to adjust rating
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateRating(at: value.location.x, width: geo.size.width)
                            }
                            .onEnded { value in
                                updateRating(at: value.location.x, width: geo.size.width)
                            }
                    )
            }
        )
    }

    private func updateRating(at x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let clampedX = min(max(0, x), width)
        let proportion = clampedX / width
        let rawStars = Double(proportion) * Double(maxStars)
        let halfSteps = (rawStars * 2.0).rounded() // nearest 0.5
        let newRating = min(Double(maxStars), max(0.0, halfSteps / 2.0))
        rating = newRating
    }
}

private struct StarView: View {
    let index: Int
    @Binding var rating: Double

    var body: some View {
        let fullThreshold = Double(index) + 1.0
        let symbol = rating >= fullThreshold
            ? "star.fill"
            : (rating >= fullThreshold - 0.5 ? "star.leadinghalf.filled" : "star")

        Image(systemName: symbol)
            .font(.title2)
            .foregroundColor((rating >= fullThreshold - 0.5) ? .yellow : .gray)
    }
}
