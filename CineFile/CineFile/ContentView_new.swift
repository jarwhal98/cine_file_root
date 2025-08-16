import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @State private var selectedTab = 0
    @AppStorage("defaultTab") private var defaultTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Use a text placeholder instead of MovieListsView for now
            NavigationView {
                Text("Movie Lists")
                    .navigationTitle("Movie Lists")
            }
            .tabItem {
                Label("Lists", systemImage: "list.bullet")
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
        .onAppear {
            // Set the selected tab to the default tab when the app launches
            selectedTab = defaultTab
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MovieViewModel())
    }
}
