# SKCore — Module Rules

Foundation protocols and utilities. **Zero external dependencies** —
every other SKInfra product depends only on SKCore, and feature modules
in consumer apps should depend on SKCore alone (not on the concrete
impl modules).

## Structure

Each concern lives in its own folder under `Sources/SKCore/`:

```
SKCore/
├── Analytics/   — AnalyticsProtocol, AnalyticsEvent, AnalyticsProperties, AnalyticsValue
├── Clock/       — ClockProtocol, ScheduledHandle, SystemClock
├── DI/          — DependencyContainerProtocol, DependencyScope, DependencyResolutionError
├── Extensions/  — Collection+SK, Optional+SK, String+SK (all behind `.sk` namespace)
├── Logger/      — LoggerProtocol, LogLevel, LogEntry, PrintLogger, OSLogLogger, CompositeLogger
├── Namespace/   — SKWrapper, SKNamespaceProvider (the `.sk` machinery)
└── Storage/     — StorageProtocol, StorageKey, UserDefaultsStorage, KeychainStorage,
                   ImageCacheProtocol, PersistentRepositoryProtocol
```

## Gotchas

- Extensions live behind the `.sk` namespace via `SKNamespaceProvider`.
  Don't extend stdlib or domain types directly.
- Concrete impls *without* SDK wrappers live beside their protocol
  (`PrintLogger`, `OSLogLogger`, `UserDefaultsStorage`, `KeychainStorage`,
  `SystemClock`). Impls that wrap a third-party SDK go in their own
  impl module instead — never in SKCore.
