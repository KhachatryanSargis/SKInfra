import Foundation
@testable import SKCore
@testable import SKAnalytics

/// A test spy analytics provider that records all tracked events for verification.
///
/// Thread-safe via `@unchecked Sendable` — since Swift Testing
/// runs tests sequentially within a suite, direct mutation is fine here.
/// Captures ``AnalyticsEvent`` values and identity calls so tests can assert
/// on event names, properties, and call sequences.
final class MockAnalyticsProvider: AnalyticsProtocol, @unchecked Sendable {
    let isEnabled: Bool
    private(set) var trackedEvents: [AnalyticsEvent] = []
    private(set) var screenEvents: [AnalyticsEvent] = []
    private(set) var identifiedUserIds: [String] = []
    private(set) var userProperties: [AnalyticsProperties] = []
    private(set) var resetCount: Int = 0

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func track(_ event: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        trackedEvents.append(AnalyticsEvent(name: event, properties: properties))
    }

    func identify(userId: String) {
        guard isEnabled else { return }
        identifiedUserIds.append(userId)
    }

    func setUserProperties(_ properties: AnalyticsProperties) {
        guard isEnabled else { return }
        userProperties.append(properties)
    }

    func screen(_ name: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        screenEvents.append(AnalyticsEvent(name: name, properties: properties))
    }

    func reset() {
        guard isEnabled else { return }
        resetCount += 1
    }

    /// Resets all recorded state for test isolation.
    func clear() {
        trackedEvents.removeAll()
        screenEvents.removeAll()
        identifiedUserIds.removeAll()
        userProperties.removeAll()
        resetCount = 0
    }
}
