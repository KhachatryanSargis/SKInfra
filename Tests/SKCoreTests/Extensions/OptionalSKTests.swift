import Testing
import Foundation
@testable import SKCore

@Suite("Optional+SK")
struct OptionalSKTests {

    // MARK: - isNil

    @Test("isNil returns true for nil")
    func isNilTrue() {
        let value: String? = nil
        #expect(value.sk.isNil == true)
    }

    @Test("isNil returns false for non-nil")
    func isNilFalse() {
        let value: String? = "hello"
        #expect(value.sk.isNil == false)
    }

    // MARK: - isNotNil

    @Test("isNotNil returns true for non-nil")
    func isNotNilTrue() {
        let value: Int? = 42
        #expect(value.sk.isNotNil == true)
    }

    @Test("isNotNil returns false for nil")
    func isNotNilFalse() {
        let value: Int? = nil
        #expect(value.sk.isNotNil == false)
    }

    // MARK: - Works with Different Types

    @Test("Works with Optional<Array>")
    func optionalArray() {
        let present: [Int]? = [1, 2, 3]
        let absent: [Int]? = nil

        #expect(present.sk.isNotNil == true)
        #expect(absent.sk.isNil == true)
    }
}
