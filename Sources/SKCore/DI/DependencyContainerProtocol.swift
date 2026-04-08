/// Framework-agnostic dependency injection container.
///
/// Defines the contract for registering and resolving dependencies with
/// lifecycle scopes. Concrete implementations (e.g. a Factory-backed
/// container) conform to this protocol, keeping all application code
/// decoupled from the specific DI framework.
///
/// The container is used **exclusively at the Composition Root** — ViewModels,
/// Use Cases, and Repositories receive their dependencies through constructor
/// injection and never reference the container directly.
///
/// ## Registration
///
/// ```swift
/// container.register(BookmarkRepository.self, scope: .singleton) {
///     BookmarkRepositoryImpl(api: apiClient)
/// }
///
/// // Named registration for disambiguation
/// container.register(StorageProtocol.self, name: "secure", scope: .singleton) {
///     KeychainStorage()
/// }
/// ```
///
/// ## Resolution
///
/// ```swift
/// let repo: BookmarkRepository = container.resolve(BookmarkRepository.self)
/// let secure: StorageProtocol = container.resolve(StorageProtocol.self, name: "secure")
/// ```
///
/// ## Parameterized Resolution
///
/// ```swift
/// container.register(DetailViewModel.self) { (id: UUID) in
///     DetailViewModel(itemID: id, fetch: container.resolve(FetchItemUseCase.self))
/// }
///
/// let vm: DetailViewModel = container.resolve(DetailViewModel.self, argument: itemID)
/// ```
public protocol DependencyContainerProtocol: Sendable {

    // MARK: - Registration

    /// Registers a factory closure for the given type and optional name.
    ///
    /// - Parameters:
    ///   - type: The type (typically a protocol) to register.
    ///   - name: An optional name to disambiguate multiple registrations of the
    ///     same type. Pass `nil` for the default registration.
    ///   - scope: The lifecycle scope controlling instance retention.
    ///     Defaults to ``DependencyScope/unique``.
    ///   - factory: A closure that produces the dependency instance.
    func register<V>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable () -> V
    )

    /// Registers a parameterized factory closure for the given type.
    ///
    /// Use this when the dependency requires a runtime argument that is not
    /// available at registration time (e.g. a screen-specific identifier).
    ///
    /// - Parameters:
    ///   - type: The type (typically a protocol) to register.
    ///   - name: An optional name to disambiguate multiple registrations.
    ///   - scope: The lifecycle scope. Defaults to ``DependencyScope/unique``.
    ///   - factory: A closure that takes a parameter `P` and produces `V`.
    func register<V, P>(
        _ type: V.Type,
        name: String?,
        scope: DependencyScope,
        factory: @escaping @Sendable (P) -> V
    )

    // MARK: - Resolution

    /// Resolves the dependency registered for the given type and optional name.
    ///
    /// - Parameters:
    ///   - type: The type to resolve.
    ///   - name: The name used during registration, or `nil` for the default.
    /// - Returns: The resolved instance.
    func resolve<V>(_ type: V.Type, name: String?) -> V

    /// Resolves a parameterized dependency, passing the argument to the factory.
    ///
    /// - Parameters:
    ///   - type: The type to resolve.
    ///   - name: The name used during registration, or `nil` for the default.
    ///   - argument: The runtime argument forwarded to the factory closure.
    /// - Returns: The resolved instance.
    func resolve<V, P>(_ type: V.Type, name: String?, argument: P) -> V

    // MARK: - Lifecycle

    /// Resets cached instances for the given scope.
    ///
    /// After reset, the next resolution for affected registrations will invoke
    /// their factory closure again.
    ///
    /// - Parameter scope: The scope to reset. Pass `nil` to reset **all** scopes.
    func reset(_ scope: DependencyScope?)
}

// MARK: - Convenience Defaults

public extension DependencyContainerProtocol {

    /// Registers a factory with the default name (`nil`) and scope (`.unique`).
    func register<V>(
        _ type: V.Type,
        scope: DependencyScope = .unique,
        factory: @escaping @Sendable () -> V
    ) {
        register(type, name: nil, scope: scope, factory: factory)
    }

    /// Registers a parameterized factory with the default name and scope.
    func register<V, P>(
        _ type: V.Type,
        scope: DependencyScope = .unique,
        factory: @escaping @Sendable (P) -> V
    ) {
        register(type, name: nil, scope: scope, factory: factory)
    }

    /// Resolves using the default name (`nil`).
    func resolve<V>(_ type: V.Type) -> V {
        resolve(type, name: nil)
    }

    /// Resolves a parameterized dependency using the default name.
    func resolve<V, P>(_ type: V.Type, argument: P) -> V {
        resolve(type, name: nil, argument: argument)
    }

    /// Resets all scopes.
    func reset() {
        reset(nil)
    }
}
