import Testing
import Foundation
@testable import SKCore

@Suite("Product")
struct ProductTests {

    @Test("Default init only requires an id")
    func minimalInit() {
        let product = Product(id: "com.app.monthly")
        #expect(product.id == "com.app.monthly")
        #expect(product.localizedTitle.isEmpty)
        #expect(product.price == 0)
        #expect(product.currencyCode == nil)
        #expect(product.subscriptionPeriod == nil)
        #expect(product.introductoryDiscount == nil)
    }

    @Test("Codable round-trip preserves every field including nested types")
    func codableRoundTrip() throws {
        let original = Product(
            id: "com.app.premium.monthly",
            localizedTitle: "Premium Monthly",
            localizedDescription: "Full access",
            price: 9.99,
            localizedPriceString: "$9.99",
            currencyCode: "USD",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
            introductoryDiscount: ProductDiscount(
                price: 0,
                localizedPriceString: "Free",
                paymentMode: .freeTrial,
                period: SubscriptionPeriod(unit: .week, value: 1),
                numberOfPeriods: 1
            )
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Product.self, from: data)
        #expect(decoded == original)
    }

    @Test("SubscriptionPeriod.Unit raw values")
    func subscriptionPeriodUnitRawValues() {
        #expect(SubscriptionPeriod.Unit.day.rawValue == "day")
        #expect(SubscriptionPeriod.Unit.week.rawValue == "week")
        #expect(SubscriptionPeriod.Unit.month.rawValue == "month")
        #expect(SubscriptionPeriod.Unit.year.rawValue == "year")
    }

    @Test("ProductDiscount.PaymentMode raw values")
    func paymentModeRawValues() {
        #expect(ProductDiscount.PaymentMode.freeTrial.rawValue == "freeTrial")
        #expect(ProductDiscount.PaymentMode.payUpFront.rawValue == "payUpFront")
        #expect(ProductDiscount.PaymentMode.payAsYouGo.rawValue == "payAsYouGo")
    }
}
