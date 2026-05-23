import Testing
import Foundation
@testable import SKCore

@Suite("Entitlement")
struct EntitlementTests {

    @Test("Default init with required fields")
    func defaultInit() {
        let ent = Entitlement(id: "premium", productIdentifier: "com.app.premium")
        #expect(ent.id == "premium")
        #expect(ent.isActive == true)
        #expect(ent.productIdentifier == "com.app.premium")
        #expect(ent.willRenew == true)
        #expect(ent.store == .appStore)
        #expect(ent.isBillingRetryPeriod == false)
        #expect(ent.periodType == .normal)
    }

    @Test("Codable round-trip preserves every field")
    func codableRoundTrip() throws {
        let original = Entitlement(
            id: "premium",
            isActive: true,
            productIdentifier: "com.app.premium.annual",
            originalPurchaseDate: Date(timeIntervalSince1970: 1_700_000_000),
            expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
            willRenew: false,
            store: .stripe,
            isBillingRetryPeriod: true,
            periodType: .trial
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Entitlement.self, from: data)
        #expect(decoded == original)
    }

    @Test("Store raw values")
    func storeRawValues() {
        #expect(Entitlement.Store.appStore.rawValue == "appStore")
        #expect(Entitlement.Store.macAppStore.rawValue == "macAppStore")
        #expect(Entitlement.Store.playStore.rawValue == "playStore")
        #expect(Entitlement.Store.stripe.rawValue == "stripe")
        #expect(Entitlement.Store.promotional.rawValue == "promotional")
        #expect(Entitlement.Store.unknown.rawValue == "unknown")
    }

    @Test("PeriodType raw values")
    func periodTypeRawValues() {
        #expect(Entitlement.PeriodType.normal.rawValue == "normal")
        #expect(Entitlement.PeriodType.intro.rawValue == "intro")
        #expect(Entitlement.PeriodType.trial.rawValue == "trial")
    }
}
