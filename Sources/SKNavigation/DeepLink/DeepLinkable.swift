import Foundation

// MARK: - Deep Linkable Protocol

/// A coordinator that can handle deep link URLs.
///
/// Implement this protocol on coordinators that need to respond to
/// external URLs (custom scheme or universal links). The app coordinator
/// typically conforms to this and delegates to child coordinators.
///
/// Example:
/// ```swift
/// extension AppCoordinator: DeepLinkable {
///     func handle(url: URL) -> Bool {
///         guard let deepLink = AppDeepLink(url: url) else { return false }
///         switch deepLink {
///         case .product(let id):
///             tabRouter.select(.home)
///             homeCoordinator.router.push(.detail(id: id))
///             return true
///         case .profile(let id):
///             tabRouter.select(.profile)
///             profileCoordinator.router.push(.detail(id: id))
///             return true
///         }
///     }
/// }
/// ```
@MainActor
public protocol DeepLinkable: AnyObject {

    /// Attempts to handle a deep link URL.
    ///
    /// - Parameter url: The URL to handle.
    /// - Returns: `true` if the URL was handled, `false` otherwise.
    func handle(url: URL) -> Bool
}

// MARK: - Deep Link Protocol

/// Represents a parsed deep link destination.
///
/// Implement this in your app layer to define the set of supported
/// deep link destinations. The failable initializer lets coordinators
/// attempt parsing without coupling to URL structure.
///
/// Example:
/// ```swift
/// enum AppDeepLink: DeepLink {
///     case product(id: String)
///     case profile(userId: String)
///     case settings
///
///     init?(url: URL) {
///         guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
///               let host = components.host else { return nil }
///
///         let pathSegments = components.path.split(separator: "/").map(String.init)
///
///         switch (host, pathSegments.first) {
///         case ("product", let id?):  self = .product(id: id)
///         case ("profile", let id?):  self = .profile(userId: id)
///         case ("settings", _):       self = .settings
///         default:                    return nil
///         }
///     }
/// }
/// ```
public protocol DeepLink: Sendable {

    /// Attempts to parse a URL into a deep link destination.
    init?(url: URL)
}
