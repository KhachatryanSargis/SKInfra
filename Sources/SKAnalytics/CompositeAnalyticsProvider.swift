import Foundation
import SKCore

// MARK: - Composite Analytics Provider

/// An analytics provider that forwards events to multiple underlying providers.
///
/// Demonstrates the composite pattern applied through protocol-oriented
/// programming: because ``AnalyticsProtocol`` is a protocol (not a base class),
/// any combination of providers can be composed without inheritance.
///
/// Each child provider applies its own ``AnalyticsProtocol/isEnabled`` flag
/// independently. The composite's own `isEnabled` acts as a master switch.
///
/// ## Usage
///
/// ```swift
/// let analytics = CompositeAnalyticsProvider(
///     providers: [
///         PrintAnalyticsProvider(),         // debug output
///         mixpanelProvider,                 // production tracking
///         internalAnalyticsProvider         // your own backend
///     ]
/// )
///
/// analytics.track("purchase_completed", properties: [
///     "item_id": "abc-123",
///     "price": 9.99
/// ])
/// // All three providers receive the event
/// ```
public struct CompositeAnalyticsProvider: AnalyticsProtocol {
    /// Master switch — when `false`, no events are forwarded to any child.
    public let isEnabled: Bool

    /// The child providers, stored as existentials for heterogeneous collection.
    ///
    /// This is a deliberate use of `any AnalyticsProtocol` — we need a
    /// heterogeneous array since each provider can be a different concrete type.
    private let providers: [any AnalyticsProtocol]

    /// Creates a composite analytics provider that forwards to all provided providers.
    ///
    /// - Parameters:
    ///   - providers: The child providers to forward events to.
    ///   - isEnabled: Master switch. Defaults to `true`.
    public init(
        providers: [any AnalyticsProtocol],
        isEnabled: Bool = true
    ) {
        self.providers = providers
        self.isEnabled = isEnabled
    }

    public func track(_ event: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        for provider in providers {
            provider.track(event, properties: properties)
        }
    }

    public func identify(userId: String) {
        guard isEnabled else { return }
        for provider in providers {
            provider.identify(userId: userId)
        }
    }

    public func setUserProperties(_ properties: AnalyticsProperties) {
        guard isEnabled else { return }
        for provider in providers {
            provider.setUserProperties(properties)
        }
    }

    public func screen(_ name: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        for provider in providers {
            provider.screen(name, properties: properties)
        }
    }

    public func reset() {
        guard isEnabled else { return }
        for provider in providers {
            provider.reset()
        }
    }
}
