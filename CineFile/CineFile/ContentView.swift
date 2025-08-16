import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MovieListView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
                .tag(0)
            
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "bookmark")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.red)
    }
}
