import SwiftUI

@main
struct CineFileApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MovieViewModel())
        }
    }
}
