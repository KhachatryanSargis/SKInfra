import Foundation
import SKCore

// MARK: - Mock Monetization Service

/// In-memory ``MonetizationProtocol`` test double with explicit state
/// control.
///
/// Follows the same patterns as ``MockAuth``:
/// - Direct simulation for arranging preconditions.
/// - Result injection consumed on the next matching call.
/// - Call tracking for assertion.
///
/// ```swift
/// let monetization = MockMonetizationService()
/// let info = CustomerInfo(originalAppUserId: "u_1")
/// monetization.nextPurchaseResult = .success(info)
///
/// try await viewModel.purchasePremium()
/// #expect(monetization.purchaseCallCount == 1)
/// ```
///
/// ## Thread Safety
///
/// All state is guarded by an `NSLock`. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot
/// verify lock-based safety statically.
public final class MockMonetizationService: MonetizationProtocol, @unchecked Sendable {

    // MARK: - State

    private let lock = NSLock()
    private var offerings: [Offering]
    private var info: CustomerInfo?
    private var offeringsSubscribers: [UUID: AsyncStream<[Offering]>.Continuation] = [:]
    private var customerInfoSubscribers: [UUID: AsyncStream<CustomerInfo>.Continuation] = [:]

    // MARK: - Call Tracking

    /// Number of ``purchase(package:)`` calls observed.
    public private(set) var purchaseCallCount = 0

    /// The packages passed to ``purchase(package:)``, in call order.
    public private(set) var purchasedPackages: [Package] = []

    /// Number of ``restorePurchases()`` calls observed.
    public private(set) var restorePurchasesCallCount = 0

    /// Number of ``fetchOfferings()`` calls observed.
    public private(set) var fetchOfferingsCallCount = 0

    /// Number of ``fetchCustomerInfo()`` calls observed.
    public private(set) var fetchCustomerInfoCallCount = 0

    // MARK: - Result Injection

    /// When set, the next ``purchase(package:)`` call consumes this.
    public var nextPurchaseResult: Result<CustomerInfo, MonetizationError>?

    /// When set, the next ``restorePurchases()`` call consumes this.
    public var nextRestoreResult: Result<CustomerInfo, MonetizationError>?

    /// When set, the next ``fetchOfferings()`` call consumes this.
    public var nextFetchOfferingsResult: Result<[Offering], MonetizationError>?

    /// When set, the next ``fetchCustomerInfo()`` call consumes this.
    public var nextFetchCustomerInfoResult: Result<CustomerInfo, MonetizationError>?

    // MARK: - Init

    /// Creates a mock with optional initial state.
    public init(
        initialOfferings: [Offering] = [],
        initialCustomerInfo: CustomerInfo? = nil
    ) {
        self.offerings = initialOfferings
        self.info = initialCustomerInfo
    }

    // MARK: - MonetizationProtocol

    public var currentOfferings: [Offering] {
        lock.withLock { offerings }
    }

    public var offeringsStream: AsyncStream<[Offering]> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot: [Offering] = lock.withLock {
                offeringsSubscribers[id] = continuation
                return offerings
            }
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeOfferingsSubscriber(id: id)
            }
        }
    }

    public var currentCustomerInfo: CustomerInfo? {
        lock.withLock { info }
    }

    public var customerInfoStream: AsyncStream<CustomerInfo> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot: CustomerInfo? = lock.withLock {
                customerInfoSubscribers[id] = continuation
                return info
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
    public func purchase(package: Package) async throws -> CustomerInfo {
        let result: Result<CustomerInfo, MonetizationError> = lock.withLock {
            purchaseCallCount += 1
            purchasedPackages.append(package)
            let pending = nextPurchaseResult ?? .failure(.productNotAvailable)
            nextPurchaseResult = nil
            return pending
        }
        switch result {
        case .success(let customerInfo):
            transitionCustomerInfo(to: customerInfo)
            return customerInfo
        case .failure(let error):
            throw error
        }
    }

    @discardableResult
    public func restorePurchases() async throws -> CustomerInfo {
        let result: Result<CustomerInfo, MonetizationError> = lock.withLock {
            restorePurchasesCallCount += 1
            let pending = nextRestoreResult ?? .failure(.storeUnavailable)
            nextRestoreResult = nil
            return pending
        }
        switch result {
        case .success(let customerInfo):
            transitionCustomerInfo(to: customerInfo)
            return customerInfo
        case .failure(let error):
            throw error
        }
    }

    public func fetchOfferings() async throws -> [Offering] {
        let result: Result<[Offering], MonetizationError> = lock.withLock {
            fetchOfferingsCallCount += 1
            let pending = nextFetchOfferingsResult ?? .success(offerings)
            nextFetchOfferingsResult = nil
            return pending
        }
        switch result {
        case .success(let fetched):
            transitionOfferings(to: fetched)
            return fetched
        case .failure(let error):
            throw error
        }
    }

    public func fetchCustomerInfo() async throws -> CustomerInfo {
        let result: Result<CustomerInfo, MonetizationError> = lock.withLock {
            fetchCustomerInfoCallCount += 1
            if let pending = nextFetchCustomerInfoResult {
                nextFetchCustomerInfoResult = nil
                return pending
            }
            if let info {
                return .success(info)
            }
            return .failure(.notConfigured)
        }
        switch result {
        case .success(let customerInfo):
            transitionCustomerInfo(to: customerInfo)
            return customerInfo
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Simulation API

    /// Sets offerings and emits to all active subscribers.
    ///
    /// Bypasses ``fetchOfferings()`` — does not increment
    /// ``fetchOfferingsCallCount``.
    public func simulateOfferings(_ newOfferings: [Offering]) {
        transitionOfferings(to: newOfferings)
    }

    /// Sets customer info and emits to all active subscribers.
    ///
    /// Bypasses ``purchase(package:)`` / ``restorePurchases()`` — does
    /// not increment any call counts.
    public func simulateCustomerInfo(_ newInfo: CustomerInfo) {
        transitionCustomerInfo(to: newInfo)
    }

    /// Resets all call counts, injected results, and argument logs.
    /// State and subscribers are preserved.
    public func resetCallTracking() {
        lock.withLock {
            purchaseCallCount = 0
            purchasedPackages.removeAll()
            restorePurchasesCallCount = 0
            fetchOfferingsCallCount = 0
            fetchCustomerInfoCallCount = 0
            nextPurchaseResult = nil
            nextRestoreResult = nil
            nextFetchOfferingsResult = nil
            nextFetchCustomerInfoResult = nil
        }
    }

    // MARK: - Private

    private func transitionOfferings(to newOfferings: [Offering]) {
        let listeners: [AsyncStream<[Offering]>.Continuation] = lock.withLock {
            offerings = newOfferings
            return Array(offeringsSubscribers.values)
        }
        for listener in listeners {
            listener.yield(newOfferings)
        }
    }

    private func transitionCustomerInfo(to newInfo: CustomerInfo) {
        let listeners: [AsyncStream<CustomerInfo>.Continuation] = lock.withLock {
            info = newInfo
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
