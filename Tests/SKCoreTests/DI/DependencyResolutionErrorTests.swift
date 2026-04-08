import Foundation
import Testing
@testable import SKCore

@Suite("DependencyResolutionError")
struct DependencyResolutionErrorTests {

    // MARK: - Error Descriptions

    @Test("notRegistered without name includes type")
    func notRegisteredWithoutName() {
        let error = DependencyResolutionError.notRegistered(type: "BookmarkRepository", name: nil)
        #expect(error.errorDescription == "No registration found for type 'BookmarkRepository'")
    }

    @Test("notRegistered with name includes both type and name")
    func notRegisteredWithName() {
        let error = DependencyResolutionError.notRegistered(type: "StorageProtocol", name: "secure")
        #expect(error.errorDescription == "No registration found for type 'StorageProtocol' with name 'secure'")
    }

    @Test("typeMismatch includes expected and actual types")
    func typeMismatchDescription() {
        let error = DependencyResolutionError.typeMismatch(expected: "String", actual: "Int")
        #expect(error.errorDescription == "Type mismatch: expected 'String', got 'Int'")
    }

    @Test("argumentTypeMismatch includes factory and provided types")
    func argumentTypeMismatchDescription() {
        let error = DependencyResolutionError.argumentTypeMismatch(factory: "UUID", provided: "String")
        #expect(error.errorDescription == "Argument type mismatch: factory expects 'UUID', provided 'String'")
    }

    // MARK: - Equatable

    @Test("Same case and values are equal")
    func equatable() {
        let a = DependencyResolutionError.notRegistered(type: "A", name: nil)
        let b = DependencyResolutionError.notRegistered(type: "A", name: nil)
        #expect(a == b)
    }

    @Test("Different cases are not equal")
    func notEqualDifferentCase() {
        let a = DependencyResolutionError.notRegistered(type: "A", name: nil)
        let b = DependencyResolutionError.typeMismatch(expected: "A", actual: "B")
        #expect(a != b)
    }

    @Test("Same case with different values are not equal")
    func notEqualDifferentValues() {
        let a = DependencyResolutionError.notRegistered(type: "A", name: nil)
        let b = DependencyResolutionError.notRegistered(type: "B", name: nil)
        #expect(a != b)
    }

    @Test("notRegistered with different names are not equal")
    func notEqualDifferentNames() {
        let a = DependencyResolutionError.notRegistered(type: "A", name: "x")
        let b = DependencyResolutionError.notRegistered(type: "A", name: "y")
        #expect(a != b)
    }

    // MARK: - Error Conformance

    @Test("Conforms to Error and can be caught")
    func errorConformance() {
        let error: any Error = DependencyResolutionError.notRegistered(type: "T", name: nil)
        #expect(error is DependencyResolutionError)
    }

    @Test("Conforms to LocalizedError with non-nil description")
    func localizedErrorConformance() {
        let error: any LocalizedError = DependencyResolutionError.typeMismatch(
            expected: "A",
            actual: "B"
        )
        #expect(error.errorDescription != nil)
    }
}
