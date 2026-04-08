import Testing
import Foundation
@testable import SKCore

@Suite("AnalyticsProperties")
struct AnalyticsPropertiesTests {

    // MARK: - Initialization

    @Test("Empty initializer creates empty properties")
    func emptyInit() {
        let properties = AnalyticsProperties()
        #expect(properties.isEmpty)
        #expect(properties.count == 0)
    }

    @Test("Dictionary literal creates properties with correct values")
    func dictionaryLiteral() {
        let properties: AnalyticsProperties = [
            "name": "Sargis",
            "age": 28,
            "score": 99.5,
            "premium": true
        ]

        #expect(properties.count == 4)
        #expect(properties["name"] == .string("Sargis"))
        #expect(properties["age"] == .int(28))
        #expect(properties["score"] == .double(99.5))
        #expect(properties["premium"] == .bool(true))
    }

    // MARK: - Subscript

    @Test("Subscript returns nil for missing keys")
    func subscriptMissingKey() {
        let properties: AnalyticsProperties = ["key": "value"]
        #expect(properties["missing"] == nil)
    }

    // MARK: - Merging

    @Test("Merging combines properties from both sides")
    func mergingCombines() {
        let a: AnalyticsProperties = ["a": 1, "b": 2]
        let b: AnalyticsProperties = ["c": 3]

        let merged = a.merging(b)

        #expect(merged.count == 3)
        #expect(merged["a"] == .int(1))
        #expect(merged["c"] == .int(3))
    }

    @Test("Merging gives precedence to other on key collision")
    func mergingPrecedence() {
        let a: AnalyticsProperties = ["key": "old"]
        let b: AnalyticsProperties = ["key": "new"]

        let merged = a.merging(b)

        #expect(merged["key"] == .string("new"))
    }

    // MARK: - Equatable

    @Test("Equal properties compare as equal")
    func equatable() {
        let a: AnalyticsProperties = ["x": 1, "y": "hello"]
        let b: AnalyticsProperties = ["x": 1, "y": "hello"]

        #expect(a == b)
    }

    @Test("Different properties compare as not equal")
    func notEqual() {
        let a: AnalyticsProperties = ["x": 1]
        let b: AnalyticsProperties = ["x": 2]

        #expect(a != b)
    }

    // MARK: - Description

    @Test("Description formats properties alphabetically")
    func description() {
        let properties: AnalyticsProperties = ["b": 2, "a": 1]

        #expect(properties.description.contains("a: 1"))
        #expect(properties.description.contains("b: 2"))
    }
}
