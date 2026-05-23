import Foundation
import SKCore

// MARK: - Mock Analytics Provider

/// A test spy ``AnalyticsProtocol`` that records every tracked event,
/// screen view, identify call, and user-property update for verification.
///
/// Captures ``AnalyticsEvent`` values plus identity-related calls so tests
/// can assert on event names, properties, and call sequences.
///
/// ## Thread Safety
///
/// `@unchecked Sendable` — this mock is intended for single-test use where
/// access is naturally serialized. Do not share an instance across
/// concurrent tasks without adding synchronization.
public final class MockAnalyticsProvider: AnalyticsProtocol, @unchecked Sendable {
    public let isEnabled: Bool

    public private(set) var trackedEvents: [AnalyticsEvent] = []
    public private(set) var screenEvents: [AnalyticsEvent] = []
    public private(set) var identifiedUserIds: [String] = []
    public private(set) var userProperties: [AnalyticsProperties] = []
    public private(set) var resetCount: Int = 0

    /// Creates a mock analytics provider.
    ///
    /// - Parameter isEnabled: Whether the provider should report itself as
    ///   enabled. When `false`, all `track`/`screen`/`identify` calls are
    ///   silently dropped, matching the production behavior of disabled
    ///   providers.
    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func track(_ event: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        trackedEvents.append(AnalyticsEvent(name: event, properties: properties))
    }

    public func identify(userId: String) {
        guard isEnabled else { return }
        identifiedUserIds.append(userId)
    }

    public func setUserProperties(_ properties: AnalyticsProperties) {
        guard isEnabled else { return }
        userProperties.append(properties)
    }

    public func screen(_ name: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        screenEvents.append(AnalyticsEvent(name: name, properties: properties))
    }

    public func reset() {
        guard isEnabled else { return }
        resetCount += 1
    }

    // MARK: - Test Helpers

    /// Resets all recorded state for test isolation.
    public func clear() {
        trackedEvents.removeAll()
        screenEvents.removeAll()
        identifiedUserIds.removeAll()
        userProperties.removeAll()
        resetCount = 0
    }
}
