import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.watchlist.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Your Watchlist is Empty")
                            .font(.headline)
                        
                        Text("Movies you add to your watchlist will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.watchlist) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieRowView(movie: movie)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.toggleWatchlist(for: movie)
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash")
                                }
                            }
                            .swipeActions(edge: .leading) {
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
            .listRowSeparator(.hidden)
            .hideScrollBackground()
            .background(AppColors.background)
                }
            }
            .navigationTitle("Watchlist")
        .background(AppColors.background.ignoresSafeArea())
        }
    }
}
