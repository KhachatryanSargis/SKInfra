import Foundation

// MARK: - Analytics Protocol

/// Type-safe, protocol-oriented analytics tracking interface.
///
/// Defines a provider-agnostic contract for event tracking, user
/// identification, and property management. Concrete implementations
/// wrap vendor SDKs (Mixpanel, Amplitude, Firebase, etc.) at the
/// application layer, keeping all feature code decoupled from any
/// specific analytics backend.
///
/// This design mirrors ``LoggerProtocol``:
///
/// - **Single set of requirements** in the protocol
/// - **Protocol composition** with `Sendable` for safe cross-isolation use
/// - **Static dispatch** when used as `some AnalyticsProtocol` in generics
/// - **Dynamic dispatch** when used as `any AnalyticsProtocol` for runtime flexibility
///
/// ## Usage
///
/// ```swift
/// func onPurchaseCompleted(
///     item: Item,
///     analytics: some AnalyticsProtocol
/// ) {
///     analytics.track("purchase_completed", properties: [
///         "item_id": item.id,
///         "price": item.price
///     ])
/// }
/// ```
///
/// ## Implementing a Provider
///
/// Wrap a vendor SDK behind this protocol:
///
/// ```swift
/// struct MixpanelProvider: AnalyticsProtocol {
///     let isEnabled: Bool = true
///
///     func track(_ event: String, properties: AnalyticsProperties?) {
///         Mixpanel.mainInstance().track(event: event, properties: properties?.mixpanelValue)
///     }
///
///     func identify(userId: String) {
///         Mixpanel.mainInstance().identify(distinctId: userId)
///     }
///
///     func setUserProperties(_ properties: AnalyticsProperties) { ... }
///     func screen(_ name: String, properties: AnalyticsProperties?) { ... }
///     func reset() { Mixpanel.mainInstance().reset() }
/// }
/// ```
public protocol AnalyticsProtocol: Sendable {
    /// Whether this provider is currently enabled.
    ///
    /// When `false`, all tracking methods should silently no-op.
    /// Use this to implement consent gating or debug toggles.
    var isEnabled: Bool { get }

    /// Tracks a named event with optional properties.
    ///
    /// - Parameters:
    ///   - event: A unique event name (e.g. `"button_tapped"`, `"purchase_completed"`).
    ///   - properties: Key-value metadata to attach to the event.
    func track(_ event: String, properties: AnalyticsProperties?)

    /// Associates future events with a known user identity.
    ///
    /// Call this after sign-in or when the user identity becomes known.
    /// Implementations should map this to the vendor's identify/login method.
    ///
    /// - Parameter userId: A stable, unique identifier for the user.
    func identify(userId: String)

    /// Sets persistent properties on the current user profile.
    ///
    /// These properties are attached to the user record (not individual events).
    /// Use for demographic data, subscription tier, preferences, etc.
    ///
    /// - Parameter properties: Key-value pairs to set on the user profile.
    func setUserProperties(_ properties: AnalyticsProperties)

    /// Tracks a screen view event.
    ///
    /// - Parameters:
    ///   - name: The screen name (e.g. `"HomeScreen"`, `"Settings"`).
    ///   - properties: Additional metadata about the screen view.
    func screen(_ name: String, properties: AnalyticsProperties?)

    /// Resets the analytics state.
    ///
    /// Clears the current user identity, super properties, and any
    /// queued events. Call this on sign-out to prevent event leakage
    /// between user sessions.
    func reset()
}

// MARK: - Convenience Defaults

public extension AnalyticsProtocol {
    /// Tracks an event with no additional properties.
    func track(_ event: String) {
        track(event, properties: nil)
    }

    /// Tracks a screen view with no additional properties.
    func screen(_ name: String) {
        screen(name, properties: nil)
    }
}
