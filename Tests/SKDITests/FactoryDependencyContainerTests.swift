import Foundation
import Testing

@testable import SKDI
import SKCore

// MARK: - Test Protocols & Types

private protocol ServiceProtocol: Sendable {
    var id: String { get }
}

private final class ServiceImpl: ServiceProtocol, Sendable {
    let id: String
    init(id: String = UUID().uuidString) { self.id = id }
}

private protocol ParameterServiceProtocol: Sendable {
    var itemID: String { get }
}

private final class ParameterServiceImpl: ParameterServiceProtocol, Sendable {
    let itemID: String
    init(itemID: String) { self.itemID = itemID }
}

// MARK: - Registration & Resolution

@Suite("FactoryDependencyContainer — Registration & Resolution")
struct RegistrationResolutionTests {

    @Test("resolves a registered dependency")
    func resolveRegistered() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self) { ServiceImpl(id: "test") }

        let service = container.resolve(ServiceProtocol.self)
        #expect(service.id == "test")
    }

    @Test("resolves named registrations independently")
    func resolveNamed() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, name: "a") { ServiceImpl(id: "a") }
        container.register(ServiceProtocol.self, name: "b") { ServiceImpl(id: "b") }

        let a = container.resolve(ServiceProtocol.self, name: "a")
        let b = container.resolve(ServiceProtocol.self, name: "b")
        #expect(a.id == "a")
        #expect(b.id == "b")
    }

    @Test("overrides previous registration for the same type and name")
    func overrideRegistration() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self) { ServiceImpl(id: "first") }
        container.register(ServiceProtocol.self) { ServiceImpl(id: "second") }

        let service = container.resolve(ServiceProtocol.self)
        #expect(service.id == "second")
    }
}

// MARK: - Parameterized Resolution

@Suite("FactoryDependencyContainer — Parameterized Resolution")
struct ParameterizedResolutionTests {

    @Test("resolves with a runtime argument")
    func resolveWithArgument() {
        let container = FactoryDependencyContainer()
        container.register(ParameterServiceProtocol.self) { (id: String) in
            ParameterServiceImpl(itemID: id)
        }

        let service = container.resolve(ParameterServiceProtocol.self, argument: "item-42")
        #expect(service.itemID == "item-42")
    }
}

// MARK: - Unique Scope

@Suite("FactoryDependencyContainer — Unique Scope")
struct UniqueScopeTests {

    @Test("creates a new instance on each resolution")
    func uniqueCreatesNew() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, scope: .unique) { ServiceImpl() }

        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first.id != second.id)
    }
}

// MARK: - Singleton Scope

@Suite("FactoryDependencyContainer — Singleton Scope")
struct SingletonScopeTests {

    @Test("returns the same instance on every resolution")
    func singletonReturnsSame() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, scope: .singleton) { ServiceImpl() }

        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first.id == second.id)
    }

    @Test("singleton survives a cached-only reset")
    func singletonSurvivesCachedReset() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, scope: .singleton) { ServiceImpl() }

        let before = container.resolve(ServiceProtocol.self)
        container.reset(.cached)
        let after = container.resolve(ServiceProtocol.self)
        #expect(before.id == after.id)
    }
}

// MARK: - Cached Scope

@Suite("FactoryDependencyContainer — Cached Scope")
struct CachedScopeTests {

    @Test("returns the same instance until reset")
    func cachedReturnsSameUntilReset() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, scope: .cached) { ServiceImpl() }

        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first.id == second.id)

        container.reset(.cached)

        let third = container.resolve(ServiceProtocol.self)
        #expect(first.id != third.id)
    }
}

// MARK: - Shared Scope

@Suite("FactoryDependencyContainer — Shared Scope")
struct SharedScopeTests {

    @Test("returns the same instance while a strong reference exists")
    func sharedWhileReferenced() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, scope: .shared) { ServiceImpl() }

        var first: ServiceProtocol? = container.resolve(ServiceProtocol.self)
        let firstID = first!.id
        let second = container.resolve(ServiceProtocol.self)
        #expect(firstID == second.id)

        // Release all external references
        first = nil
        // After release, a new instance may be created
        // (behavior depends on ARC timing — not deterministically testable)
    }
}

// MARK: - Reset

@Suite("FactoryDependencyContainer — Reset")
struct ResetTests {

    @Test("full reset clears all scopes")
    func fullReset() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, name: "s", scope: .singleton) { ServiceImpl() }
        container.register(ServiceProtocol.self, name: "c", scope: .cached) { ServiceImpl() }

        let singletonBefore = container.resolve(ServiceProtocol.self, name: "s")
        let cachedBefore = container.resolve(ServiceProtocol.self, name: "c")

        container.reset()

        let singletonAfter = container.resolve(ServiceProtocol.self, name: "s")
        let cachedAfter = container.resolve(ServiceProtocol.self, name: "c")

        #expect(singletonBefore.id != singletonAfter.id)
        #expect(cachedBefore.id != cachedAfter.id)
    }

    @Test("scoped reset only affects the target scope")
    func scopedReset() {
        let container = FactoryDependencyContainer()
        container.register(ServiceProtocol.self, name: "s", scope: .singleton) { ServiceImpl() }
        container.register(ServiceProtocol.self, name: "c", scope: .cached) { ServiceImpl() }

        let singletonBefore = container.resolve(ServiceProtocol.self, name: "s")
        let cachedBefore = container.resolve(ServiceProtocol.self, name: "c")

        container.reset(.cached)

        let singletonAfter = container.resolve(ServiceProtocol.self, name: "s")
        let cachedAfter = container.resolve(ServiceProtocol.self, name: "c")

        #expect(singletonBefore.id == singletonAfter.id)
        #expect(cachedBefore.id != cachedAfter.id)
    }
}

// MARK: - DependencyScope Description

@Suite("DependencyScope — CustomStringConvertible")
struct DependencyScopeDescriptionTests {

    @Test("all scopes have correct descriptions", arguments: [
        (DependencyScope.unique, "unique"),
        (DependencyScope.singleton, "singleton"),
        (DependencyScope.cached, "cached"),
        (DependencyScope.shared, "shared"),
        (DependencyScope.graph, "graph")
    ])
    func scopeDescription(scope: DependencyScope, expected: String) {
        #expect(scope.description == expected)
    }
}

// MARK: - DependencyResolutionError

@Suite("DependencyResolutionError")
struct DependencyResolutionErrorTests {

    @Test("notRegistered error includes type name")
    func notRegisteredMessage() {
        let error = DependencyResolutionError.notRegistered(type: "MyService", name: nil)
        let description = error.localizedDescription
        #expect(description.contains("MyService"))
    }

    @Test("notRegistered error includes name when provided")
    func notRegisteredWithName() {
        let error = DependencyResolutionError.notRegistered(type: "MyService", name: "primary")
        let description = error.localizedDescription
        #expect(description.contains("primary"))
    }

    @Test("typeMismatch error includes both types")
    func typeMismatchMessage() {
        let error = DependencyResolutionError.typeMismatch(expected: "String", actual: "Int")
        let description = error.localizedDescription
        #expect(description.contains("String"))
        #expect(description.contains("Int"))
    }

    @Test("argumentTypeMismatch error includes both parameter types")
    func argumentMismatchMessage() {
        let error = DependencyResolutionError.argumentTypeMismatch(factory: "UUID", provided: "String")
        let description = error.localizedDescription
        #expect(description.contains("UUID"))
        #expect(description.contains("String"))
    }

    @Test("equatable conformance works correctly")
    func equatable() {
        let a = DependencyResolutionError.notRegistered(type: "A", name: nil)
        let b = DependencyResolutionError.notRegistered(type: "A", name: nil)
        let c = DependencyResolutionError.notRegistered(type: "B", name: nil)
        #expect(a == b)
        #expect(a != c)
    }
}
