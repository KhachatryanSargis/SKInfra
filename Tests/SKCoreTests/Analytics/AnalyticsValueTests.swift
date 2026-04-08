import Testing
import Foundation
@testable import SKCore

@Suite("AnalyticsValue")
struct AnalyticsValueTests {

    // MARK: - Literal Conformances

    @Test("String literal creates string value")
    func stringLiteral() {
        let value: AnalyticsValue = "hello"
        #expect(value == .string("hello"))
    }

    @Test("Integer literal creates int value")
    func integerLiteral() {
        let value: AnalyticsValue = 42
        #expect(value == .int(42))
    }

    @Test("Float literal creates double value")
    func floatLiteral() {
        let value: AnalyticsValue = 3.14
        #expect(value == .double(3.14))
    }

    @Test("Boolean literal creates bool value")
    func booleanLiteral() {
        let value: AnalyticsValue = true
        #expect(value == .bool(true))
    }

    // MARK: - Date

    @Test("Date value round-trips correctly")
    func dateValue() {
        let now = Date()
        let value = AnalyticsValue.date(now)

        if case .date(let stored) = value {
            #expect(stored == now)
        } else {
            Issue.record("Expected .date case")
        }
    }

    // MARK: - Equatable

    @Test("Same values compare as equal")
    func equatable() {
        #expect(AnalyticsValue.string("a") == AnalyticsValue.string("a"))
        #expect(AnalyticsValue.int(1) == AnalyticsValue.int(1))
        #expect(AnalyticsValue.double(1.5) == AnalyticsValue.double(1.5))
        #expect(AnalyticsValue.bool(false) == AnalyticsValue.bool(false))
    }

    @Test("Different values compare as not equal")
    func notEqual() {
        #expect(AnalyticsValue.string("a") != AnalyticsValue.string("b"))
        #expect(AnalyticsValue.int(1) != AnalyticsValue.int(2))
    }

    // MARK: - Description

    @Test("Description formats each case correctly")
    func description() {
        #expect(AnalyticsValue.string("hi").description == "\"hi\"")
        #expect(AnalyticsValue.int(42).description == "42")
        #expect(AnalyticsValue.bool(true).description == "true")
    }
}
