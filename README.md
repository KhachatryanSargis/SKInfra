# SKInfra

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange?logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

Reusable iOS and macOS infrastructure libraries. SKInfra is a monorepo that exposes multiple SPM products — import only what you need.

> **Architecture:** Feature modules depend on **SKCore** (protocols). The app layer imports implementation packages (**SKDI**, **SKStorage**, **SKNavigation**, **SKAnalytics**) and wires them at the Composition Root. SPM compiles only the products you declare.

---

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.1+
- Xcode 16.3+

---

## Installation

**Xcode:** File > Add Package Dependencies > enter the repository URL, select *Up to Next Major Version*.

**`Package.swift`:**

```swift
dependencies: [
    .package(url: "https://github.com/KhachatryanSargis/SKInfra.git", from: "1.0.0")
],
targets: [
    // Feature modules — depend on protocols only
    .target(name: "MyFeature", dependencies: [
        .product(name: "SKCore", package: "SKInfra")
    ]),
    // App layer — wires concrete implementations
    .target(name: "MyApp", dependencies: [
        .product(name: "SKCore", package: "SKInfra"),
        .product(name: "SKDI", package: "SKInfra"),
        .product(name: "SKNavigation", package: "SKInfra"),
        .product(name: "SKStorage", package: "SKInfra"),
        .product(name: "SKAnalytics", package: "SKInfra")
    ])
]
```

---

## Products

| Product | Description | Key Types |
|---------|-------------|-----------|
| **SKCore** | Foundation protocols and utilities — DI, Storage, Logger, Analytics, Namespace, Extensions | `DependencyContainerProtocol`, `StorageProtocol`, `LoggerProtocol`, `AnalyticsProtocol`, `ImageCacheProtocol` |
| **SKDI** | Dependency injection container with scoped lifecycles | `FactoryDependencyContainer` |
| **SKNavigation** | Type-safe SwiftUI Coordinator-based navigation | `Coordinator`, `NavigationRouter`, `Route`, `TabRouter` |
| **SKStorage** | Image caching (memory + disk) and SwiftData persistence | `ImageCacheCoordinator`, `SwiftDataRepository` |
| **SKAnalytics** | Provider-agnostic analytics tracking with composable providers | `CompositeAnalyticsProvider`, `SuperPropertyProvider`, `PrintAnalyticsProvider` |

### Dependency Graph

```
SKCore (protocols — zero dependencies)
  ↑
  ├── SKDI
  ├── SKNavigation
  ├── SKStorage
  └── SKAnalytics
```

All products depend only on SKCore. No cross-dependencies.

---

## SKCore

Type-safe protocols and utilities that define the contracts all other products implement against. Zero external dependencies.

### Dependency Injection

Framework-agnostic DI container protocol. The container is used exclusively at the Composition Root — all other code receives dependencies through constructor injection.

| Scope | Behavior |
|-------|----------|
| `unique` | New instance every resolution |
| `singleton` | Single instance for the app's lifetime |
| `cached` | Persisted until the container is reset |
| `shared` | Alive while at least one strong reference exists |
| `graph` | Shared within a single resolution graph |

```swift
container.register(BookmarkRepository.self, scope: .singleton) {
    BookmarkRepositoryImpl(api: apiClient)
}

let repo = container.resolve(BookmarkRepository.self)
```

### Storage

Type-safe key-value storage using phantom-typed keys:

```swift
extension StorageKey where Value == String {
    static let authToken = StorageKey("auth_token")
}

let storage: StorageProtocol = UserDefaultsStorage()
try storage.save("bearer_abc", forKey: .authToken)
```

| Type | Backed By | Use Case |
|------|-----------|----------|
| `UserDefaultsStorage` | `UserDefaults` | Preferences, flags, non-sensitive settings |
| `KeychainStorage` | Security framework | Tokens, credentials, sensitive data |

### Logger

Protocol-oriented logging with convenience methods per severity level:

```swift
let logger: some LoggerProtocol = OSLogLogger(
    subsystem: "com.example.myapp",
    category: "Networking",
    minimumLevel: .info
)

logger.debug("Payload decoded")
logger.error("Connection failed: \(error)")
```

| Type | Backed By | Use Case |
|------|-----------|----------|
| `PrintLogger` | `print()` | Development, debugging, unit tests |
| `OSLogLogger` | `os.Logger` | Production — Console.app, log stream |
| `CompositeLogger` | N child loggers | Multi-destination forwarding |

### Analytics

Provider-agnostic analytics protocol for event tracking, user identification, and property management. Vendor SDKs (Mixpanel, Amplitude, Firebase, etc.) are wrapped at the application layer.

```swift
analytics.track("purchase_completed", properties: [
    "item_id": "abc-123",
    "price": 9.99,
    "is_first_purchase": true
])

analytics.identify(userId: "user-42")
analytics.screen("HomeScreen")
```

### Namespace & Extensions

All extensions live behind `.sk` to avoid collisions:

```swift
"hello world".sk.capitalizingFirstLetter()  // "Hello world"
[1, 2, 2, 3].sk.uniqued()                  // [1, 2, 3]
```

---

## SKDI

Concrete `DependencyContainerProtocol` implementation with thread-safe registration, resolution, and full scope lifecycle management.

```swift
let container = FactoryDependencyContainer()
container.register(BookmarkRepository.self, scope: .singleton) {
    BookmarkRepositoryImpl(api: apiClient)
}
let repo = container.resolve(BookmarkRepository.self)
```

---

## SKNavigation

Type-safe SwiftUI navigation built on the Coordinator pattern. Coordinators own routers, views are stateless with respect to navigation.

```swift
@Observable @MainActor
final class CatalogCoordinator: Coordinator {
    typealias RouteType = CatalogRoute
    let router = NavigationRouter<CatalogRoute>()

    @ViewBuilder
    func rootView() -> some View { CatalogListView(coordinator: self) }

    @ViewBuilder
    func destination(for route: CatalogRoute) -> some View {
        switch route {
        case .list: CatalogListView(coordinator: self)
        case .detail(let id): CatalogDetailView(id: id, coordinator: self)
        }
    }
}
```

---

## SKStorage

Image caching and SwiftData persistence implementations for SKCore protocols.

```swift
// Two-tier image cache (memory + disk)
let cache = ImageCacheCoordinator()
await cache.store(image, for: imageURL)

// SwiftData CRUD
let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)
try await repo.insert(Item(name: "New"))
```

---

## SKAnalytics

Provider-agnostic analytics implementations for SKCore's `AnalyticsProtocol`. Compose multiple providers, attach persistent super properties, and swap backends without touching feature code.

```swift
// Compose providers — debug console + production backend
let analytics = CompositeAnalyticsProvider(providers: [
    PrintAnalyticsProvider(),
    mixpanelProvider  // your AnalyticsProtocol wrapper
])

// Attach super properties to every event
let tracked = SuperPropertyProvider(
    wrapping: analytics,
    initialProperties: ["app_version": "2.1.0", "platform": "iOS"]
)
```

| Type | Description |
|------|-------------|
| `PrintAnalyticsProvider` | Debug console output (mirrors `PrintLogger`) |
| `CompositeAnalyticsProvider` | Multi-provider fan-out (mirrors `CompositeLogger`) |
| `SuperPropertyProvider` | Decorator that attaches persistent properties to every event |

---

## Package Structure

```
SKInfra/
├── Package.swift
├── Sources/
│   ├── SKCore/
│   │   ├── Analytics/
│   │   ├── DI/
│   │   ├── Extensions/
│   │   ├── Logger/
│   │   ├── Namespace/
│   │   └── Storage/
│   ├── SKAnalytics/
│   ├── SKDI/
│   ├── SKNavigation/
│   │   ├── Coordinator/
│   │   ├── CrossModule/
│   │   ├── DeepLink/
│   │   ├── Route/
│   │   ├── Router/
│   │   └── View/
│   └── SKStorage/
│       ├── ImageCache/
│       └── SwiftData/
└── Tests/
    ├── SKAnalyticsTests/
    ├── SKCoreTests/
    ├── SKDITests/
    ├── SKNavigationTests/
    └── SKStorageTests/
```

---

## Dependencies

None. SKInfra has zero external dependencies.

---

## License

MIT
