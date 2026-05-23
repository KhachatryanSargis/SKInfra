import Foundation
import SKCore

// MARK: - Mock Dependency Container

/// Records all calls to ``DependencyContainerProtocol`` for verifying
/// dependent code behaviour. Returns pre-configured values on resolution.
///
/// This mock tests the **protocol-level** contract — it does NOT replicate
/// scope lifecycle. Tests for scope behavior belong in the concrete
/// container's test suite.
///
/// ## Thread Safety
///
/// `@unchecked Sendable` — this mock is intended for single-test use where
/// access is naturally serialized. Do not share an instance across
/// concurrent tasks without adding synchronization.
public final class MockDependencyContainer: DependencyContainerProtocol, @unchecked Sendable {

    // MARK: - Call Records

    /// Record of a single `register` call.
    public struct RegisterCall: Equatable, Sendable {
        public let type: String
        public let name: String?
        public let scope: DependencyScope

        public init(type: String, name: String?, scope: DependencyScope) {
            self.type = type
            self.name = name
            self.scope = scope
        }
    }

    /// Record of a single `resolve` call.
    public struct ResolveCall: Equatable, Sendable {
        public let type: String
        public let name: String?

        public init(type: String, name: String?) {
            self.type = type
            self.name = name
        }
    }

    /// Record of a single parameter-based `resolve` call.
    public struct ParameterResolveCall: Equatable, Sendable {
        public let type: String
        public let name: String?
        public let argumentType: String

        public init(type: String, name: String?, argumentType: String) {
            self.type = type
            self.name = name
            self.argumentType = argumentType
        }
    }

    public private(set) var registerCalls: [RegisterCall] = []
    public private(set) var parameterRegisterCalls: [RegisterCall] = []
    public private(set) var resolveCalls: [ResolveCall] = []
    public private(set) var parameterResolveCalls: [ParameterResolveCall] = []
    public private(set) var resetCalls: [DependencyScope?] = []

    // MARK: - Stub Storage

    private var stubs: [String: Any] = [:]

    /// Creates a mock dependency container with no stubs.
    public init() {}

    /// Pre-configures a value to return when `resolve(_:name:)` is called.
    ///
    /// - Parameters:
    ///   - type: The type the stub should be returned for.
    ///   - name: An optional registration name.
    ///   - value: The instance to return on resolve.
    public func stub<V>(_ type: V.Type, name: String? = nil, value: V) {
        let key = stubKey(type: "\(V.self)", name: name)
        stubs[key] = value
    }

    // MARK: - DependencyContainerProtocol

    public func register<V>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable () -> V
    ) {
        registerCalls.append(RegisterCall(type: "\(V.self)", name: name, scope: scope))
    }

    public func register<V, P>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable (P) -> V
    ) {
        parameterRegisterCalls.append(RegisterCall(type: "\(V.self)", name: name, scope: scope))
    }

    public func resolve<V>(_ type: V.Type, name: String?) -> V {
        resolveCalls.append(ResolveCall(type: "\(V.self)", name: name))
        let key = stubKey(type: "\(V.self)", name: name)
        guard let value = stubs[key] as? V else {
            fatalError("No stub configured for \(V.self) (name: \(name ?? "nil"))")
        }
        return value
    }

    public func resolve<V, P>(_ type: V.Type, name: String?, argument: P) -> V {
        parameterResolveCalls.append(
            ParameterResolveCall(type: "\(V.self)", name: name, argumentType: "\(P.self)")
        )
        let key = stubKey(type: "\(V.self)", name: name)
        guard let value = stubs[key] as? V else {
            fatalError("No stub configured for \(V.self) (name: \(name ?? "nil"))")
        }
        return value
    }

    public func reset(_ scope: DependencyScope?) {
        resetCalls.append(scope)
    }

    // MARK: - Private

    private func stubKey(type: String, name: String?) -> String {
        "\(type):\(name ?? "_default_")"
    }
}
