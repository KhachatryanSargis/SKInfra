import Testing
import Foundation
@testable import SKCore
@testable import SKAnalytics

@Suite("SuperPropertyProvider")
struct SuperPropertyProviderTests {

    // MARK: - Super Property Injection

    @Test("Attaches super properties to tracked events")
    func attachesSuperProperties() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["app_version": "2.0"]
        )

        provider.track("test_event")

        #expect(mock.trackedEvents.count == 1)
        #expect(mock.trackedEvents[0].properties?["app_version"] == .string("2.0"))
    }

    @Test("Attaches super properties to screen events")
    func attachesSuperPropertiesToScreen() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["platform": "iOS"]
        )

        provider.screen("HomeScreen")

        #expect(mock.screenEvents.count == 1)
        #expect(mock.screenEvents[0].properties?["platform"] == .string("iOS"))
    }

    // MARK: - Event Property Precedence

    @Test("Event-specific properties override super properties on collision")
    func eventOverridesSuperOnCollision() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["source": "default"]
        )

        provider.track("test", properties: ["source": "deeplink"])

        #expect(mock.trackedEvents[0].properties?["source"] == .string("deeplink"))
    }

    @Test("Merges both super and event properties when no collision")
    func mergesBothProperties() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["app_version": "2.0"]
        )

        provider.track("test", properties: ["item_id": "abc"])

        let props = mock.trackedEvents[0].properties
        #expect(props?["app_version"] == .string("2.0"))
        #expect(props?["item_id"] == .string("abc"))
    }

    // MARK: - Registration

    @Test("Register adds new super properties")
    func registerAddsProperties() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(wrapping: mock)

        provider.register(["env": "production"])
        provider.track("test")

        #expect(mock.trackedEvents[0].properties?["env"] == .string("production"))
    }

    @Test("Register overwrites existing super properties")
    func registerOverwrites() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["version": "1.0"]
        )

        provider.register(["version": "2.0"])
        provider.track("test")

        #expect(mock.trackedEvents[0].properties?["version"] == .string("2.0"))
    }

    // MARK: - Clear

    @Test("Clear removes all super properties")
    func clearRemovesSuperProperties() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["key": "value"]
        )

        provider.clearSuperProperties()
        provider.track("test")

        let current = provider.currentSuperProperties()
        #expect(current.isEmpty)
        // Event should still be tracked, just without super properties
        #expect(mock.trackedEvents.count == 1)
    }

    // MARK: - Reset

    @Test("Reset clears super properties and forwards to wrapped provider")
    func resetClearsAndForwards() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["key": "value"]
        )

        provider.reset()

        let current = provider.currentSuperProperties()
        #expect(current.isEmpty)
        #expect(mock.resetCount == 1)
    }

    // MARK: - Passthrough

    @Test("Identify is forwarded directly to wrapped provider")
    func identifyPassthrough() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(wrapping: mock)

        provider.identify(userId: "user-123")

        #expect(mock.identifiedUserIds == ["user-123"])
    }

    @Test("setUserProperties is forwarded directly to wrapped provider")
    func userPropertiesPassthrough() {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(wrapping: mock)

        provider.setUserProperties(["tier": "premium"])

        #expect(mock.userProperties.count == 1)
    }

    // MARK: - Disabled State

    @Test("Disabled wrapped provider prevents event tracking")
    func disabledWrappedProvider() {
        let mock = MockAnalyticsProvider(isEnabled: false)
        let provider = SuperPropertyProvider(wrapping: mock)

        provider.track("should_not_track")

        #expect(mock.trackedEvents.isEmpty)
    }

    // MARK: - Sendable Conformance

    @Test("SuperPropertyProvider can be used across isolation boundaries")
    func sendableConformance() async {
        let mock = MockAnalyticsProvider()
        let provider = SuperPropertyProvider(
            wrapping: mock,
            initialProperties: ["env": "test"]
        )

        await Task.detached {
            provider.track("from detached task")
        }.value

        #expect(mock.trackedEvents.count == 1)
        #expect(mock.trackedEvents[0].properties?["env"] == .string("test"))
    }
}
