import Foundation

// MARK: - Navigation Action

/// A declarative description of a navigation mutation.
///
/// Actions are the single entry point for all navigation state changes.
/// This makes navigation deterministic, testable, and loggable.
public enum NavigationAction<R: Route>: Sendable {

    /// Push a route onto the navigation stack.
    case push(R)

    /// Present a route modally using the given style.
    case present(R, style: PresentationStyle)

    /// Pop one or more routes from the navigation stack.
    /// When `count` is 1 (default), pops just the top route.
    case pop(count: Int = 1)

    /// Pop to the root of the navigation stack.
    case popToRoot

    /// Pop to a specific route in the navigation stack.
    case popTo(R)

    /// Dismiss the currently presented modal (sheet or full-screen cover).
    case dismiss

    /// Reset navigation to its initial state: dismiss all modals and pop to root.
    case reset

    /// Replace the entire navigation stack with the provided routes.
    case setStack([R])
}
