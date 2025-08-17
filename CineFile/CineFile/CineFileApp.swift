import SwiftUI

@main
struct CineFileApp: App {
    @StateObject private var viewModel = MovieViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Use the main ContentView with the shared view model
            ContentView()
                .accentColor(.red)
                .environmentObject(viewModel)
                .onAppear { AppTheme.applyAppearance() }
        }
    }
}
