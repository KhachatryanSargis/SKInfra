import Foundation

import SKCore

/// Default implementation of ``DependencyContainerProtocol``.
///
/// Provides thread-safe dependency registration and resolution with full
/// scope lifecycle management (unique, singleton, cached, shared, graph).
/// All application code depends only on ``DependencyContainerProtocol``
/// from SKCore — this concrete type is referenced only at the Composition Root.
///
/// ## Setup at the Composition Root
///
/// ```swift
/// import SKDI
///
/// let container = FactoryDependencyContainer()
///
/// container.register(BookmarkRepository.self, scope: .singleton) {
///     BookmarkRepositoryImpl(api: apiClient)
/// }
///
/// let repo = container.resolve(BookmarkRepository.self)
/// let vm = BookmarkListViewModel(
///     fetchBookmarks: FetchBookmarksUseCaseImpl(repository: repo),
///     deleteBookmark: DeleteBookmarkUseCaseImpl(repository: repo)
/// )
/// ```
///
/// ## Testing
///
/// ```swift
/// let container = FactoryDependencyContainer()
/// container.register(BookmarkRepository.self) { MockBookmarkRepository() }
/// // resolve returns the mock
/// container.reset()  // clears all cached instances
/// ```
public final class FactoryDependencyContainer: DependencyContainerProtocol, @unchecked Sendable {
    // SAFETY: all access to `registrations` is guarded by `lock`

    private let lock = NSLock()
    private var registrations: [RegistrationKey: Any] = [:]

    public init() {}

    // MARK: - Registration

    public func register<V>(
        _ type: V.Type,
        name: String? = nil,
        scope: DependencyScope = .unique,
        factory: @escaping @Sendable () -> V
    ) {
        let key = RegistrationKey(type: "\(V.self)", name: name)
        let entry = Registration(scope: scope, factory: factory)
        lock.withLock { registrations[key] = entry }
    }

    public func register<V, P>(
        _ type: V.Type,
        name: String? = nil,
        scope: DependencyScope = .unique,
        factory: @escaping @Sendable (P) -> V
    ) {
        let key = RegistrationKey(type: "\(V.self)", name: name, parameterType: "\(P.self)")
        let entry = ParameterRegistration<V, P>(scope: scope, factory: factory)
        lock.withLock { registrations[key] = entry }
    }

    // MARK: - Resolution

    public func resolve<V>(_ type: V.Type, name: String? = nil) -> V {
        let key = RegistrationKey(type: "\(V.self)", name: name)
        let entry: Registration<V> = lock.withLock {
            guard let raw = registrations[key] else {
                fatalError(
                    DependencyResolutionError
                        .notRegistered(type: "\(V.self)", name: name)
                        .localizedDescription
                )
            }
            guard let typed = raw as? Registration<V> else {
                fatalError(
                    DependencyResolutionError
                        .typeMismatch(expected: "\(V.self)", actual: "\(Swift.type(of: raw))")
                        .localizedDescription
                )
            }
            return typed
        }
        return entry.resolve()
    }

    public func resolve<V, P>(_ type: V.Type, name: String? = nil, argument: P) -> V {
        let key = RegistrationKey(type: "\(V.self)", name: name, parameterType: "\(P.self)")
        let entry: ParameterRegistration<V, P> = lock.withLock {
            guard let raw = registrations[key] else {
                fatalError(
                    DependencyResolutionError
                        .notRegistered(type: "\(V.self)", name: name)
                        .localizedDescription
                )
            }
            guard let typed = raw as? ParameterRegistration<V, P> else {
                fatalError(
                    DependencyResolutionError
                        .argumentTypeMismatch(
                            factory: "\(P.self)",
                            provided: "\(Swift.type(of: argument))"
                        )
                        .localizedDescription
                )
            }
            return typed
        }
        return entry.resolve(argument: argument)
    }

    // MARK: - Lifecycle

    public func reset(_ scope: DependencyScope? = nil) {
        lock.withLock {
            if let scope {
                for (_, entry) in registrations {
                    if let resettable = entry as? Resettable, resettable.scope == scope {
                        resettable.reset()
                    }
                }
            } else {
                for (_, entry) in registrations {
                    (entry as? Resettable)?.reset()
                }
            }
        }
    }
}

// MARK: - Internal Types

private extension FactoryDependencyContainer {

    /// Composite key for the registration dictionary.
    struct RegistrationKey: Hashable {
        let type: String
        let name: String?
        var parameterType: String?
    }

    /// Allows resetting cached instances by scope without knowing the generic type.
    protocol Resettable: AnyObject {
        var scope: DependencyScope { get }
        func reset()
    }

    /// Holds a zero-parameter factory and its scoped cache.
    final class Registration<V>: Resettable {
        let scope: DependencyScope
        private let factory: @Sendable () -> V
        private var cachedValue: V?
        private weak var weakRef: AnyObject?

        init(scope: DependencyScope, factory: @escaping @Sendable () -> V) {
            self.scope = scope
            self.factory = factory
        }

        func resolve() -> V {
            switch scope {
            case .unique:
                return factory()
            case .singleton, .cached, .graph:
                if let cached = cachedValue {
                    return cached
                }
                let value = factory()
                cachedValue = value
                return value
            case .shared:
                if let ref = weakRef, let value = ref as? V {
                    return value
                }
                let value = factory()
                weakRef = value as AnyObject
                return value
            }
        }

        func reset() {
            cachedValue = nil
            weakRef = nil
        }
    }

    /// Holds a parameterized factory and its scoped cache.
    final class ParameterRegistration<V, P>: Resettable {
        let scope: DependencyScope
        private let factory: @Sendable (P) -> V
        private var cachedValue: V?

        init(scope: DependencyScope, factory: @escaping @Sendable (P) -> V) {
            self.scope = scope
            self.factory = factory
        }

        func resolve(argument: P) -> V {
            switch scope {
            case .unique:
                return factory(argument)
            case .singleton, .cached, .graph:
                if let cached = cachedValue {
                    return cached
                }
                let value = factory(argument)
                cachedValue = value
                return value
            case .shared:
                return factory(argument)
            }
        }

        func reset() {
            cachedValue = nil
        }
    }
}
