# SKMonetization — Module Rules

RevenueCat-backed implementation of `SKCore.MonetizationProtocol`. Wraps the
`Purchases` lifecycle and the `PurchasesDelegate` callbacks behind the
protocol-neutral surface so feature code never imports `RevenueCat` directly.
Sign-in providers handled today: in-app purchases through `Purchases.shared`
(StoreKit) with offerings, packages, and entitlements driven by the RevenueCat
dashboard.

The consumer is responsible for calling `Purchases.configure(withAPIKey:)`
once in the composition root before constructing `RevenueCatAdapter` —
the adapter assumes the default `Purchases` instance is already set up;
use the `init(purchases:)` overload for non-default configurations.

## Structure

```
SKMonetization/
├── SKMonetization.swift                — Module docstring (no code)
├── RevenueCatAdapter.swift             — MonetizationProtocol conformance + PurchasesDelegate
├── Offering+RevenueCat.swift           — RevenueCat.Offering → SKCore.Offering projection
├── Package+RevenueCat.swift            — RevenueCat.Package / PackageType → SKCore projection
├── Product+RevenueCat.swift            — RevenueCat.StoreProduct / SubscriptionPeriod / StoreProductDiscount projections
├── CustomerInfo+RevenueCat.swift       — RevenueCat.CustomerInfo / EntitlementInfo / Store / PeriodType projections
└── MonetizationError+RevenueCat.swift  — RevenueCat.ErrorCode → MonetizationError mapping (+ Sendable error wrapper)
```

## Gotchas

- `Purchases.configure(withAPIKey:)` must run **before** any
  `RevenueCatAdapter` is constructed. The adapter installs itself as the
  `PurchasesDelegate` in `init`, so a misconfigured `Purchases` instance
  surfaces as `.notConfigured` errors on the first mutation.
- Both SKCore and RevenueCat export types named `Package`, `PackageType`,
  `SubscriptionPeriod`, `ProductDiscount`, and `CustomerInfo`. Every
  reference in this module qualifies the SKCore type with `SKCore.` and
  uses private typealiases (`RCOffering`, `RCPackage`, etc.) for the
  RevenueCat counterparts so the compiler can resolve them.
- `RevenueCat.CustomerInfo` is spelled out in the `PurchasesDelegate`
  conformance because `purchases(_:receivedUpdated:)` must be public,
  and a private typealias cannot appear in a public signature.
- The adapter calls `transition(to:)` explicitly in `purchase`,
  `restorePurchases`, `fetchOfferings`, and `fetchCustomerInfo` before
  returning. `PurchasesDelegate.purchases(_:receivedUpdated:)` will also
  fire asynchronously — `transition` is idempotent on equal state, so
  the double-update is harmless but the explicit call guarantees
  `currentCustomerInfo` agrees with the returned value by the time the
  method returns.
- `findRCPackage(for:)` looks up the RevenueCat package through
  `purchases.cachedOfferings`. If no fetch has completed yet, the lookup
  fails with `.productNotAvailable` rather than triggering a network
  call — callers should observe `offeringsStream` until non-empty before
  attempting a purchase, or call `fetchOfferings()` explicitly.
- RevenueCat's `Store` and `PeriodType` enums carry vendor-specific
  cases that don't fit the domain model (`.amazon`, `.rcBilling`,
  `.external`, `.paddle`, `.testStore`, `.galaxy`, `.prepaid`). The
  projection maps all unsupported `Store` cases to `.unknown` and
  `.prepaid` to `.normal` so the SKCore enum surface stays stable.
- Paywall experiment variants surface through `Offering.metadata` under
  the `rc_experiment_id` / `rc_experiment_variant` keys. The
  `Offering.experiment` computed property in SKCore parses these — the
  adapter does no extra work to expose them.
