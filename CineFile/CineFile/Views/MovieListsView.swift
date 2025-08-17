import SwiftUI

struct MovieListsView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var showingListSelector = false
    @State private var ratingSheetMovie: Movie? = nil
    @State private var ratingSheetUserRating: Double = 0
    @Namespace private var filterNamespace
    @State private var filterPulse = false
    private var appBackground: Color { AppColors.background }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Movies list (header is pinned via safeAreaInset)
                List {
                    if viewModel.selectedList != nil {
                        ForEach(viewModel.selectedListMovies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieListRowView(
                                    movie: movie,
                                    listID: viewModel.selectedList?.id,
                                    toggleSeen: {
                                        if !movie.watched { viewModel.toggleWatched(for: movie) }
                                        ratingSheetUserRating = movie.userRating ?? 0
                                        ratingSheetMovie = movie
                                    }
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(appBackground)
                            .overlay(Rectangle().fill(appBackground).frame(height: 0.001), alignment: .bottom)
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
                }
                .listStyle(PlainListStyle())
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                .hideScrollBackground()
                .adaptiveListRowSpacing(0)
                .listRowBackground(appBackground)
                .legacyListBackground(appBackground)
                .background(appBackground)
                // Fully pinned header (title + progress + filters)
                .safeAreaInset(edge: .top) {
                    if let selectedList = viewModel.selectedList {
                        VStack(spacing: 4) {
                            // Title selector
                            Button(action: { showingListSelector = true }) {
                                HStack(spacing: 6) {
                                    Spacer(minLength: 0)
                                    Text(selectedList.name)
                                        .font(.system(.title2, design: .serif))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Image(systemName: "chevron.down")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer(minLength: 0)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // Progress
                            let (watched, total) = viewModel.calculateListCompletion(for: selectedList.id)
                            let progress = viewModel.calculateListProgress(for: selectedList.id)
                            VStack(spacing: 2) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color(.systemGray5).opacity(0.9))
                                            .frame(width: geometry.size.width, height: 6)
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color(.systemGray3))
                                            .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                Text("\(watched) of \(total) watched (\(Int(progress * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            // Filters with sliding glass bubble + pulse
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MovieSortOption.allCases, id: \.self) { option in
                                        let isSelected = viewModel.sortOption == option
                                        Button(action: { viewModel.setSortOption(option) }) {
                                            ZStack {
                                                if isSelected {
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .fill(.ultraThinMaterial)
                                                        // Subtle accent tint to match app palette
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                                .fill(Color.accentColor.opacity(0.08))
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                                                        )
                                                        .matchedGeometryEffect(id: "filterBubble", in: filterNamespace)
                                                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                                }
                                                HStack(spacing: 6) {
                                                    Text(option.rawValue)
                                                        .font(.subheadline)
                                                        .fontWeight(isSelected ? .semibold : .regular)
                                                    if isSelected {
                                                        Text(viewModel.isEffectiveAscending(for: option) ? "▲" : "▼")
                                                            .font(.caption2)
                                                            .accessibilityHidden(true)
                                                    }
                                                }
                                                .padding(.horizontal, 14)
                                            }
                                            .scaleEffect(isSelected && filterPulse ? 1.06 : 1.0)
                                            .frame(height: 32)
                                            .fixedSize()
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.primary)
                                        .contentShape(Rectangle())
                                        .accessibilityLabel("Sort by \(option.rawValue) \(viewModel.isEffectiveAscending(for: option) ? "ascending" : "descending")")
                                    }
                                }
                                .frame(height: 40)
                                .padding(.horizontal)
                                .padding(.vertical, 0)
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: viewModel.sortOption)
                            .onChange(of: viewModel.sortOption) { _ in
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { filterPulse = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { filterPulse = false }
                                }
                            }
                        }
                        .padding(.top, 0)
                        .padding(.bottom, 0)
                        .background(
                            ZStack {
                                // Base glass material at current opacity
                                Rectangle().fill(.regularMaterial).opacity(0.82)
                                // Opacity ramp: clearer near filters, more opaque toward the top (CineFile title)
                                LinearGradient(
                                    colors: [
                                        AppColors.background.opacity(0.00),
                                        AppColors.background.opacity(0.06),
                                        AppColors.background.opacity(0.12),
                                        AppColors.background.opacity(0.18),
                                        AppColors.background.opacity(0.22)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            }
                        )
                    }
                }
            }
            .navigationTitle("CineFile")
            .navigationBarTitleDisplayMode(.inline)
            .navBarBackground(appBackground)
            .sheet(isPresented: $showingListSelector) {
                ListSelectorView(isPresented: $showingListSelector)
            }
            .sheet(item: $ratingSheetMovie) { movie in
                let isPresentedBinding = Binding<Bool>(
                    get: { ratingSheetMovie != nil },
                    set: { newVal in if newVal == false { ratingSheetMovie = nil } }
                )
                MovieRatingView(movie: movie, userRating: $ratingSheetUserRating, isPresented: isPresentedBinding)
                    .environmentObject(viewModel)
            }
            .background(appBackground.ignoresSafeArea())
        }
    }
}

struct MovieListRowView: View {
    let movie: Movie
    var listID: String? = nil
    var toggleSeen: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank indicator (prefer rank for selected list; fallback to best rank across lists)
            let rankValue: Int? = {
                if let id = listID, id != MovieViewModel.allListsID {
                    return movie.listRankings[id]
                } else {
                    return movie.listRankings.values.min()
                }
            }()
            if let rank = rankValue {
                Text("#\(rank)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 44, alignment: .trailing)
                    .foregroundColor(.primary)
                    .accessibilityLabel("Rank \(rank)")
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
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.card)
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
        .compositingGroup()
        .padding(.vertical, 8)
        .listRowBackground(AppColors.background)
        .listRowSeparator(.hidden)
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
                                .foregroundColor(.secondary)
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            .listRowSeparator(.hidden)
            .hideScrollBackground()
            .background(AppColors.background)
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
        .background(AppColors.background)
    }
}
