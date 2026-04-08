/// Lifecycle scope for a dependency registration.
///
/// Controls how often a dependency's factory closure is invoked and how long
/// the resulting instance is retained. Concrete DI frameworks
/// (e.g. Factory, Swinject) map these cases to their own scope types.
///
/// ## Scope Behaviors
///
/// ```
/// ┌───────────┬─────────────────────────────────────────────┐
/// │ Scope     │ Behavior                                    │
/// ├───────────┼─────────────────────────────────────────────┤
/// │ unique    │ New instance every resolution               │
/// │ singleton │ Single instance for the app's lifetime      │
/// │ cached    │ Persisted until the container is reset      │
/// │ shared    │ Alive while ≥1 strong reference exists      │
/// │ graph     │ Shared within a single resolution graph     │
/// └───────────┴─────────────────────────────────────────────┘
/// ```
///
/// ## Usage
///
/// ```swift
/// container.register(BookmarkRepository.self, scope: .singleton) {
///     BookmarkRepositoryImpl(api: apiClient, storage: localStorage)
/// }
///
/// container.register(SearchViewModel.self, scope: .unique) {
///     SearchViewModel(search: container.resolve(SearchUseCase.self))
/// }
/// ```
public enum DependencyScope: Sendable {
    /// A new instance is created every time the dependency is resolved.
    case unique

    /// A single instance is created on first resolution and reused for the
    /// entire lifetime of the application. The instance is never released.
    case singleton

    /// The instance is created on first resolution and cached until the
    /// container's ``DependencyContainerProtocol/reset(_:)`` is called.
    /// Useful for session-scoped dependencies that outlive individual screens.
    case cached

    /// The instance is retained only while at least one strong reference
    /// exists outside the container. Once all external references are
    /// released, the next resolution creates a new instance.
    case shared

    /// The instance is shared across all resolutions that occur within the
    /// same object-graph construction. Once the graph is fully built, the
    /// reference is discarded. Useful for ensuring a single instance is
    /// shared across a coordinator and its child ViewModels during setup.
    case graph
}

// MARK: - CustomStringConvertible

extension DependencyScope: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unique: "unique"
        case .singleton: "singleton"
        case .cached: "cached"
        case .shared: "shared"
        case .graph: "graph"
        }
    }
}
