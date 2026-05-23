# SKStorage — Module Rules

Image caching and SwiftData persistence implementations for SKCore
storage protocols.

## Structure

```
SKStorage/
├── ImageCache/
│   ├── InMemoryImageCache.swift     — Actor wrapping NSCache
│   ├── DiskImageCache.swift         — Actor wrapping the file system
│   └── ImageCacheCoordinator.swift  — Two-tier (memory + disk) coordinator
└── SwiftData/
    └── SwiftDataRepository.swift    — Generic CRUD over a SwiftData ModelContext
```

## Gotchas

- `SwiftDataRepository` is `@unchecked Sendable` because `ModelContext`
  is not Sendable. Do **NOT** add `Sendable` conformance to SwiftData
  `@Model` types — SwiftData expects them to be non-Sendable model
  objects and will fight you under strict concurrency.
- ImageCache types are actors. Refactoring any of them to a class
  requires rethinking the concurrency boundary in
  `ImageCacheCoordinator` — don't do it incidentally.
