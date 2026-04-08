import Testing
import Foundation
@testable import SKCore
@testable import SKAnalytics

@Suite("CompositeAnalyticsProvider")
struct CompositeAnalyticsProviderTests {

    // MARK: - Forwarding

    @Test("Forwards track events to all child providers")
    func forwardsTrackToAll() {
        let provider1 = MockAnalyticsProvider()
        let provider2 = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider1, provider2])

        composite.track("test_event", properties: ["key": "value"])

        #expect(provider1.trackedEvents.count == 1)
        #expect(provider1.trackedEvents[0].name == "test_event")
        #expect(provider2.trackedEvents.count == 1)
        #expect(provider2.trackedEvents[0].name == "test_event")
    }

    @Test("Forwards identify to all child providers")
    func forwardsIdentifyToAll() {
        let provider1 = MockAnalyticsProvider()
        let provider2 = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider1, provider2])

        composite.identify(userId: "user-123")

        #expect(provider1.identifiedUserIds == ["user-123"])
        #expect(provider2.identifiedUserIds == ["user-123"])
    }

    @Test("Forwards screen events to all child providers")
    func forwardsScreenToAll() {
        let provider1 = MockAnalyticsProvider()
        let provider2 = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider1, provider2])

        composite.screen("HomeScreen", properties: ["tab": "feed"])

        #expect(provider1.screenEvents.count == 1)
        #expect(provider1.screenEvents[0].name == "HomeScreen")
        #expect(provider2.screenEvents.count == 1)
    }

    @Test("Forwards setUserProperties to all child providers")
    func forwardsUserPropertiesToAll() {
        let provider1 = MockAnalyticsProvider()
        let provider2 = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider1, provider2])

        composite.setUserProperties(["tier": "premium"])

        #expect(provider1.userProperties.count == 1)
        #expect(provider2.userProperties.count == 1)
    }

    @Test("Forwards reset to all child providers")
    func forwardsResetToAll() {
        let provider1 = MockAnalyticsProvider()
        let provider2 = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider1, provider2])

        composite.reset()

        #expect(provider1.resetCount == 1)
        #expect(provider2.resetCount == 1)
    }

    // MARK: - Master Switch

    @Test("Disabled composite does not forward any events")
    func disabledCompositeNoOps() {
        let provider = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider], isEnabled: false)

        composite.track("ignored")
        composite.identify(userId: "ignored")
        composite.screen("ignored")
        composite.setUserProperties(["ignored": true])
        composite.reset()

        #expect(provider.trackedEvents.isEmpty)
        #expect(provider.identifiedUserIds.isEmpty)
        #expect(provider.screenEvents.isEmpty)
        #expect(provider.userProperties.isEmpty)
        #expect(provider.resetCount == 0)
    }

    // MARK: - Per-Child Filtering

    @Test("Each child applies its own isEnabled flag")
    func perChildFiltering() {
        let enabled = MockAnalyticsProvider(isEnabled: true)
        let disabled = MockAnalyticsProvider(isEnabled: false)
        let composite = CompositeAnalyticsProvider(providers: [enabled, disabled])

        composite.track("test")

        #expect(enabled.trackedEvents.count == 1)
        #expect(disabled.trackedEvents.isEmpty)
    }

    // MARK: - Properties Preservation

    @Test("Event properties are preserved through forwarding")
    func propertiesPreserved() {
        let provider = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider])

        let props: AnalyticsProperties = ["item_id": "abc", "price": 9.99]
        composite.track("purchase", properties: props)

        let tracked = provider.trackedEvents[0]
        #expect(tracked.properties?["item_id"] == .string("abc"))
        #expect(tracked.properties?["price"] == .double(9.99))
    }

    // MARK: - Sendable Conformance

    @Test("CompositeAnalyticsProvider can be used across isolation boundaries")
    func sendableConformance() async {
        let provider = MockAnalyticsProvider()
        let composite = CompositeAnalyticsProvider(providers: [provider])

        await Task.detached {
            composite.track("from detached task")
        }.value

        #expect(provider.trackedEvents.count == 1)
    }
}
