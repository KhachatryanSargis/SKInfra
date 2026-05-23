/// SKMonetization — RevenueCat-backed implementation of
/// ``SKCore/MonetizationProtocol``.
///
/// Wraps `RevenueCat.Purchases` and exposes a single concrete type,
/// ``RevenueCatAdapter``, that conforms to the protocol-neutral
/// ``SKCore/MonetizationProtocol`` surface.
///
/// ## Composition
///
/// Consumers call `Purchases.configure(withAPIKey:)` in the
/// composition root, register `RevenueCatAdapter` in the DI
/// container, and depend on ``SKCore/MonetizationProtocol``
/// everywhere else. Feature code never imports `RevenueCat`
/// directly.
///
/// ```swift
/// Purchases.configure(withAPIKey: "rc_api_key")
/// container.register(MonetizationProtocol.self, scope: .singleton) {
///     RevenueCatAdapter()
/// }
/// ```
