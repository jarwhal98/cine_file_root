import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search movies...", text: $searchText)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        viewModel.searchResults = []
                                    }) {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 10)
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                viewModel.searchMovies(query: newValue)
                            } else {
                                viewModel.searchResults = []
                            }
                        }
                }
                .padding(.top, 10)
                .padding(.horizontal, 8)
                
                // Error message (e.g., missing API key)
                if let error = viewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchText.isEmpty {
                    // Initial state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Search for Movies")
                            .font(.headline)
                        
                        Text("Enter a title to search for movies.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else if viewModel.searchResults.isEmpty {
                    // No results
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Results")
                            .font(.headline)
                        
                        Text("No movies found matching '\(searchText)'.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    // Results list
                    List {
                        ForEach(viewModel.searchResults) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieRowView(movie: movie)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.toggleWatchlist(for: movie)
                                } label: {
                                    Label(movie.inWatchlist ? "Remove" : "Add", 
                                          systemImage: movie.inWatchlist ? "bookmark.slash" : "bookmark")
                                }
                                .tint(.blue)
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
                }
            }
            .navigationTitle("Search")
        .background(AppColors.background.ignoresSafeArea())
        }
    }
}
