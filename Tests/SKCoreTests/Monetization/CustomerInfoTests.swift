import Testing
import Foundation
@testable import SKCore

@Suite("CustomerInfo")
struct CustomerInfoTests {

    @Test("Default init only requires originalAppUserId")
    func minimalInit() {
        let info = CustomerInfo(originalAppUserId: "u_1")
        #expect(info.originalAppUserId == "u_1")
        #expect(info.activeEntitlements.isEmpty)
        #expect(info.allPurchasedProductIdentifiers.isEmpty)
        #expect(info.latestExpirationDate == nil)
        #expect(info.managementURL == nil)
    }

    @Test("Codable round-trip preserves every field")
    func codableRoundTrip() throws {
        let entitlement = Entitlement(
            id: "premium",
            isActive: true,
            productIdentifier: "com.app.premium.monthly",
            expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
            willRenew: true,
            store: .appStore
        )
        let original = CustomerInfo(
            originalAppUserId: "u_42",
            firstSeen: Date(timeIntervalSince1970: 1_700_000_000),
            activeEntitlements: ["premium": entitlement],
            allPurchasedProductIdentifiers: ["com.app.premium.monthly"],
            latestExpirationDate: Date(timeIntervalSince1970: 1_800_000_000),
            managementURL: URL(string: "https://apps.apple.com/account/subscriptions")
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomerInfo.self, from: data)
        #expect(decoded == original)
    }

    @Test("Hashable equality is value-based")
    func hashableEquality() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = CustomerInfo(originalAppUserId: "u_1", firstSeen: date)
        let b = CustomerInfo(originalAppUserId: "u_1", firstSeen: date)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}
