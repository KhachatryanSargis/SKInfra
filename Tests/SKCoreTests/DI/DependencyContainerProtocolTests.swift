import Testing
@testable import SKCore

// MARK: - Test Doubles

private protocol TestServiceProtocol: Sendable {
    var id: String { get }
}

private struct TestService: TestServiceProtocol, Sendable {
    let id: String
}

@Suite("DependencyContainerProtocol — Convenience Extensions")
struct DependencyContainerProtocolTests {

    // MARK: - register(_:scope:factory:)

    @Test("Convenience register forwards nil name to the protocol requirement")
    func registerForwardsNilName() {
        let mock = MockDependencyContainer()

        mock.register(String.self, scope: .singleton) { "value" }

        let call = mock.registerCalls.first
        #expect(call?.name == nil)
        #expect(call?.scope == .singleton)
        #expect(call?.type == "String")
    }

    @Test("Convenience register defaults scope to unique")
    func registerDefaultsToUnique() {
        let mock = MockDependencyContainer()

        mock.register(String.self) { "value" }

        let call = mock.registerCalls.first
        #expect(call?.scope == .unique)
    }

    // MARK: - register(_:scope:factory:) (parameterized)

    @Test("Parameterized convenience register forwards nil name")
    func parameterRegisterForwardsNilName() {
        let mock = MockDependencyContainer()

        mock.register(String.self, scope: .cached) { (id: Int) in "\(id)" }

        let call = mock.parameterRegisterCalls.first
        #expect(call?.name == nil)
        #expect(call?.scope == .cached)
    }

    @Test("Parameterized convenience register defaults scope to unique")
    func parameterRegisterDefaultsToUnique() {
        let mock = MockDependencyContainer()

        mock.register(String.self) { (id: Int) in "\(id)" }

        let call = mock.parameterRegisterCalls.first
        #expect(call?.scope == .unique)
    }

    // MARK: - resolve(_:)

    @Test("Convenience resolve forwards nil name")
    func resolveForwardsNilName() {
        let mock = MockDependencyContainer()
        mock.stub(String.self, value: "hello")

        let result: String = mock.resolve(String.self)

        #expect(result == "hello")
        #expect(mock.resolveCalls.first?.name == nil)
    }

    // MARK: - resolve(_:argument:)

    @Test("Parameterized convenience resolve forwards nil name")
    func parameterResolveForwardsNilName() {
        let mock = MockDependencyContainer()
        mock.stub(String.self, value: "resolved")

        let result: String = mock.resolve(String.self, argument: 42)

        #expect(result == "resolved")
        let call = mock.parameterResolveCalls.first
        #expect(call?.name == nil)
        #expect(call?.argumentType == "Int")
    }

    // MARK: - reset()

    @Test("Convenience reset forwards nil scope")
    func resetForwardsNilScope() {
        let mock = MockDependencyContainer()

        mock.reset()

        #expect(mock.resetCalls.count == 1)
        #expect(mock.resetCalls.first == nil as DependencyScope?)
    }

    // MARK: - Protocol-Based Resolution

    @Test("Resolves a protocol type through the convenience method")
    func resolveProtocolType() {
        let mock = MockDependencyContainer()
        let service = TestService(id: "test-123")
        mock.stub(TestServiceProtocol.self, value: service)

        let resolved: TestServiceProtocol = mock.resolve(TestServiceProtocol.self)

        #expect(resolved.id == "test-123")
    }

    // MARK: - Named vs Default

    @Test("Named and default registrations produce separate calls")
    func namedVsDefault() {
        let mock = MockDependencyContainer()

        mock.register(String.self) { "default" }
        mock.register(String.self, name: "special", scope: .singleton) { "special" }

        #expect(mock.registerCalls.count == 2)
        #expect(mock.registerCalls[0].name == nil)
        #expect(mock.registerCalls[1].name == "special")
    }

    // MARK: - Multiple Resolutions

    @Test("Multiple resolve calls are all recorded")
    func multipleResolveCalls() {
        let mock = MockDependencyContainer()
        mock.stub(String.self, value: "v")

        _ = mock.resolve(String.self)
        _ = mock.resolve(String.self)
        _ = mock.resolve(String.self)

        #expect(mock.resolveCalls.count == 3)
    }
}
