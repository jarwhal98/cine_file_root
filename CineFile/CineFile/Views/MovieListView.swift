import SwiftUI

struct MovieListView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var selectedFilter = "All"
    @State private var ratingSheetMovie: Movie? = nil
    @State private var ratingSheetUserRating: Double = 0
    
    let filterOptions = ["All", "Watched", "Unwatched"]
    
    var filteredMovies: [Movie] {
        switch selectedFilter {
        case "Watched":
            return viewModel.movies.filter { $0.watched }
        case "Unwatched":
            return viewModel.movies.filter { !$0.watched }
        default:
            return viewModel.movies
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter control
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                List {
                    ForEach(filteredMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            MovieRowView(movie: movie)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                // Delete action would be implemented here
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.toggleWatchlist(for: movie)
                            } label: {
                                Label(movie.inWatchlist ? "Remove" : "Watchlist", 
                                      systemImage: movie.inWatchlist ? "bookmark.slash" : "bookmark")
                            }
                            .tint(.blue)
                            
                            Button {
                                if movie.watched {
                                    viewModel.toggleWatched(for: movie)
                                } else {
                                    viewModel.toggleWatched(for: movie)
                                    ratingSheetUserRating = movie.userRating ?? 0
                                    ratingSheetMovie = movie
                                }
                            } label: {
                                Label(movie.watched ? "Unwatched" : "Watched", 
                                      systemImage: movie.watched ? "eye.slash" : "eye")
                            }
                            .tint(.green)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("CineFile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Add new movie action
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Rating sheet for seen action
            .sheet(item: $ratingSheetMovie) { movie in
                let isPresentedBinding = Binding<Bool>(
                    get: { ratingSheetMovie != nil },
                    set: { newVal in if newVal == false { ratingSheetMovie = nil } }
                )
                MovieRatingView(movie: movie, userRating: $ratingSheetUserRating, isPresented: isPresentedBinding)
                    .environmentObject(viewModel)
            }
        }
    }
}
