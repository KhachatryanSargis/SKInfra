import Testing
@testable import SKCore

@Suite("StorageError")
struct StorageErrorTests {

    @Test("Each error case produces a descriptive message")
    func errorDescriptions() {
        let cases: [(StorageError, String)] = [
            (.encodingFailed(key: "k", underlying: "reason"),
             "Failed to encode value for key 'k': reason"),
            (.decodingFailed(key: "k", underlying: "reason"),
             "Failed to decode value for key 'k': reason"),
            (.saveFailed(key: "k", underlying: "reason"),
             "Failed to save value for key 'k': reason"),
            (.loadFailed(key: "k", underlying: "reason"),
             "Failed to load value for key 'k': reason"),
            (.deleteFailed(key: "k", underlying: "reason"),
             "Failed to delete value for key 'k': reason")
        ]

        for (error, expected) in cases {
            #expect(error.errorDescription == expected)
        }
    }

    @Test("Errors with same case and values are equal")
    func equatable() {
        let a = StorageError.saveFailed(key: "token", underlying: "OSStatus -25299")
        let b = StorageError.saveFailed(key: "token", underlying: "OSStatus -25299")
        #expect(a == b)
    }

    @Test("Errors with different cases are not equal")
    func notEqual() {
        let a = StorageError.saveFailed(key: "token", underlying: "reason")
        let b = StorageError.loadFailed(key: "token", underlying: "reason")
        #expect(a != b)
    }
}
