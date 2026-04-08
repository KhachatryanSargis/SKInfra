import Foundation
import os
import SKCore

// TODO: When minimum deployment target is raised to iOS 18+ / macOS 15+,
// replace OSAllocatedUnfairLock with Mutex from the Synchronization framework
// and remove @unchecked Sendable.

// MARK: - Super Property Provider

/// An analytics provider decorator that automatically attaches persistent
/// "super properties" to every tracked event.
///
/// Wraps any ``AnalyticsProtocol`` conformer and merges a set of shared
/// properties into each `track` and `screen` call. Event-specific properties
/// take precedence over super properties when keys collide.
///
/// This is the protocol-oriented equivalent of Mixpanel's
/// `registerSuperProperties` — but decoupled from any vendor.
///
/// ## Thread Safety
///
/// Uses `OSAllocatedUnfairLock` to protect mutable super-property state,
/// ensuring safe access across concurrency domains. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot verify
/// lock-based safety statically.
///
/// ## Usage
///
/// ```swift
/// let base = PrintAnalyticsProvider()
/// let analytics = SuperPropertyProvider(wrapping: base)
///
/// analytics.register(["app_version": "2.1.0", "platform": "iOS"])
/// analytics.track("button_tapped", properties: ["button": "buy"])
/// // Tracked with: app_version, platform, AND button
/// ```
public struct SuperPropertyProvider: AnalyticsProtocol, @unchecked Sendable {
    // MARK: - Dependencies

    private let wrapped: any AnalyticsProtocol
    private let state: OSAllocatedUnfairLock<AnalyticsProperties>

    // MARK: - Init

    /// Creates a super property provider wrapping the given base provider.
    ///
    /// - Parameters:
    ///   - wrapped: The underlying analytics provider to forward events to.
    ///   - initialProperties: Super properties to register immediately.
    ///     Defaults to empty.
    public init(
        wrapping wrapped: any AnalyticsProtocol,
        initialProperties: AnalyticsProperties = [:]
    ) {
        self.wrapped = wrapped
        self.state = OSAllocatedUnfairLock(initialState: initialProperties)
    }

    // MARK: - Super Property Management

    /// Registers super properties that will be attached to all future events.
    ///
    /// If a key already exists, its value is overwritten.
    ///
    /// - Parameter properties: The properties to register.
    public func register(_ properties: AnalyticsProperties) {
        state.withLock { $0 = $0.merging(properties) }
    }

    /// Removes all registered super properties.
    public func clearSuperProperties() {
        state.withLock { $0 = [:] }
    }

    /// Returns the currently registered super properties.
    public func currentSuperProperties() -> AnalyticsProperties {
        state.withLock { $0 }
    }

    // MARK: - AnalyticsProtocol

    public var isEnabled: Bool { wrapped.isEnabled }

    public func track(_ event: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        let merged = mergedProperties(with: properties)
        wrapped.track(event, properties: merged)
    }

    public func identify(userId: String) {
        wrapped.identify(userId: userId)
    }

    public func setUserProperties(_ properties: AnalyticsProperties) {
        wrapped.setUserProperties(properties)
    }

    public func screen(_ name: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        let merged = mergedProperties(with: properties)
        wrapped.screen(name, properties: merged)
    }

    public func reset() {
        state.withLock { $0 = [:] }
        wrapped.reset()
    }

    // MARK: - Private

    private func mergedProperties(with eventProperties: AnalyticsProperties?) -> AnalyticsProperties {
        let superProps = state.withLock { $0 }
        guard let eventProperties else { return superProps }
        return superProps.merging(eventProperties)
    }
}
