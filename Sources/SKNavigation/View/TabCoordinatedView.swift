import SwiftUI

// MARK: - Tab Coordinated View

/// A SwiftUI view that wires a ``TabCoordinator`` to a `TabView`.
///
/// Handles tab selection binding, re-tap-to-root behavior, and route-based
/// tab bar visibility automatically.
///
/// The tab bar visibility is driven by the ``Route/hidesTabBar`` property of the
/// currently active route in each tab's navigation stack. When any tab's top route
/// has `hidesTabBar == true`, the tab bar is hidden.
///
/// Example:
/// ```swift
/// @main
/// struct MyApp: App {
///     @State private var appCoordinator = AppCoordinator()
///
///     var body: some Scene {
///         WindowGroup {
///             TabCoordinatedView(coordinator: appCoordinator)
///         }
///     }
/// }
/// ```
public struct TabCoordinatedView<C: TabCoordinator>: View {

    // MARK: - Properties

    private let coordinator: C

    // MARK: - Lifecycle

    public init(coordinator: C) {
        self.coordinator = coordinator
    }

    // MARK: - Body

    public var body: some View {
        TabView(selection: Binding(
            get: { coordinator.tabRouter.selectedTab },
            set: { coordinator.tabRouter.select($0) }
        )) {
            ForEach(Array(C.TabType.allCases), id: \.id) { tab in
                coordinator.coordinatorView(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                            .accessibilityLabel(tab.accessibilityLabel)
                    }
                    .tag(tab)
                    .badgeIfAvailable(tab.badge)
            }
        }
        #if os(iOS)
        .applyTabBarVisibility(isHidden: coordinator.tabRouter.isTabBarHidden)
        #endif
    }
}

// MARK: - Tab Bar Visibility

#if os(iOS)
extension View {

    /// Hides or shows the tab bar using `toolbarVisibility` on iOS 18+.
    /// On iOS 17 this is a no-op — the tab bar remains visible.
    @ViewBuilder
    fileprivate func applyTabBarVisibility(isHidden: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.toolbarVisibility(isHidden ? .hidden : .visible, for: .tabBar)
        } else {
            self
        }
    }
}
#endif

// MARK: - Badge Modifier

extension View {

    /// Applies a badge only when the value is non-nil.
    @ViewBuilder
    fileprivate func badgeIfAvailable(_ value: String?) -> some View {
        if let value {
            self.badge(value)
        } else {
            self
        }
    }
}
