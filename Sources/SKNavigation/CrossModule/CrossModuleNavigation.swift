import Foundation

// MARK: - Cross-Module Navigation Strategy

/// Defines how cross-module navigation is performed when a feature
/// needs to navigate to a destination owned by another feature.
///
/// Each cross-module destination specifies its preferred strategy,
/// giving the app coordinator flexibility to either switch tabs or
/// present modally.
public enum CrossModuleStrategy: Sendable, Equatable {

    /// Switch to the target tab and push the destination onto its navigation stack.
    ///
    /// Use this when the user should fully transition to the other module.
    case switchTabAndPush

    /// Present the destination modally as a sheet over the current context.
    ///
    /// Use this for quick interactions that don't require leaving the current flow.
    case presentSheet

    /// Present the destination as a full-screen cover over the current context.
    case presentFullScreenCover
}

// MARK: - Cross-Module Destination

/// A type-safe description of a navigation destination in another module.
///
/// `Target` is a generic type that your app defines — typically an enum of all
/// modules. SKNavigation only requires it to be `Hashable & Sendable`,
/// keeping the package fully reusable across projects.
///
/// Feature coordinators create these when they need to navigate to a
/// destination owned by a different feature. The app coordinator resolves
/// the destination and performs the actual navigation.
public struct CrossModuleDestination<Target: Hashable & Sendable>: Sendable {

    /// The target module to navigate to.
    public let targetModule: Target

    /// A unique identifier for the destination within the module.
    public let identifier: String

    /// Parameters needed to construct the destination.
    public let parameters: [String: String]

    /// The preferred navigation strategy for this destination.
    public let preferredStrategy: CrossModuleStrategy

    public init(
        targetModule: Target,
        identifier: String,
        parameters: [String: String] = [:],
        preferredStrategy: CrossModuleStrategy
    ) {
        self.targetModule = targetModule
        self.identifier = identifier
        self.parameters = parameters
        self.preferredStrategy = preferredStrategy
    }
}

// MARK: - Cross-Module Navigation Handler

/// A protocol for the app-layer coordinator to handle cross-module navigation.
///
/// The app coordinator conforms to this protocol to resolve cross-module
/// destinations and perform the navigation using its knowledge of all
/// feature coordinators and the tab layout.
///
/// `Target` matches the same type used in ``CrossModuleDestination``.
@MainActor
public protocol CrossModuleNavigationHandler: AnyObject {

    /// The type that identifies modules in your app.
    associatedtype Target: Hashable & Sendable

    /// Navigates to a cross-module destination.
    ///
    /// - Parameter destination: The destination to navigate to.
    func navigate(to destination: CrossModuleDestination<Target>)
}
