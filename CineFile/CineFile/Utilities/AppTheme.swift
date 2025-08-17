import SwiftUI

// Centralized colors and lightweight UI helpers used across views
enum AppColors {
    // Solarized Base2: #EEE8D5
    static let background = Color(red: 238/255, green: 232/255, blue: 213/255)
    // If we want cards to match the background exactly per latest direction
    static let card = background
}

// Hide the default scrollable background (List/Form/ScrollView) on iOS 16+
struct HideScrollBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func hideScrollBackground() -> some View { self.modifier(HideScrollBackground()) }
}
