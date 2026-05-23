import Foundation

// MARK: - Monetization Protocol

/// An abstraction over in-app purchase, subscription management, and
/// entitlement verification.
///
/// `MonetizationProtocol` is the single monetization customization
/// point used by every SKInfra consumer that needs purchase or
/// entitlement checks. Feature code depends on this protocol rather
/// than `RevenueCat.Purchases` directly, so tests can swap in
/// `MockMonetizationService` for fully deterministic behavior.
///
/// ## Scope
///
/// - Offering observation: ``currentOfferings`` for a synchronous
///   snapshot, ``offeringsStream`` for a hot async stream.
/// - Customer observation: ``currentCustomerInfo`` for a synchronous
///   snapshot, ``customerInfoStream`` for reactive updates.
/// - Mutations: ``purchase(package:)``, ``restorePurchases()``.
/// - One-shot fetches: ``fetchOfferings()``, ``fetchCustomerInfo()``.
///
/// ## Conformance
///
/// Implementations are responsible for:
///
/// - Replaying the current offerings and customer info to every new
///   subscriber immediately on subscription.
/// - Translating SDK-specific errors into ``MonetizationError``.
/// - Keeping snapshots and streams in agreement after each mutating
///   call returns.
///
/// ## Usage
///
/// ```swift
/// // Production
/// Purchases.configure(withAPIKey: "rc_api_key")
/// container.register(MonetizationProtocol.self, scope: .singleton) {
///     RevenueCatAdapter()
/// }
///
/// // SwiftUI
/// struct PaywallView: View {
///     @State private var offerings: [Offering] = []
///     let monetization: any MonetizationProtocol
///
///     var body: some View {
///         content(for: offerings)
///             .task {
///                 for await next in monetization.offeringsStream {
///                     offerings = next
///                 }
///             }
///     }
/// }
///
/// // Tests
/// let mock = MockMonetizationService()
/// mock.simulateOfferings([Offering(id: "default")])
/// ```
public protocol MonetizationProtocol: Sendable {

    /// A synchronous snapshot of the current offerings, or empty when
    /// not yet fetched.
    var currentOfferings: [Offering] { get }

    /// A hot stream of available offerings.
    ///
    /// Emits the current offerings immediately on subscription, then
    /// one element per subsequent change.
    var offeringsStream: AsyncStream<[Offering]> { get }

    /// A synchronous snapshot of the current customer info, or `nil`
    /// before the first fetch completes.
    var currentCustomerInfo: CustomerInfo? { get }

    /// A hot stream of customer info changes.
    ///
    /// Emits the current customer info immediately on subscription
    /// (if available), then one element per subsequent change
    /// (purchase, restore, renewal, expiration, etc.).
    var customerInfoStream: AsyncStream<CustomerInfo> { get }

    /// Purchases the given package.
    ///
    /// On success, ``currentCustomerInfo`` is updated and
    /// ``customerInfoStream`` emits the new info before this method
    /// returns.
    ///
    /// - Parameter package: The package to purchase.
    /// - Returns: The updated customer info after the purchase.
    /// - Throws: ``MonetizationError`` describing why the purchase failed.
    @discardableResult
    func purchase(package: Package) async throws -> CustomerInfo

    /// Restores purchases previously made by the current App Store
    /// account.
    ///
    /// On success, ``currentCustomerInfo`` is updated and
    /// ``customerInfoStream`` emits the new info.
    ///
    /// - Returns: The updated customer info after restoration.
    /// - Throws: ``MonetizationError`` describing why the restore failed.
    @discardableResult
    func restorePurchases() async throws -> CustomerInfo

    /// Fetches offerings on demand (one-shot).
    ///
    /// Useful when the caller does not need a continuous stream but
    /// wants the latest offerings once.
    ///
    /// - Returns: The current offerings.
    /// - Throws: ``MonetizationError`` if the fetch fails.
    func fetchOfferings() async throws -> [Offering]

    /// Fetches the current customer info on demand (one-shot).
    ///
    /// - Returns: The current customer info.
    /// - Throws: ``MonetizationError`` if the fetch fails.
    func fetchCustomerInfo() async throws -> CustomerInfo
}

// MARK: - Convenience

public extension MonetizationProtocol {

    /// Whether the customer currently has any active entitlement.
    var hasActiveEntitlement: Bool {
        currentCustomerInfo?.activeEntitlements.isEmpty == false
    }

    /// Returns `true` if the customer has an active entitlement with
    /// the given identifier.
    func hasEntitlement(_ identifier: String) -> Bool {
        currentCustomerInfo?.activeEntitlements[identifier] != nil
    }
}
