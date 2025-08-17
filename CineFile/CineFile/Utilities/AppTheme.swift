import SwiftUI
#if os(iOS)
import UIKit
#endif

// Centralized colors and lightweight UI helpers used across views
enum AppColors {
    // Solarized Base2: #EEE8D5
    static let background = Color(red: 238/255, green: 232/255, blue: 213/255)
    // If we want cards to match the background exactly per latest direction
    static let card = background
}

enum AppTheme {
    static func applyAppearance() {
        #if os(iOS)
        let bg = UIColor(red: 238/255, green: 232/255, blue: 213/255, alpha: 1)
        if #available(iOS 15.0, *) {
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = bg
            navAppearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance

            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithOpaqueBackground()
            tabAppearance.backgroundColor = bg
            tabAppearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance = tabAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        } else {
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().barTintColor = bg
            UINavigationBar.appearance().backgroundColor = bg
            UITabBar.appearance().isTranslucent = false
            UITabBar.appearance().barTintColor = bg
            UITabBar.appearance().backgroundColor = bg
        }
        #endif
    }
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

// Set a solid navigation bar background color (iOS 16+) to match the app theme
struct NavBarBackground: ViewModifier {
    let color: Color
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

extension View {
    func navBarBackground(_ color: Color) -> some View { self.modifier(NavBarBackground(color: color)) }
}
