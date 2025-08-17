import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Color.clear.frame(height: 4).listRowBackground(AppColors.background)
                        ForEach(viewModel.watchlist) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieRowView(movie: movie)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(AppColors.background)
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
                    .listSectionSeparator(.hidden)
                    .hideScrollBackground()
                    .listRowBackground(AppColors.background)
                    .legacyListBackground(AppColors.background)
                    .background(AppColors.background)
                    .safeAreaInset(edge: .top) {
                        // Keep consistent top cap color under nav bar
                        Rectangle().fill(AppColors.background).frame(height: 0.5)
                    }
                }
            }
            .navigationTitle("Watchlist")
            .navBarBackground(AppColors.background)
        }
    }
}
