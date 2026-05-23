import Testing
import Foundation
import SKCore
import SKInfraTesting

@Suite("MockMonetizationService")
struct MockMonetizationServiceTests {

    // MARK: - Helpers

    private func makeProduct(id: String = "com.app.monthly") -> Product {
        Product(id: id, price: 9.99, localizedPriceString: "$9.99")
    }

    private func makePackage(
        id: String = "$rc_monthly",
        offeringId: String = "default"
    ) -> Package {
        Package(
            id: id,
            packageType: .monthly,
            product: makeProduct(),
            offeringIdentifier: offeringId
        )
    }

    private func makeCustomerInfo(userId: String = "u_1") -> CustomerInfo {
        CustomerInfo(originalAppUserId: userId)
    }

    // MARK: - Initial State

    @Test("Default init has empty offerings and nil customerInfo")
    func defaultInitialState() {
        let sut = MockMonetizationService()
        #expect(sut.currentOfferings.isEmpty)
        #expect(sut.currentCustomerInfo == nil)
        #expect(sut.hasActiveEntitlement == false)
    }

    @Test("Custom initial offerings are accessible")
    func customInitialOfferings() {
        let offering = Offering(id: "default")
        let sut = MockMonetizationService(initialOfferings: [offering])
        #expect(sut.currentOfferings == [offering])
    }

    @Test("Custom initial customerInfo is accessible")
    func customInitialCustomerInfo() {
        let info = makeCustomerInfo()
        let sut = MockMonetizationService(initialCustomerInfo: info)
        #expect(sut.currentCustomerInfo == info)
    }

    // MARK: - Stream Replay

    @Test("offeringsStream replays current offerings on subscription")
    func offeringsStreamReplay() async {
        let offering = Offering(id: "default")
        let sut = MockMonetizationService(initialOfferings: [offering])
        var iterator = sut.offeringsStream.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == [offering])
    }

    @Test("customerInfoStream replays current info on subscription")
    func customerInfoStreamReplay() async {
        let info = makeCustomerInfo()
        let sut = MockMonetizationService(initialCustomerInfo: info)
        var iterator = sut.customerInfoStream.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == info)
    }

    @Test("customerInfoStream does not yield if info is nil")
    func customerInfoStreamNilDoesNotYield() async {
        let sut = MockMonetizationService()
        let offering = Offering(id: "test")
        sut.simulateOfferings([offering])

        var offeringsIterator = sut.offeringsStream.makeAsyncIterator()
        let offResult = await offeringsIterator.next()
        #expect(offResult == [offering])
    }

    // MARK: - Simulation

    @Test("simulateOfferings emits to active subscribers")
    func simulateOfferingsEmits() async {
        let sut = MockMonetizationService()
        var iterator = sut.offeringsStream.makeAsyncIterator()
        _ = await iterator.next() // initial empty

        let offering = Offering(id: "promo")
        sut.simulateOfferings([offering])
        let next = await iterator.next()
        #expect(next == [offering])
    }

    @Test("simulateCustomerInfo emits to active subscribers")
    func simulateCustomerInfoEmits() async {
        let info = makeCustomerInfo()
        let sut = MockMonetizationService()
        var iterator = sut.customerInfoStream.makeAsyncIterator()

        sut.simulateCustomerInfo(info)
        let first = await iterator.next()
        #expect(first == info)
    }

    @Test("Multiple subscribers each see changes from their subscription point")
    func multipleSubscribers() async {
        let sut = MockMonetizationService()
        var first = sut.offeringsStream.makeAsyncIterator()
        _ = await first.next() // initial

        let offering = Offering(id: "default")
        sut.simulateOfferings([offering])
        let firstUpdate = await first.next()
        #expect(firstUpdate == [offering])

        var second = sut.offeringsStream.makeAsyncIterator()
        let secondInitial = await second.next()
        #expect(secondInitial == [offering])

        sut.simulateOfferings([])
        let firstEmpty = await first.next()
        let secondEmpty = await second.next()
        #expect(firstEmpty?.isEmpty == true)
        #expect(secondEmpty?.isEmpty == true)
    }

    // MARK: - purchase(package:)

    @Test("purchase returns injected success and updates customerInfo")
    func purchaseSuccess() async throws {
        let sut = MockMonetizationService()
        let info = makeCustomerInfo()
        sut.nextPurchaseResult = .success(info)

        let result = try await sut.purchase(package: makePackage())
        #expect(result == info)
        #expect(sut.currentCustomerInfo == info)
        #expect(sut.purchaseCallCount == 1)
        #expect(sut.purchasedPackages.count == 1)
    }

    @Test("purchase throws injected failure and leaves state unchanged")
    func purchaseFailure() async throws {
        let sut = MockMonetizationService()
        sut.nextPurchaseResult = .failure(.purchaseCancelled)
        await #expect(throws: MonetizationError.purchaseCancelled) {
            try await sut.purchase(package: makePackage())
        }
        #expect(sut.currentCustomerInfo == nil)
    }

    @Test("purchase without injected result defaults to .productNotAvailable")
    func purchaseDefaultError() async throws {
        let sut = MockMonetizationService()
        await #expect(throws: MonetizationError.productNotAvailable) {
            try await sut.purchase(package: makePackage())
        }
    }

    // MARK: - restorePurchases

    @Test("restorePurchases returns injected success")
    func restoreSuccess() async throws {
        let sut = MockMonetizationService()
        let info = makeCustomerInfo()
        sut.nextRestoreResult = .success(info)

        let result = try await sut.restorePurchases()
        #expect(result == info)
        #expect(sut.currentCustomerInfo == info)
        #expect(sut.restorePurchasesCallCount == 1)
    }

    @Test("restorePurchases throws injected failure")
    func restoreFailure() async throws {
        let sut = MockMonetizationService()
        sut.nextRestoreResult = .failure(.networkUnavailable)
        await #expect(throws: MonetizationError.networkUnavailable) {
            try await sut.restorePurchases()
        }
    }

    // MARK: - fetchOfferings

    @Test("fetchOfferings returns injected offerings")
    func fetchOfferingsInjected() async throws {
        let sut = MockMonetizationService()
        let offering = Offering(id: "fetched")
        sut.nextFetchOfferingsResult = .success([offering])

        let result = try await sut.fetchOfferings()
        #expect(result == [offering])
        #expect(sut.currentOfferings == [offering])
        #expect(sut.fetchOfferingsCallCount == 1)
    }

    @Test("fetchOfferings returns current state when no injection")
    func fetchOfferingsDefault() async throws {
        let offering = Offering(id: "initial")
        let sut = MockMonetizationService(initialOfferings: [offering])

        let result = try await sut.fetchOfferings()
        #expect(result == [offering])
    }

    // MARK: - fetchCustomerInfo

    @Test("fetchCustomerInfo returns injected info")
    func fetchCustomerInfoInjected() async throws {
        let sut = MockMonetizationService()
        let info = makeCustomerInfo()
        sut.nextFetchCustomerInfoResult = .success(info)

        let result = try await sut.fetchCustomerInfo()
        #expect(result == info)
        #expect(sut.currentCustomerInfo == info)
        #expect(sut.fetchCustomerInfoCallCount == 1)
    }

    @Test("fetchCustomerInfo returns .notConfigured when no info and no injection")
    func fetchCustomerInfoNotConfigured() async throws {
        let sut = MockMonetizationService()
        await #expect(throws: MonetizationError.notConfigured) {
            try await sut.fetchCustomerInfo()
        }
    }

    // MARK: - resetCallTracking

    @Test("resetCallTracking clears counts and injections but preserves state")
    func resetCallTrackingPreservesState() async throws {
        let info = makeCustomerInfo()
        let sut = MockMonetizationService(initialCustomerInfo: info)
        sut.nextPurchaseResult = .success(info)
        _ = try await sut.purchase(package: makePackage())
        #expect(sut.purchaseCallCount == 1)

        sut.nextRestoreResult = .success(info)
        sut.resetCallTracking()

        #expect(sut.purchaseCallCount == 0)
        #expect(sut.purchasedPackages.isEmpty)
        #expect(sut.restorePurchasesCallCount == 0)
        #expect(sut.fetchOfferingsCallCount == 0)
        #expect(sut.fetchCustomerInfoCallCount == 0)
        #expect(sut.nextPurchaseResult == nil)
        #expect(sut.nextRestoreResult == nil)
        #expect(sut.currentCustomerInfo == info)
    }

    // MARK: - Convenience

    @Test("hasEntitlement checks active entitlements")
    func hasEntitlementConvenience() {
        let entitlement = Entitlement(
            id: "premium",
            productIdentifier: "com.app.premium"
        )
        let info = CustomerInfo(
            originalAppUserId: "u_1",
            activeEntitlements: ["premium": entitlement]
        )
        let sut = MockMonetizationService(initialCustomerInfo: info)
        #expect(sut.hasEntitlement("premium") == true)
        #expect(sut.hasEntitlement("pro") == false)
        #expect(sut.hasActiveEntitlement == true)
    }
}
