import SwiftUI

// MARK: - Coordinator Protocol

/// The base contract for all coordinators in the navigation hierarchy.
///
/// A coordinator owns a ``NavigationRouter`` and is responsible for:
/// - Providing the root view of its flow
/// - Mapping routes to destination views
/// - Managing child coordinator lifecycles
///
/// Each feature module implements its own coordinator conforming to this protocol.
/// The coordinator is `@Observable` so SwiftUI can react to navigation state changes.
///
/// Example:
/// ```swift
/// @Observable
/// @MainActor
/// final class ProductCoordinator: Coordinator {
///     typealias RouteType = ProductRoute
///
///     let router = NavigationRouter<ProductRoute>()
///
///     @ViewBuilder
///     func rootView() -> some View {
///         ProductListView(coordinator: self)
///     }
///
///     @ViewBuilder
///     func destination(for route: ProductRoute) -> some View {
///         switch route {
///         case .detail(let id):
///             ProductDetailView(id: id, coordinator: self)
///         case .settings:
///             SettingsView(coordinator: self)
///         }
///     }
/// }
/// ```
@MainActor
public protocol Coordinator: AnyObject, Observable {

    /// The route type this coordinator handles.
    associatedtype RouteType: Route

    /// The concrete view type returned by ``rootView()``.
    /// Inferred automatically from your `@ViewBuilder` implementation.
    associatedtype RootBody: View

    /// The concrete view type returned by ``destination(for:)``.
    /// Inferred automatically from your `@ViewBuilder` implementation.
    associatedtype DestinationBody: View

    /// The router managing this coordinator's navigation state.
    var router: NavigationRouter<RouteType> { get }

    /// The root view of this coordinator's flow.
    @ViewBuilder
    func rootView() -> RootBody

    /// Resolves a route to its corresponding destination view.
    ///
    /// - Parameter route: The route to resolve.
    /// - Returns: The view for the given route.
    @ViewBuilder
    func destination(for route: RouteType) -> DestinationBody
}

// MARK: - Flow Coordinator Protocol

/// A coordinator that manages a complete flow with a typed result.
///
/// Use this for child flows that return a result to their parent.
/// The parent calls ``start()`` which suspends until the flow completes.
///
/// Example:
/// ```swift
/// @Observable
/// @MainActor
/// final class CheckoutCoordinator: FlowCoordinator {
///     typealias RouteType = CheckoutRoute
///     typealias Output = CheckoutOutput
///
///     let router = NavigationRouter<CheckoutRoute>()
///     let resultHandler = CoordinatorResultHandler<CheckoutOutput>()
///
///     func start() async -> CoordinatorResult<CheckoutOutput> {
///         await resultHandler.awaitResult()
///     }
///
///     func didComplete(orderId: String) {
///         resultHandler.finish(with: .completed(orderId: orderId))
///     }
///
///     func didCancel() {
///         resultHandler.cancel()
///     }
/// }
/// ```
@MainActor
public protocol FlowCoordinator: Coordinator {

    /// The output type produced when this flow completes.
    associatedtype Output: Sendable

    /// Starts the coordinator's flow and suspends until it completes.
    ///
    /// - Returns: The flow's result.
    func start() async -> CoordinatorResult<Output>
}
