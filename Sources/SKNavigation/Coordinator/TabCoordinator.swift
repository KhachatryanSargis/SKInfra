import SwiftUI

// MARK: - Tab Coordinator Protocol

/// A coordinator that manages a tab-based navigation hierarchy.
///
/// The `TabCoordinator` owns a ``TabRouter`` and a set of child coordinators,
/// one per tab. It is responsible for:
/// - Creating child coordinators for each tab
/// - Providing the view for each tab
/// - Handling cross-module navigation by routing to the correct tab
///
/// Example:
/// ```swift
/// @Observable
/// @MainActor
/// final class AppCoordinator: TabCoordinator {
///     typealias TabType = AppTab
///
///     let tabRouter = TabRouter(initialTab: AppTab.home)
///
///     private(set) lazy var homeCoordinator = HomeCoordinator()
///     private(set) lazy var searchCoordinator = SearchCoordinator()
///     private(set) lazy var profileCoordinator = ProfileCoordinator()
///
///     @ViewBuilder
///     func coordinatorView(for tab: AppTab) -> some View {
///         switch tab {
///         case .home:    CoordinatedView(coordinator: homeCoordinator)
///         case .search:  CoordinatedView(coordinator: searchCoordinator)
///         case .profile: CoordinatedView(coordinator: profileCoordinator)
///         }
///     }
/// }
/// ```
@MainActor
public protocol TabCoordinator: AnyObject, Observable {

    /// The tab type this coordinator manages.
    associatedtype TabType: Tab

    /// The concrete view type returned by ``coordinatorView(for:)``.
    /// Inferred automatically from your `@ViewBuilder` implementation.
    associatedtype TabBody: View

    /// The router managing tab selection state.
    var tabRouter: TabRouter<TabType> { get }

    /// Returns the coordinated view for a given tab.
    ///
    /// Each tab's view is typically a ``CoordinatedView`` wrapping
    /// the tab's child coordinator.
    ///
    /// - Parameter tab: The tab to provide a view for.
    @ViewBuilder
    func coordinatorView(for tab: TabType) -> TabBody
}
