# SKAnalytics — Module Rules

Provider-agnostic analytics implementations for SKCore's `AnalyticsProtocol`.
Vendor SDK wrappers (Mixpanel, Amplitude, Firebase, …) live in the consumer
app — this module provides composition and decoration primitives only.

## Structure

```
SKAnalytics/
├── PrintAnalyticsProvider.swift     — Debug console output (mirrors PrintLogger)
├── CompositeAnalyticsProvider.swift — N-way fan-out (mirrors CompositeLogger)
└── SuperPropertyProvider.swift      — Decorator that attaches persistent props
                                       to every track/screen event
```

## Gotchas

- `SuperPropertyProvider`: event-specific properties override super
  properties when keys collide. `register(...)` adds super-props; it
  does **not** lock keys against per-call overrides.
