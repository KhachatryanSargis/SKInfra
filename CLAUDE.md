# SKInfra — Package Rules

Claude reads this file when working on files inside the SKInfra monorepo.

## Package Overview

SKInfra is a monorepo containing reusable iOS/macOS infrastructure libraries.
Cross-platform (iOS 17+ / macOS 14+), Swift 6.1, strict concurrency. Zero
runtime dependencies. All packages are exposed as separate SPM products from
a single `Package.swift` — consumers import only the products they need.

## Products

| Product | Purpose | Depends On |
|---|---|---|
| **SKCore** | Foundation protocols and utilities (DI, Storage, Logger, Analytics, Clock, Namespace, Extensions) | Nothing |
| **SKDI** | Dependency injection container implementation with scoped lifecycles | SKCore |
| **SKNavigation** | Type-safe SwiftUI Coordinator-based navigation | SKCore |
| **SKStorage** | Image caching and SwiftData persistence implementations | SKCore |
| **SKAnalytics** | Provider-agnostic analytics tracking with composable providers | SKCore |
| **SKInfraTesting** | Public mocks/doubles for every SKCore protocol (test targets only) | SKCore |

## Dependency Direction

```
SKCore (protocols — zero dependencies)
  ↑
  ├── SKDI (DI container implementation)
  ├── SKNavigation (Coordinator, Router, Route)
  ├── SKStorage (ImageCache, SwiftData)
  ├── SKAnalytics (CompositeAnalytics, SuperProperty, PrintAnalytics)
  └── SKInfraTesting (MockClock, MockLogger, MockDependencyContainer, …)
                        ↑
                        link only from test targets
```

All products depend only on SKCore. No cross-dependencies between SKDI,
SKNavigation, SKStorage, SKAnalytics, and SKInfraTesting.

## Consumer Usage

```swift
dependencies: [
    .package(url: "https://github.com/KhachatryanSargis/SKInfra.git", from: "1.0.0")
],
targets: [
    .target(name: "MyFeature", dependencies: [
        .product(name: "SKCore", package: "SKInfra")
    ]),
    .target(name: "MyApp", dependencies: [
        .product(name: "SKCore", package: "SKInfra"),
        .product(name: "SKDI", package: "SKInfra"),
        .product(name: "SKNavigation", package: "SKInfra"),
        .product(name: "SKStorage", package: "SKInfra"),
        .product(name: "SKAnalytics", package: "SKInfra")
    ])
]
```

## Build & Test

```bash
swift build
swift test
```

## Linting

SwiftLint runs automatically via `SwiftLintBuildToolPlugin` on every
`swift build`. Violations appear as warnings in Xcode and the terminal.
CI runs an additional `swiftlint --strict` job as the hard gate.

The plugin is declared as a build-time only dependency on
[SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins);
it does not propagate to consumers' runtime binaries.

## Module Rules

Each module has its own `CLAUDE.md` next to its sources with a short
purpose blurb and a Structure block mapping its folder layout. They
load on-demand when Claude reads files in that directory, keeping
baseline context light.

| Module | Path |
|---|---|
| SKCore | [`Sources/SKCore/CLAUDE.md`](Sources/SKCore/CLAUDE.md) |
| SKDI | [`Sources/SKDI/CLAUDE.md`](Sources/SKDI/CLAUDE.md) |
| SKNavigation | [`Sources/SKNavigation/CLAUDE.md`](Sources/SKNavigation/CLAUDE.md) |
| SKStorage | [`Sources/SKStorage/CLAUDE.md`](Sources/SKStorage/CLAUDE.md) |
| SKAnalytics | [`Sources/SKAnalytics/CLAUDE.md`](Sources/SKAnalytics/CLAUDE.md) |
| SKInfraTesting | [`Sources/SKInfraTesting/CLAUDE.md`](Sources/SKInfraTesting/CLAUDE.md) |

Type signatures, doc-comments, and usage examples live in the source
files — that's the single source of truth. Add module-specific rules
or gotchas to a per-module file only when they're real (cross-cutting
invariants, non-obvious behaviour). Don't create empty sections to
fill later.
