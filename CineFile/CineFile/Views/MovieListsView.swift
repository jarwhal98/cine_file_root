import SwiftUI

struct MovieListsView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var showingListSelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with list selection and progress
                if let selectedList = viewModel.selectedList {
                    VStack(spacing: 16) {
                        // List title and selection button
                        Button(action: {
                            showingListSelector = true
                        }) {
                            HStack {
                                Text(selectedList.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        }
                        
                        // Progress indicator
                        let (watched, total) = viewModel.calculateListCompletion(for: selectedList.id)
                        let progress = viewModel.calculateListProgress(for: selectedList.id)
                        
                        VStack(spacing: 8) {
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .foregroundColor(Color(.systemGray5))
                                        .frame(width: geometry.size.width, height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .foregroundColor(Color.red)
                                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            // Completion text
                            Text("\(watched) of \(total) watched (\(Int(progress * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    
                    // Sort options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MovieSortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    viewModel.setSortOption(option)
                                }) {
                                    Text(option.rawValue)
                                        .font(.caption)
                                        .fontWeight(viewModel.sortOption == option ? .bold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            viewModel.sortOption == option ?
                                                Color.red.opacity(0.2) :
                                                Color(.systemGray6)
                                        )
                                        .cornerRadius(15)
                                        .foregroundColor(viewModel.sortOption == option ? .red : .primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                }
                
                // Movie list
                List {
                    ForEach(viewModel.selectedListMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            MovieListRowView(movie: movie, toggleSeen: {
                                viewModel.toggleWatched(for: movie)
                            })
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                viewModel.toggleWatchlist(for: movie)
                            } label: {
                                Label(movie.inWatchlist ? "Remove" : "Watchlist", 
                                      systemImage: movie.inWatchlist ? "bookmark.slash" : "bookmark")
                            }
                            .tint(.blue)
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
            }
            .navigationTitle("CineFile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingListSelector) {
                ListSelectorView(isPresented: $showingListSelector)
            }
        }
    }
}

struct MovieListRowView: View {
    let movie: Movie
    var toggleSeen: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank indicator (if available)
            if let rank = movie.listRankings.values.first {
                Text("#\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 30)
                    .foregroundColor(.red)
            }
            
            // Movie poster
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 90)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(movie.year) • \(movie.director)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Runtime and genres
                Text("\(movie.runtime) min • \(movie.genres.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Status indicators
                HStack(spacing: 10) {
                    // Seen toggle (icon only)
                    if let toggleSeen {
                        Button(action: toggleSeen) {
                            Image(systemName: movie.watched ? "eye.fill" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // Critic rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", movie.criticRating))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // User rating if available
                    if let userRating = movie.userRating {
                        HStack(spacing: 2) {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(String(format: "%.1f", userRating))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Watched status
                    if movie.watched {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Watched")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Watchlist status
                    if movie.inWatchlist {
                        HStack(spacing: 2) {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Watchlist")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ListSelectorView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    viewModel.selectList(MovieViewModel.allListsID)
                    isPresented = false
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All Lists")
                                .font(.headline)
                            let (watched, total) = viewModel.calculateListCompletion(for: MovieViewModel.allListsID)
                            Text("\(watched)/\(total) watched • Combined")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedList?.id == MovieViewModel.allListsID {
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                ForEach(viewModel.movieLists) { list in
                    Button(action: {
                        viewModel.selectList(list.id)
                        isPresented = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.name)
                                    .font(.headline)
                                
                                Text(list.source)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                let (watched, total) = viewModel.calculateListCompletion(for: list.id)
                                Text("\(watched)/\(total) watched • \(list.year)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedList?.id == list.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
