---
name: skcore
description: SKCore protocols and utilities — DependencyContainerProtocol, DependencyScope, StorageProtocol, StorageKey, LoggerProtocol, ImageCacheProtocol, PersistentRepositoryProtocol, PlatformImage, .sk namespace extensions. Use when implementing features that depend on SKCore contracts.
---

# SKCore — Consumer Reference

> **Scope:** DI container protocol, storage, logger, image cache, persistent repository, namespace extensions
> **Layer:** SKCore is the protocol layer. Feature modules depend only on SKCore. Concrete implementations come from SKDI, SKStorage, SKNavigation.

## Dependency Injection

`DependencyContainerProtocol` — framework-agnostic container used at the Composition Root only.
ViewModels, Use Cases, and Repositories receive dependencies through constructor injection.

### Scopes

| Scope | Behavior |
|-------|----------|
| `.unique` | New instance every resolution |
| `.singleton` | One instance for the app's lifetime |
| `.cached` | Persisted until `container.reset(.cached)` |
| `.shared` | Alive while ≥1 strong reference exists |
| `.graph` | Shared within a single resolution graph |

### Registration & Resolution

```swift
// Composition Root — register by protocol type
container.register(BookmarkRepository.self, scope: .singleton) {
    BookmarkRepositoryImpl(api: apiClient)
}

// Named registration for disambiguation
container.register(StorageProtocol.self, name: "secure", scope: .singleton) {
    KeychainStorage()
}

// Parameterized — runtime argument not known at registration time
container.register(DetailViewModel.self) { (id: UUID) in
    DetailViewModel(itemID: id, fetch: container.resolve(FetchItemUseCase.self))
}

// Resolution
let repo = container.resolve(BookmarkRepository.self)
let vm = container.resolve(DetailViewModel.self, argument: itemID)
```

### Errors

`DependencyResolutionError` — `.notRegistered`, `.typeMismatch`, `.argumentTypeMismatch`.
These are fatal in production (the container crashes). Catch misconfigurations during development.

## Storage

### StorageKey (phantom-typed)

```swift
extension StorageKey where Value == String {
    static let authToken = StorageKey("auth_token")
}
extension StorageKey where Value == User {
    static let currentUser = StorageKey("current_user")
}
```

### StorageProtocol

```swift
let storage: StorageProtocol = UserDefaultsStorage()
try storage.save("bearer_abc", forKey: .authToken)
let token: String? = try storage.load(forKey: .authToken)
try storage.delete(forKey: .authToken)
```

| Implementation | Use Case |
|----------------|----------|
| `UserDefaultsStorage` | Preferences, flags, non-sensitive settings |
| `KeychainStorage` | Tokens, credentials, sensitive data |

### ImageCacheProtocol

```swift
func loadAvatar(cache: any ImageCacheProtocol, url: URL) async -> PlatformImage? {
    await cache.image(for: url)
}
```

- Use `PlatformImage` — resolves to `UIImage` on iOS, `NSImage` on macOS
- **MUST NOT** reference `UIImage`/`NSImage` directly in feature modules

### PersistentRepositoryProtocol

```swift
func fetchItems<T: PersistentModel>(repo: any PersistentRepositoryProtocol<T>) async throws -> [T] {
    try await repo.fetch()
}
```

## Logger

### Setup

```swift
// Development
let logger: some LoggerProtocol = PrintLogger(minimumLevel: .debug)

// Production
let logger: some LoggerProtocol = OSLogLogger(
    subsystem: "com.example.myapp", category: "Networking", minimumLevel: .info
)

// Multi-destination
let logger: some LoggerProtocol = CompositeLogger(loggers: [
    PrintLogger(minimumLevel: .debug),
    OSLogLogger(subsystem: "com.example.myapp", category: "Main", minimumLevel: .warning)
])
```

### Usage

```swift
logger.debug("Payload decoded")
logger.info("Request started")
logger.warning("Cache miss")
logger.error("Connection failed: \(error)")
```

Messages below `minimumLevel` are discarded without evaluating the closure.

- **MUST** inject loggers via constructor — never call `print()` directly
- **MUST** use `LoggerProtocol` as the dependency type

## Namespace & Extensions

All SKCore extensions live behind `.sk` to avoid collisions:

```swift
"hello world".sk.capitalizingFirstLetter()  // "Hello world"
"  ".sk.nilIfEmpty()                        // nil
"Hello!".sk.truncated(to: 3)               // "Hel…"
"abc123".sk.isAlphanumeric                  // true

let name: String? = nil
name.sk.isNil                               // true

[10, 20, 30].sk.element(at: 5)             // nil (safe subscript)
[1, 2, 2, 3].sk.uniqued()                  // [1, 2, 3]
```

- **MUST NOT** add bare extensions on Foundation types — always use the `.sk` namespace
