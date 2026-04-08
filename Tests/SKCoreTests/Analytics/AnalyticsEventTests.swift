import Testing
import Foundation
@testable import SKCore

@Suite("AnalyticsEvent")
struct AnalyticsEventTests {

    // MARK: - Initialization

    @Test("Creates event with name and nil properties by default")
    func defaultInit() {
        let event = AnalyticsEvent(name: "test_event")

        #expect(event.name == "test_event")
        #expect(event.properties == nil)
    }

    @Test("Creates event with properties")
    func initWithProperties() {
        let props: AnalyticsProperties = ["key": "value"]
        let event = AnalyticsEvent(name: "test_event", properties: props)

        #expect(event.properties?["key"] == .string("value"))
    }

    @Test("Timestamp defaults to approximately now")
    func timestampDefaultsToNow() {
        let before = Date()
        let event = AnalyticsEvent(name: "test")
        let after = Date()

        #expect(event.timestamp >= before)
        #expect(event.timestamp <= after)
    }

    // MARK: - Description

    @Test("Description includes event name")
    func descriptionWithoutProperties() {
        let event = AnalyticsEvent(name: "button_tapped")
        #expect(event.description.contains("button_tapped"))
    }

    @Test("Description includes properties when present")
    func descriptionWithProperties() {
        let event = AnalyticsEvent(name: "purchase", properties: ["price": 9.99])
        #expect(event.description.contains("purchase"))
        #expect(event.description.contains("price"))
    }

    // MARK: - Equatable

    @Test("Events with same values compare as equal")
    func equatable() {
        let date = Date()
        let a = AnalyticsEvent(name: "e", properties: ["k": 1], timestamp: date)
        let b = AnalyticsEvent(name: "e", properties: ["k": 1], timestamp: date)

        #expect(a == b)
    }
}
