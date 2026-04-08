---
name: skstorage
description: SKStorage image caching and SwiftData persistence — ImageCacheCoordinator, InMemoryImageCache, DiskImageCache, SwiftDataRepository, two-tier cache, PlatformImage. Use when implementing image caching, disk cache, memory cache, or SwiftData CRUD operations.
---

# SKStorage — Consumer Reference

> **Scope:** Two-tier image caching (memory + disk), SwiftData repository
> **Layer:** SKStorage implements SKCore protocols (`ImageCacheProtocol`, `PersistentRepositoryProtocol`). Injected at the Composition Root.

## Image Caching

### ImageCacheCoordinator (two-tier)

The primary cache type. Checks memory first, falls back to disk, auto-promotes to memory on disk hits.

```swift
let cache: ImageCacheProtocol = ImageCacheCoordinator()

// Store
await cache.store(image, for: imageURL)

// Retrieve — memory hit is instant, disk hit promotes to memory
let cached = await cache.image(for: imageURL)

// Remove single entry
await cache.remove(for: imageURL)

// Clear everything
await cache.clear()
```

### Individual Caches

Use these directly only when you need fine-grained control:

```swift
// Memory only — NSCache-backed, auto-eviction
let memory = InMemoryImageCache(countLimit: 100)

// Disk only — file-based, SHA-256 filenames
let disk = DiskImageCache()

// Custom coordinator with tuned caches
let cache = ImageCacheCoordinator(
    memoryCache: InMemoryImageCache(countLimit: 50),
    diskCache: DiskImageCache()
)
```

### Feature Module Usage

Feature modules depend on `ImageCacheProtocol` from SKCore — never import SKStorage directly:

```swift
// Feature module
import SKCore

final class AvatarViewModel {
    private let cache: ImageCacheProtocol

    init(cache: ImageCacheProtocol) {
        self.cache = cache
    }

    func loadAvatar(url: URL) async -> PlatformImage? {
        await cache.image(for: url)
    }
}
```

### Platform Image

`PlatformImage` is a cross-platform typealias from SKCore:
- iOS: `UIImage`
- macOS: `NSImage`

**MUST** use `PlatformImage` in all shared code — never reference `UIImage`/`NSImage` directly.

## SwiftData Persistence

### SwiftDataRepository

Generic CRUD repository wrapping `ModelContext`:

```swift
let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)

// Insert
try await repo.insert(Item(name: "New Item"))

// Fetch all
let items = try await repo.fetch()

// Fetch with predicate
let filtered = try await repo.fetch(
    predicate: #Predicate<Item> { $0.name.contains("search") }
)

// Delete
try await repo.delete(item)
```

### Feature Module Usage

Feature modules depend on `PersistentRepositoryProtocol` from SKCore:

```swift
// Feature module
import SKCore

final class ItemListViewModel {
    private let repository: PersistentRepositoryProtocol<Item>

    init(repository: PersistentRepositoryProtocol<Item>) {
        self.repository = repository
    }

    func loadItems() async throws -> [Item] {
        try await repository.fetch()
    }
}
```

## Concurrency Model

All SKStorage types use actor isolation:

| Type | Isolation | Why |
|------|-----------|-----|
| `InMemoryImageCache` | `actor` | Thread-safe NSCache wrapper |
| `DiskImageCache` | `actor` | File system access |
| `ImageCacheCoordinator` | `actor` | Coordinates memory + disk |
| `SwiftDataRepository` | `@MainActor` | SwiftData requirement |

All public APIs are `async` — callers must `await`.

## Composition Root Wiring

```swift
// Register at the Composition Root
container.register(ImageCacheProtocol.self, scope: .singleton) {
    ImageCacheCoordinator()
}

container.register(PersistentRepositoryProtocol<Item>.self, scope: .singleton) {
    SwiftDataRepository<Item>(modelContext: modelContainer.mainContext)
}
```

## Rules

- **MUST** import SKStorage only at the Composition Root — feature modules use SKCore protocols
- **MUST** use `PlatformImage` for cross-platform compatibility
- **MUST** `await` all cache and repository operations
- **MUST** register caches as `.singleton` — avoid creating multiple cache instances
