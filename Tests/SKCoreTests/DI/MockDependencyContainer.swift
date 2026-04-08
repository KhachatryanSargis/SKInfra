@testable import SKCore

/// Records all calls to the container protocol for verifying convenience
/// extension behavior. Returns pre-configured values on resolution.
///
/// This mock tests the **protocol extension** defaults — it does NOT test
/// scope lifecycle (that belongs in the concrete container's test suite).
final class MockDependencyContainer: DependencyContainerProtocol, @unchecked Sendable {
    // SAFETY: only accessed from a single test at a time

    // MARK: - Call Records

    struct RegisterCall: Equatable {
        let type: String
        let name: String?
        let scope: DependencyScope
    }

    struct ResolveCall: Equatable {
        let type: String
        let name: String?
    }

    struct ParameterResolveCall: Equatable {
        let type: String
        let name: String?
        let argumentType: String
    }

    private(set) var registerCalls: [RegisterCall] = []
    private(set) var parameterRegisterCalls: [RegisterCall] = []
    private(set) var resolveCalls: [ResolveCall] = []
    private(set) var parameterResolveCalls: [ParameterResolveCall] = []
    private(set) var resetCalls: [DependencyScope?] = []

    // MARK: - Stub Storage

    private var stubs: [String: Any] = [:]

    /// Pre-configures a value to return when `resolve(_:name:)` is called.
    func stub<V>(_ type: V.Type, name: String? = nil, value: V) {
        let key = stubKey(type: "\(V.self)", name: name)
        stubs[key] = value
    }

    // MARK: - DependencyContainerProtocol

    func register<V>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable () -> V
    ) {
        registerCalls.append(RegisterCall(type: "\(V.self)", name: name, scope: scope))
    }

    func register<V, P>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable (P) -> V
    ) {
        parameterRegisterCalls.append(RegisterCall(type: "\(V.self)", name: name, scope: scope))
    }

    func resolve<V>(_ type: V.Type, name: String?) -> V {
        resolveCalls.append(ResolveCall(type: "\(V.self)", name: name))
        let key = stubKey(type: "\(V.self)", name: name)
        guard let value = stubs[key] as? V else {
            fatalError("No stub configured for \(V.self) (name: \(name ?? "nil"))")
        }
        return value
    }

    func resolve<V, P>(_ type: V.Type, name: String?, argument: P) -> V {
        parameterResolveCalls.append(
            ParameterResolveCall(type: "\(V.self)", name: name, argumentType: "\(P.self)")
        )
        let key = stubKey(type: "\(V.self)", name: name)
        guard let value = stubs[key] as? V else {
            fatalError("No stub configured for \(V.self) (name: \(name ?? "nil"))")
        }
        return value
    }

    func reset(_ scope: DependencyScope?) {
        resetCalls.append(scope)
    }

    // MARK: - Private

    private func stubKey(type: String, name: String?) -> String {
        "\(type):\(name ?? "_default_")"
    }
}
