---
name: skdi
description: SKDI dependency injection container — FactoryDependencyContainer, scoped registration and resolution, container reset for testing, Composition Root wiring. Use when setting up DI, wiring dependencies, or writing tests that need container reset.
---

# SKDI — Consumer Reference

> **Scope:** Concrete DI container implementation, Composition Root wiring, test container setup
> **Layer:** SKDI implements `DependencyContainerProtocol` from SKCore. Only imported at the Composition Root.

## FactoryDependencyContainer

Thread-safe container with `NSLock`-guarded registration dictionary and full scope lifecycle.

### Composition Root Setup

```swift
import SKDI

let container = FactoryDependencyContainer()

// Infrastructure
container.register(StorageProtocol.self, name: "defaults", scope: .singleton) {
    UserDefaultsStorage()
}
container.register(StorageProtocol.self, name: "secure", scope: .singleton) {
    KeychainStorage()
}
container.register(LoggerProtocol.self, scope: .singleton) {
    CompositeLogger(loggers: [
        PrintLogger(minimumLevel: .debug),
        OSLogLogger(subsystem: "com.example.app", category: "Main", minimumLevel: .info)
    ])
}

// Repositories
container.register(BookmarkRepository.self, scope: .singleton) {
    BookmarkRepositoryImpl(
        api: container.resolve(APIClient.self),
        storage: container.resolve(StorageProtocol.self, name: "defaults")
    )
}

// Use Cases
container.register(FetchBookmarksUseCase.self) {
    FetchBookmarksUseCaseImpl(repository: container.resolve(BookmarkRepository.self))
}

// ViewModels — typically .unique (one per screen)
container.register(BookmarkListViewModel.self, scope: .unique) {
    BookmarkListViewModel(
        fetchBookmarks: container.resolve(FetchBookmarksUseCase.self),
        deleteBookmark: container.resolve(DeleteBookmarkUseCase.self)
    )
}
```

### Parameterized Resolution

```swift
container.register(DetailViewModel.self) { (id: UUID) in
    DetailViewModel(
        itemID: id,
        fetchItem: container.resolve(FetchItemUseCase.self)
    )
}

// At navigation time
let vm = container.resolve(DetailViewModel.self, argument: selectedItemID)
```

### Scope Selection Guide

| What | Scope | Why |
|------|-------|-----|
| API clients, loggers, storage | `.singleton` | One shared instance, never recreated |
| Auth session, user profile cache | `.cached` | Lives until logout (`container.reset(.cached)`) |
| Repositories | `.singleton` | Stateless, shared safely |
| Use Cases | `.unique` | Lightweight, no state |
| ViewModels | `.unique` | One per screen instance |
| Shared coordinator dependencies | `.graph` | Same instance during coordinator setup |

### Testing

```swift
func makeTestContainer() -> DependencyContainerProtocol {
    let container = FactoryDependencyContainer()
    container.register(BookmarkRepository.self) { MockBookmarkRepository() }
    container.register(FetchBookmarksUseCase.self) {
        FetchBookmarksUseCaseImpl(repository: container.resolve(BookmarkRepository.self))
    }
    return container
}

// Between tests — clear cached/singleton instances
container.reset()           // all scopes
container.reset(.cached)    // only cached scope
```

## Rules

- **MUST** import SKDI only at the Composition Root — never in feature modules
- **MUST** register by protocol type, not concrete type
- **MUST** use constructor injection — ViewModels, Use Cases, Repositories never reference the container
- **MUST** call `container.reset()` in test setup to prevent cross-test state leaks
