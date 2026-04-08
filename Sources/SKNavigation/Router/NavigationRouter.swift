import SwiftUI
import Observation
import SKCore

// MARK: - Navigation Router

/// Observable navigation state container for a single coordinator's flow.
///
/// `NavigationRouter` owns the navigation stack (for push/pop) and the modal
/// presentation state (sheet and full-screen cover). It is the single source
/// of truth for a coordinator's navigation hierarchy.
///
/// - Important: All mutations go through ``navigate(to:)`` to ensure
///   centralized, predictable state changes.
@Observable
@MainActor
public final class NavigationRouter<R: Route> {

    // MARK: - State

    /// The current navigation stack. Drives `NavigationStack(path:)`.
    public private(set) var path: [R] = []

    /// The currently presented sheet route, if any.
    public var sheet: R?

    /// The currently presented full-screen cover route, if any.
    public var fullScreenCover: R?

    /// The sheet configuration for the currently presented sheet.
    /// Set automatically when presenting with ``PresentationStyle/sheet(_:)``.
    public private(set) var currentSheetConfiguration: SheetConfiguration?

    /// An optional callback invoked on every navigation action.
    /// Use for analytics, logging, or debugging navigation flows.
    public var onNavigationAction: ((NavigationAction<R>) -> Void)?

    // MARK: - Logging

    private let logger: any LoggerProtocol

    // MARK: - Lifecycle

    public init(
        logger: any LoggerProtocol = OSLogLogger(subsystem: "SKNavigation", category: "Router")
    ) {
        self.logger = logger
    }

    // MARK: - Navigation

    /// Performs a navigation action, mutating the router's state.
    ///
    /// - Parameter action: The navigation action to perform.
    public func navigate(to action: NavigationAction<R>) {
        logger.debug("Navigate: \(String(describing: action))")
        onNavigationAction?(action)

        switch action {
        case .push(let route):
            path.append(route)

        case .present(let route, let style):
            switch style {
            case .push:
                logger.warning("present(_:style: .push) converts to a push operation. Use .push(\(String(describing: route))) directly for clarity.")
                path.append(route)
            case .sheet(let configuration):
                currentSheetConfiguration = configuration
                sheet = route
            case .fullScreenCover:
                #if os(macOS)
                logger.warning("fullScreenCover is not supported on macOS. Falling back to sheet presentation.")
                currentSheetConfiguration = .default
                sheet = route
                #else
                currentSheetConfiguration = nil
                fullScreenCover = route
                #endif
            }

        case .pop(count: let count):
            let removals = min(count, path.count)
            guard removals > 0 else {
                logger.warning("Attempted to pop \(count) items from a stack of \(self.path.count).")
                return
            }
            path.removeLast(removals)

        case .popToRoot:
            path.removeAll()

        case .popTo(let route):
            guard let index = path.lastIndex(of: route) else {
                logger.warning("Attempted to pop to route not in stack: \(String(describing: route))")
                return
            }
            path = Array(path[...index])

        case .dismiss:
            if fullScreenCover != nil {
                fullScreenCover = nil
            } else if sheet != nil {
                sheet = nil
                currentSheetConfiguration = nil
            }

        case .reset:
            fullScreenCover = nil
            sheet = nil
            currentSheetConfiguration = nil
            path.removeAll()

        case .setStack(let routes):
            path = routes
        }
    }

    // MARK: - Convenience

    /// Pushes a route onto the navigation stack.
    public func push(_ route: R) {
        navigate(to: .push(route))
    }

    /// Pops one or more routes from the navigation stack.
    public func pop(count: Int = 1) {
        navigate(to: .pop(count: count))
    }

    /// Pops to the root of the navigation stack.
    public func popToRoot() {
        navigate(to: .popToRoot)
    }

    /// Pops to a specific route in the navigation stack.
    ///
    /// If the route is not found in the stack, this is a no-op.
    public func popTo(_ route: R) {
        navigate(to: .popTo(route))
    }

    /// Presents a route modally with the given style.
    public func present(_ route: R, as style: PresentationStyle = .sheet()) {
        navigate(to: .present(route, style: style))
    }

    /// Dismisses the topmost modal presentation.
    public func dismiss() {
        navigate(to: .dismiss)
    }

    /// Resets navigation to its initial state.
    public func reset() {
        navigate(to: .reset)
    }

    /// Replaces the entire navigation stack.
    public func setStack(_ routes: [R]) {
        navigate(to: .setStack(routes))
    }

    // MARK: - Query

    /// Whether the navigation stack is empty (at root).
    public var isAtRoot: Bool { path.isEmpty }

    /// The number of routes currently in the stack.
    public var stackDepth: Int { path.count }

    /// Whether a modal is currently presented.
    public var isPresenting: Bool { sheet != nil || fullScreenCover != nil }

    /// The topmost route in the stack, or `nil` if at root.
    public var topRoute: R? { path.last }

    /// Whether the tab bar should be hidden based on the current top route.
    public var shouldHideTabBar: Bool { topRoute?.hidesTabBar ?? false }
}
