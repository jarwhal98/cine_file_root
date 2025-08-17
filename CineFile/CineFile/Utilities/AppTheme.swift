import SwiftUI
#if os(iOS)
import UIKit
#endif

// Centralized colors and lightweight UI helpers used across views
enum AppColors {
    // New theme: backgrounds #F5F5F5, cards #EFEFEF
    static let background = Color(red: 245/255, green: 245/255, blue: 245/255) // #F5F5F5
    static let card = Color(red: 239/255, green: 239/255, blue: 239/255) // #EFEFEF
}

    extension View {
        // Opt-in glass background convenience for headers
        func glassHeaderBackground() -> some View {
            self.background(.ultraThinMaterial)
        }
    }
enum AppTheme {
    static func applyAppearance() {
        #if os(iOS)
    let bg = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1) // #F5F5F5
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

        // Ensure SwiftUI List (UITableView) matches theme and has no separators
        UITableView.appearance().backgroundColor = bg
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = bg
        UITableViewCell.appearance().backgroundColor = .clear
        UITableViewHeaderFooterView.appearance().tintColor = bg
        #endif
    }
}

// iOS 16+: Control spacing between List rows. No-op on earlier versions.
struct AdaptiveListRowSpacing: ViewModifier {
    let spacing: CGFloat
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.listRowSpacing(spacing)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveListRowSpacing(_ spacing: CGFloat) -> some View { self.modifier(AdaptiveListRowSpacing(spacing: spacing)) }
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
