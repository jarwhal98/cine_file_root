import SwiftUI

struct MovieListView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var selectedFilter = "All"
    
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
                                viewModel.toggleWatched(for: movie)
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
        }
    }
}
