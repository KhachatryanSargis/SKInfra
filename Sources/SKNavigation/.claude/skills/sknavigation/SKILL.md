---
name: sknavigation
description: SKNavigation Coordinator-based SwiftUI navigation — Coordinator, FlowCoordinator, NavigationRouter, TabRouter, Route, PresentationStyle, CoordinatedView, TabCoordinatedView, CrossModuleNavigation, DeepLinkable. Use when building navigation, coordinators, routing, or deep links.
---

# SKNavigation — Consumer Reference

> **Scope:** Coordinator pattern, NavigationRouter, TabRouter, Route protocol, presentation styles, cross-module navigation, deep links
> **Layer:** SKNavigation depends on SKCore. Used in the Presentation layer for navigation orchestration.

## Coordinator Pattern

Coordinators are `@Observable @MainActor` objects that own a router and drive all navigation. Views are stateless with respect to navigation — they call back to the coordinator.

### Basic Coordinator

```swift
@Observable @MainActor
final class CatalogCoordinator: Coordinator {
    typealias RouteType = CatalogRoute
    let router = NavigationRouter<CatalogRoute>()

    @ViewBuilder
    func rootView() -> some View {
        CatalogListView(coordinator: self)
    }

    @ViewBuilder
    func destination(for route: CatalogRoute) -> some View {
        switch route {
        case .detail(let id):
            CatalogDetailView(id: id, coordinator: self)
        case .filter:
            FilterView(coordinator: self)
        }
    }
}
```

### FlowCoordinator (child flows with results)

```swift
@Observable @MainActor
final class CheckoutCoordinator: FlowCoordinator {
    typealias RouteType = CheckoutRoute
    typealias Output = OrderConfirmation

    let router = NavigationRouter<CheckoutRoute>()
    let resultHandler = CoordinatorResultHandler<OrderConfirmation>()

    func complete(with order: OrderConfirmation) {
        resultHandler.finish(with: order)
    }
}

// Parent starts the flow and awaits the result
let result = await checkoutCoordinator.resultHandler.awaitResult()
switch result {
case .finished(let order): handleOrder(order)
case .cancelled: dismissCheckout()
}
```

## Route Protocol

Define destinations as a `Hashable`, `Sendable` enum:

```swift
enum CatalogRoute: Route {
    case detail(id: UUID)
    case filter

    // Optional — hides the tab bar when this route is on top
    var hidesTabBar: Bool {
        switch self {
        case .detail: true
        case .filter: false
        }
    }
}
```

## NavigationRouter

State container for a single navigation stack. The coordinator owns it, views read from it.

```swift
let router = NavigationRouter<CatalogRoute>()

// Push / Pop
router.push(.detail(id: itemID))
router.pop()
router.popToRoot()
router.popTo(.filter)

// Present modally
router.present(.filter, as: .sheet())
router.present(.detail(id: itemID), as: .fullScreenCover)
router.dismiss()

// Sheet configuration
router.present(.filter, as: .sheet(
    detents: [.medium, .large],
    dragIndicatorVisibility: .visible,
    isDismissDisabled: true
))

// State queries
router.isAtRoot          // Bool
router.stackDepth        // Int
router.isPresenting      // Bool (sheet or fullScreenCover active)
router.topRoute          // R? (current top of stack)
router.shouldHideTabBar  // Bool (driven by Route.hidesTabBar)
```

## TabRouter

Manages tab selection with re-tap-to-root detection:

```swift
protocol Tab: Hashable, Identifiable, CaseIterable, Sendable {
    var title: String { get }
    var icon: String { get }
}

enum AppTab: Tab {
    case home, search, profile
    var title: String { ... }
    var icon: String { ... }
}

let tabRouter = TabRouter<AppTab>(initialTab: .home)
tabRouter.select(.search)
tabRouter.selectedTab     // .search
tabRouter.previousTab     // .home
tabRouter.didRetap        // true if same tab tapped again
tabRouter.consumeRetap()  // reset the retap flag
```

### TabCoordinator

```swift
@Observable @MainActor
final class AppCoordinator: TabCoordinator {
    typealias TabType = AppTab
    let tabRouter = TabRouter<AppTab>(initialTab: .home)

    @ViewBuilder
    func coordinatorView(for tab: AppTab) -> some View {
        switch tab {
        case .home: CoordinatedView(coordinator: homeCoordinator)
        case .search: CoordinatedView(coordinator: searchCoordinator)
        case .profile: CoordinatedView(coordinator: profileCoordinator)
        }
    }
}
```

## SwiftUI Wiring

```swift
// Single-stack navigation
CoordinatedView(coordinator: catalogCoordinator)

// Tab-based navigation
TabCoordinatedView(coordinator: appCoordinator)
```

## Presentation Styles

```swift
.sheet()                          // default sheet
.sheet(detents: [.medium])        // half-sheet
.sheet(isDismissDisabled: true)   // non-dismissable
.fullScreenCover                  // full screen modal
.push                             // navigation stack push (default)
```

## Cross-Module Navigation

Navigate between feature modules without direct imports:

```swift
let destination = CrossModuleDestination(
    targetModule: .profile,
    identifier: "user-detail",
    parameters: ["userId": userID.uuidString],
    preferredStrategy: .push
)
crossModuleHandler?.navigate(to: destination)
```

The app coordinator implements `CrossModuleNavigationHandler` to resolve targets.

## Deep Links

```swift
protocol DeepLinkable: AnyObject {
    func handle(deepLink: any DeepLink) -> Bool
}
```

Coordinators conform to `DeepLinkable`. The app coordinator routes deep links down the coordinator tree.

## Rules

- **MUST** use `@Observable @MainActor` on all coordinators
- **MUST** define routes as enums conforming to `Route`
- **MUST NOT** perform navigation from Views — always call back to the coordinator
- **MUST NOT** use `NavigationLink` or `NavigationDestination` directly — use `NavigationRouter`
- **MUST** use `CoordinatedView` / `TabCoordinatedView` to wire coordinators to SwiftUI
