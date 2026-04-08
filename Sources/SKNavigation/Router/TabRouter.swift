import SwiftUI
import Observation
import SKCore

// MARK: - Tab Protocol

/// Represents a tab in the application's tab bar.
///
/// Each app defines its own `Tab` enum conforming to this protocol.
///
/// Example:
/// ```swift
/// enum AppTab: String, Tab {
///     case home, search, favorites, profile
///
///     var title: String { rawValue.capitalized }
///     var icon: String {
///         switch self {
///         case .home:      "house"
///         case .search:    "magnifyingglass"
///         case .favorites: "heart"
///         case .profile:   "person.circle"
///         }
///     }
/// }
/// ```
public protocol Tab: Hashable, Identifiable, CaseIterable, Sendable {

    /// The display title for this tab.
    var title: String { get }

    /// The SF Symbol name for this tab's icon.
    var icon: String { get }

    /// The accessibility label for this tab. Defaults to ``title``.
    var accessibilityLabel: String { get }

    /// Optional badge value for this tab.
    var badge: String? { get }
}

extension Tab {
    public var id: Self { self }
    public var accessibilityLabel: String { title }
    public var badge: String? { nil }
}

// MARK: - Tab Router

/// Observable state container for tab-based navigation.
///
/// Manages the currently selected tab and provides utilities for
/// programmatic tab switching, including re-tap-to-root behavior.
@Observable
@MainActor
public final class TabRouter<T: Tab> {

    // MARK: - State

    /// The currently selected tab.
    public private(set) var selectedTab: T

    /// The previously selected tab, useful for transition animations.
    public private(set) var previousTab: T?

    /// Set to `true` when the user taps the already-selected tab.
    ///
    /// Coordinators should observe this and call ``popToRoot()`` (or similar)
    /// when it becomes `true`. The flag auto-resets to `false` after being read
    /// via ``consumeRetap()``, or on the next tab switch.
    ///
    /// This one-shot design prevents count drift from accumulated re-taps
    /// when a coordinator doesn't respond to every re-tap event.
    public private(set) var didRetap: Bool = false

    /// Whether the tab bar is currently hidden.
    /// Updated by ``TabCoordinatedView`` based on the active route's ``Route/hidesTabBar``.
    public var isTabBarHidden: Bool = false

    // MARK: - Logging

    private let logger: any LoggerProtocol

    // MARK: - Lifecycle

    public init(
        initialTab: T,
        logger: any LoggerProtocol = OSLogLogger(subsystem: "SKNavigation", category: "TabRouter")
    ) {
        self.selectedTab = initialTab
        self.logger = logger
    }

    // MARK: - Actions

    /// Selects a tab. If the tab is already selected, flags a re-tap event.
    ///
    /// When the same tab is tapped again, ``didRetap`` becomes `true`.
    /// Coordinators should observe ``didRetap`` and call
    /// ``consumeRetap()`` after handling the event.
    public func select(_ tab: T) {
        if tab == selectedTab {
            didRetap = true
            logger.debug("Re-tapped tab: \(String(describing: tab))")
        } else {
            previousTab = selectedTab
            selectedTab = tab
            didRetap = false
            logger.debug("Switched tab: \(String(describing: tab))")
        }
    }

    /// Acknowledges and clears the re-tap flag.
    ///
    /// Call this after handling a re-tap event (e.g., after popping to root)
    /// to prevent duplicate handling.
    public func consumeRetap() {
        didRetap = false
    }
}
