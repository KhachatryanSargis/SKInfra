import Testing
import Foundation
@testable import SKCore

@Suite("Package")
struct PackageTests {

    @Test("Codable round-trip preserves every field")
    func codableRoundTrip() throws {
        let original = Package(
            id: "$rc_monthly",
            packageType: .monthly,
            product: Product(id: "com.app.monthly", price: 9.99),
            offeringIdentifier: "default"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Package.self, from: data)
        #expect(decoded == original)
    }

    @Test("PackageType equality including custom")
    func packageTypeEquality() {
        #expect(PackageType.monthly == .monthly)
        #expect(PackageType.custom("promo") == .custom("promo"))
        #expect(PackageType.custom("a") != .custom("b"))
        #expect(PackageType.monthly != .annual)
    }

    @Test("PackageType Codable round-trip for all cases")
    func packageTypeCodable() throws {
        let cases: [PackageType] = [
            .monthly, .annual, .weekly, .twoMonth,
            .threeMonth, .sixMonth, .lifetime,
            .custom("promo"), .unknown
        ]
        for type in cases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(PackageType.self, from: data)
            #expect(decoded == type)
        }
    }
}
