import Foundation

// MARK: - Route Protocol

/// A type-safe navigation destination.
///
/// Each feature module defines its own `Route` enum conforming to this protocol.
/// Routes carry all the data needed to construct the destination view.
///
/// Example:
/// ```swift
/// enum SettingsRoute: Route {
///     case general
///     case notifications
///     case privacy(userId: String)
///
///     var hidesTabBar: Bool {
///         switch self {
///         case .privacy: return true
///         default: return false
///         }
///     }
/// }
/// ```
public protocol Route: Hashable, Identifiable, Sendable {

    /// Whether this route should hide the tab bar when displayed.
    ///
    /// Override this in your route enum to hide the tab bar for specific destinations.
    /// Defaults to `false`.
    var hidesTabBar: Bool { get }
}

// MARK: - Default Implementations

extension Route {

    /// Stable identity derived from the route's string representation.
    ///
    /// Uses `String(describing:)` instead of `hashValue` because Swift's
    /// hash values are randomized per process and are not stable across
    /// app launches — making them unsuitable for `NavigationStack` identity
    /// and state restoration.
    ///
    /// Override this in your concrete route if you need a custom identity scheme.
    public var id: String { String(describing: self) }

    /// Tab bar is visible by default.
    public var hidesTabBar: Bool { false }
}
