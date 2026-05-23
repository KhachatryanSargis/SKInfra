import Foundation

// MARK: - Product

/// A store product available for purchase.
///
/// Provider-neutral representation of an App Store product. Carries
/// the fields needed for paywall display and the purchase flow
/// without importing StoreKit or any vendor SDK.
public struct Product: Sendable, Hashable, Codable, Identifiable {

    /// The App Store product identifier (e.g., `"com.app.premium.monthly"`).
    public let id: String

    /// The localized display name of the product.
    public let localizedTitle: String

    /// The localized description of the product.
    public let localizedDescription: String

    /// The price as a decimal number.
    public let price: Decimal

    /// The localized price string including currency symbol
    /// (e.g., `"$9.99"`, `"€8,99"`).
    public let localizedPriceString: String

    /// The ISO 4217 currency code (e.g., `"USD"`, `"EUR"`).
    public let currencyCode: String?

    /// The subscription period, if this is a subscription product.
    public let subscriptionPeriod: SubscriptionPeriod?

    /// The introductory offer, if available.
    public let introductoryDiscount: ProductDiscount?

    /// Creates a `Product`.
    ///
    /// All fields except `id` are optional or defaulted because not
    /// every context requires a fully populated product.
    public init(
        id: String,
        localizedTitle: String = "",
        localizedDescription: String = "",
        price: Decimal = 0,
        localizedPriceString: String = "",
        currencyCode: String? = nil,
        subscriptionPeriod: SubscriptionPeriod? = nil,
        introductoryDiscount: ProductDiscount? = nil
    ) {
        self.id = id
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.price = price
        self.localizedPriceString = localizedPriceString
        self.currencyCode = currencyCode
        self.subscriptionPeriod = subscriptionPeriod
        self.introductoryDiscount = introductoryDiscount
    }
}

// MARK: - Subscription Period

/// The duration of a subscription billing cycle.
public struct SubscriptionPeriod: Sendable, Hashable, Codable {

    /// The unit of time for the period.
    public let unit: Unit

    /// The number of units per period.
    public let value: Int

    public init(unit: Unit, value: Int) {
        self.unit = unit
        self.value = value
    }

    /// Time unit for subscription periods.
    public enum Unit: String, Sendable, Hashable, Codable {
        case day
        case week
        case month
        case year
    }
}

// MARK: - Product Discount

/// An introductory or promotional discount on a product.
public struct ProductDiscount: Sendable, Hashable, Codable {

    /// The discounted price.
    public let price: Decimal

    /// The localized price string.
    public let localizedPriceString: String

    /// The payment mode of the discount.
    public let paymentMode: PaymentMode

    /// The period of the discount.
    public let period: SubscriptionPeriod

    /// The number of periods the discount applies.
    public let numberOfPeriods: Int

    public init(
        price: Decimal,
        localizedPriceString: String = "",
        paymentMode: PaymentMode,
        period: SubscriptionPeriod,
        numberOfPeriods: Int = 1
    ) {
        self.price = price
        self.localizedPriceString = localizedPriceString
        self.paymentMode = paymentMode
        self.period = period
        self.numberOfPeriods = numberOfPeriods
    }

    /// How the discount price is charged.
    public enum PaymentMode: String, Sendable, Hashable, Codable {
        case freeTrial
        case payUpFront
        case payAsYouGo
    }
}
