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

// iOS 15 List background helper: Ensure UITableView background matches our theme and cells are clear
struct LegacyListBackground: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .onAppear {
                if #available(iOS 16.0, *) {
                    // iOS 16+ handled by scrollContentBackground + listRowBackground
                } else {
                    #if os(iOS)
                    let uiColor = UIColor(color)
                    DispatchQueue.main.async {
                        UITableView.appearance().backgroundColor = uiColor
                        UITableView.appearance().separatorColor = uiColor
                        UITableViewCell.appearance().backgroundColor = .clear
                        UITableViewHeaderFooterView.appearance().tintColor = uiColor
                    }
                    #endif
                }
            }
    }
}

extension View {
    func legacyListBackground(_ color: Color) -> some View { self.modifier(LegacyListBackground(color: color)) }
}
