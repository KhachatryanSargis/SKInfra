# SKInfraTesting — Module Rules

Public mocks and test doubles for every SKCore protocol. **Link only
from test targets.** This module is intentionally not part of the
production graph.

## Structure

```
SKInfraTesting/
├── SKInfraTesting.swift          — Module docstring (no code)
├── MockAuth.swift                — Explicit-state Auth with simulate… controls
├── MockClock.swift               — Virtual-time ClockProtocol
├── MockLogger.swift              — Recording LoggerProtocol
├── MockDependencyContainer.swift — Stub-based DependencyContainerProtocol
├── MockAnalyticsProvider.swift   — Recording AnalyticsProtocol
├── MockMonetizationService.swift — Explicit-state MonetizationProtocol with simulate… controls
└── MockKeychainOperations.swift  — In-memory KeychainOperations
```

## Gotchas

- One mock per SKCore protocol. When a new protocol lands in SKCore,
  the matching mock lands here in the same slice.
- Mocks use plain `import SKCore`, not `@testable import SKCore`.
  Every SKCore protocol they conform to is already part of the public
  surface, so there's no need for `@testable` and adding it would
  block the module from being a public library.
- `MockClock.sleep(for:)` and `schedule(after:_:)` install their
  continuations synchronously then suspend. If a test races a sleep
  against `advance(by:)`, call `await Task.yield()` before the advance
  so the work-under-test enters its sleep first.
