import SwiftUI

@main
struct CineFileApp: App {
    @StateObject private var viewModel = MovieViewModel()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                } else {
                    // Use the main ContentView with the shared view model
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.35), value: showSplash)
            .accentColor(.red)
            .environmentObject(viewModel)
            .onAppear {
                AppTheme.applyAppearance()
                // Kick off first-launch preload; Splash will show progress
                viewModel.startInitialPreloadIfNeeded()
            }
        }
    }
}
