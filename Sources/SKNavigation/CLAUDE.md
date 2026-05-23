# SKNavigation — Module Rules

Type-safe SwiftUI navigation built on the Coordinator pattern.
Coordinators own routers; views are stateless with respect to
navigation and receive their coordinator via constructor injection.

## Structure

```
SKNavigation/
├── Coordinator/  — Coordinator, FlowCoordinator, TabCoordinator,
│                   CoordinatorResult, CoordinatorResultHandler
├── CrossModule/  — CrossModuleNavigation primitives for cross-feature jumps
├── DeepLink/     — DeepLinkable, DeepLink
├── Route/        — Route, PresentationStyle, SheetConfiguration
├── Router/       — NavigationRouter, TabRouter, NavigationAction
└── View/         — CoordinatedView, TabCoordinatedView
```

## Gotchas

- Coordinators are `@Observable @MainActor` reference types and own
  their router. Views are stateless w.r.t. navigation — they receive
  the coordinator by construction and never mutate the router directly.
- Cross-module navigation goes through `CrossModuleNavigationHandler` —
  don't import another feature's coordinator directly.
