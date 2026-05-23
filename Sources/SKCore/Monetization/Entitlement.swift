import Foundation

// MARK: - Entitlement

/// An active entitlement granting access to a feature or content.
///
/// Represents a single entitlement's current state. Multiple
/// entitlements are carried on ``CustomerInfo/activeEntitlements``.
public struct Entitlement: Sendable, Hashable, Codable, Identifiable {

    /// The entitlement identifier configured in the dashboard.
    public let id: String

    /// Whether this entitlement is currently active.
    public let isActive: Bool

    /// The product identifier that granted this entitlement.
    public let productIdentifier: String

    /// When the entitlement was originally purchased.
    public let originalPurchaseDate: Date?

    /// When the entitlement expires, or `nil` for lifetime.
    public let expirationDate: Date?

    /// Whether this entitlement will renew at expiration.
    public let willRenew: Bool

    /// The store where the product was purchased.
    public let store: Store

    /// Whether the customer is within a billing retry period
    /// (grace period).
    public let isBillingRetryPeriod: Bool

    /// The period type for the current entitlement.
    public let periodType: PeriodType

    /// Creates an `Entitlement`.
    public init(
        id: String,
        isActive: Bool = true,
        productIdentifier: String,
        originalPurchaseDate: Date? = nil,
        expirationDate: Date? = nil,
        willRenew: Bool = true,
        store: Store = .appStore,
        isBillingRetryPeriod: Bool = false,
        periodType: PeriodType = .normal
    ) {
        self.id = id
        self.isActive = isActive
        self.productIdentifier = productIdentifier
        self.originalPurchaseDate = originalPurchaseDate
        self.expirationDate = expirationDate
        self.willRenew = willRenew
        self.store = store
        self.isBillingRetryPeriod = isBillingRetryPeriod
        self.periodType = periodType
    }

    /// The store that processed the purchase.
    public enum Store: String, Sendable, Hashable, Codable {
        case appStore
        case macAppStore
        case playStore
        case stripe
        case promotional
        case unknown
    }

    /// The period type of an entitlement.
    public enum PeriodType: String, Sendable, Hashable, Codable {
        case normal
        case intro
        case trial
    }
}
