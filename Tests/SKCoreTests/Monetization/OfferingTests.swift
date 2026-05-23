import Testing
import Foundation
@testable import SKCore

@Suite("Offering")
struct OfferingTests {

    @Test("Default init only requires an id")
    func minimalInit() {
        let offering = Offering(id: "default")
        #expect(offering.id == "default")
        #expect(offering.serverDescription.isEmpty)
        #expect(offering.packages.isEmpty)
        #expect(offering.metadata.isEmpty)
    }

    @Test("Hashable equality is value-based")
    func hashableEquality() {
        let a = Offering(id: "default", serverDescription: "Premium")
        let b = Offering(id: "default", serverDescription: "Premium")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Codable round-trip preserves every field")
    func codableRoundTrip() throws {
        let product = Product(id: "com.app.monthly", price: 9.99)
        let pkg = Package(
            id: "$rc_monthly",
            packageType: .monthly,
            product: product,
            offeringIdentifier: "default"
        )
        let original = Offering(
            id: "default",
            serverDescription: "Premium",
            packages: [pkg],
            metadata: ["key": "value"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Offering.self, from: data)
        #expect(decoded == original)
    }

    @Test("package(ofType:) returns matching package")
    func packageOfTypeFound() {
        let monthly = Package(
            id: "$rc_monthly",
            packageType: .monthly,
            product: Product(id: "com.app.monthly"),
            offeringIdentifier: "default"
        )
        let annual = Package(
            id: "$rc_annual",
            packageType: .annual,
            product: Product(id: "com.app.annual"),
            offeringIdentifier: "default"
        )
        let offering = Offering(id: "default", packages: [monthly, annual])
        #expect(offering.package(ofType: .monthly) == monthly)
        #expect(offering.package(ofType: .annual) == annual)
        #expect(offering.package(ofType: .lifetime) == nil)
    }
}
