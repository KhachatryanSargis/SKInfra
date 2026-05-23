import Foundation

@preconcurrency import RevenueCat

import SKCore

// MARK: - Disambiguation

private typealias RCOfferings = RevenueCat.Offerings
private typealias RCOffering = RevenueCat.Offering
private typealias RCPackage = RevenueCat.Package
// RevenueCat.CustomerInfo is spelled out in the PurchasesDelegate
// conformance because that method must be public, and a private
// typealias cannot appear in a public signature.

// MARK: - RevenueCat Adapter

/// `SKCore/MonetizationProtocol` implementation backed by RevenueCat.
///
/// Owns a reference to the configured `Purchases` instance and
/// installs itself as the `PurchasesDelegate` to receive customer
/// info updates.
///
/// ## Lifecycle
///
/// Construct once during composition-root setup, after
/// `Purchases.configure(withAPIKey:appUserID:)`.
///
/// ```swift
/// Purchases.configure(withAPIKey: "rc_api_key")
/// let monetization: any MonetizationProtocol = RevenueCatAdapter()
/// ```
///
/// ## Thread Safety
///
/// All state is guarded by an `NSLock`. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot
/// verify lock-based safety statically.
public final class RevenueCatAdapter: NSObject, MonetizationProtocol, @unchecked Sendable {

    // MARK: - State

    private let purchases: Purchases
    private let lock = NSLock()
    private var offerings: [SKCore.Offering] = []
    private var customerInfo: SKCore.CustomerInfo?
    private var offeringsSubscribers: [UUID: AsyncStream<[SKCore.Offering]>.Continuation] = [:]
    private var customerInfoSubscribers: [UUID: AsyncStream<SKCore.CustomerInfo>.Continuation] = [:]

    // MARK: - Init

    /// Creates an adapter bound to the default `Purchases.shared`.
    override public convenience init() {
        self.init(purchases: Purchases.shared)
    }

    /// Creates an adapter bound to an explicit `Purchases` instance.
    ///
    /// Useful for multi-app setups or when the consumer wants to
    /// point the adapter at a non-default configuration.
    public init(purchases: Purchases) {
        self.purchases = purchases
        super.init()
        self.purchases.delegate = self
        Task { [weak self] in
            await self?.performInitialFetch()
        }
    }

    deinit {
        let offeringsToFinish: [AsyncStream<[SKCore.Offering]>.Continuation] = lock.withLock {
            let all = Array(offeringsSubscribers.values)
            offeringsSubscribers.removeAll()
            return all
        }
        let customerInfoToFinish: [AsyncStream<SKCore.CustomerInfo>.Continuation] = lock.withLock {
            let all = Array(customerInfoSubscribers.values)
            customerInfoSubscribers.removeAll()
            return all
        }
        for continuation in offeringsToFinish { continuation.finish() }
        for continuation in customerInfoToFinish { continuation.finish() }
    }

    // MARK: - MonetizationProtocol

    public var currentOfferings: [SKCore.Offering] {
        lock.withLock { offerings }
    }

    public var offeringsStream: AsyncStream<[SKCore.Offering]> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot: [SKCore.Offering] = lock.withLock {
                offeringsSubscribers[id] = continuation
                return offerings
            }
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeOfferingsSubscriber(id: id)
            }
        }
    }

    public var currentCustomerInfo: SKCore.CustomerInfo? {
        lock.withLock { customerInfo }
    }

    public var customerInfoStream: AsyncStream<SKCore.CustomerInfo> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot: SKCore.CustomerInfo? = lock.withLock {
                customerInfoSubscribers[id] = continuation
                return customerInfo
            }
            if let snapshot {
                continuation.yield(snapshot)
            }
            continuation.onTermination = { [weak self] _ in
                self?.removeCustomerInfoSubscriber(id: id)
            }
        }
    }

    @discardableResult
    public func purchase(package: SKCore.Package) async throws -> SKCore.CustomerInfo {
        do {
            let rcPackage = try findRCPackage(for: package)
            let result = try await purchases.purchase(package: rcPackage)
            let info = SKCore.CustomerInfo(rcCustomerInfo: result.customerInfo)
            transitionCustomerInfo(to: info)
            return info
        } catch let error as MonetizationError {
            throw error
        } catch {
            throw MonetizationError.mapping(error)
        }
    }

    @discardableResult
    public func restorePurchases() async throws -> SKCore.CustomerInfo {
        do {
            let rcInfo = try await purchases.restorePurchases()
            let info = SKCore.CustomerInfo(rcCustomerInfo: rcInfo)
            transitionCustomerInfo(to: info)
            return info
        } catch {
            throw MonetizationError.mapping(error)
        }
    }

    public func fetchOfferings() async throws -> [SKCore.Offering] {
        do {
            let rcOfferings = try await purchases.offerings()
            let mapped = rcOfferings.all.values.map { SKCore.Offering(rcOffering: $0) }
            transitionOfferings(to: mapped)
            return mapped
        } catch {
            throw MonetizationError.mapping(error)
        }
    }

    public func fetchCustomerInfo() async throws -> SKCore.CustomerInfo {
        do {
            let rcInfo = try await purchases.customerInfo()
            let info = SKCore.CustomerInfo(rcCustomerInfo: rcInfo)
            transitionCustomerInfo(to: info)
            return info
        } catch {
            throw MonetizationError.mapping(error)
        }
    }

    // MARK: - Private

    private func performInitialFetch() async {
        do {
            _ = try await fetchOfferings()
            _ = try await fetchCustomerInfo()
        } catch {
            // Initial fetch failures are non-fatal; streams remain
            // empty until the next successful fetch.
        }
    }

    private func findRCPackage(for package: SKCore.Package) throws -> RCPackage {
        guard let rcOfferings = purchases.cachedOfferings,
              let rcOffering = rcOfferings.all[package.offeringIdentifier],
              let rcPackage = rcOffering.package(identifier: package.id) else {
            throw MonetizationError.productNotAvailable
        }
        return rcPackage
    }

    private func transitionOfferings(to newOfferings: [SKCore.Offering]) {
        let listeners: [AsyncStream<[SKCore.Offering]>.Continuation] = lock.withLock {
            offerings = newOfferings
            return Array(offeringsSubscribers.values)
        }
        for listener in listeners {
            listener.yield(newOfferings)
        }
    }

    private func transitionCustomerInfo(to newInfo: SKCore.CustomerInfo) {
        let listeners: [AsyncStream<SKCore.CustomerInfo>.Continuation] = lock.withLock {
            customerInfo = newInfo
            return Array(customerInfoSubscribers.values)
        }
        for listener in listeners {
            listener.yield(newInfo)
        }
    }

    private func removeOfferingsSubscriber(id: UUID) {
        lock.withLock {
            _ = offeringsSubscribers.removeValue(forKey: id)
        }
    }

    private func removeCustomerInfoSubscriber(id: UUID) {
        lock.withLock {
            _ = customerInfoSubscribers.removeValue(forKey: id)
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatAdapter: PurchasesDelegate {
    public func purchases(
        _ purchases: Purchases,
        receivedUpdated customerInfo: RevenueCat.CustomerInfo
    ) {
        let info = SKCore.CustomerInfo(rcCustomerInfo: customerInfo)
        transitionCustomerInfo(to: info)
    }
}
