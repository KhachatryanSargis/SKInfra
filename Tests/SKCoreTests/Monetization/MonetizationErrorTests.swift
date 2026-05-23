import Testing
import Foundation
@testable import SKCore

@Suite("MonetizationError")
struct MonetizationErrorTests {

    @Test("Same cases are equal")
    func sameCaseEquality() {
        #expect(MonetizationError.purchaseCancelled == .purchaseCancelled)
        #expect(MonetizationError.paymentPending == .paymentPending)
        #expect(MonetizationError.productNotAvailable == .productNotAvailable)
        #expect(MonetizationError.purchaseNotAllowed == .purchaseNotAllowed)
        #expect(MonetizationError.receiptVerificationFailed == .receiptVerificationFailed)
        #expect(MonetizationError.alreadyPurchased == .alreadyPurchased)
        #expect(MonetizationError.storeUnavailable == .storeUnavailable)
        #expect(MonetizationError.networkUnavailable == .networkUnavailable)
        #expect(MonetizationError.notConfigured == .notConfigured)
    }

    @Test("Different cases are not equal")
    func crossCaseInequality() {
        #expect(MonetizationError.purchaseCancelled != .paymentPending)
        #expect(MonetizationError.networkUnavailable != .storeUnavailable)
        #expect(MonetizationError.notConfigured != .purchaseNotAllowed)
    }

    @Test("underlying equality uses localizedDescription")
    func underlyingEquality() {
        struct TestError: Error, Sendable, LocalizedError {
            let msg: String
            var errorDescription: String? { msg }
        }
        let a = MonetizationError.underlying(TestError(msg: "boom"))
        let b = MonetizationError.underlying(TestError(msg: "boom"))
        let c = MonetizationError.underlying(TestError(msg: "other"))
        #expect(a == b)
        #expect(a != c)
    }
}
