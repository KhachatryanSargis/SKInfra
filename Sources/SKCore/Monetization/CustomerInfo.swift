import Foundation

// MARK: - Customer Info

/// A snapshot of the customer's purchase and entitlement state.
///
/// Provider-neutral projection of the underlying SDK's customer
/// record. Contains active entitlements, all purchased product IDs,
/// and management URLs.
///
/// `Codable` so it can round-trip through ``StorageProtocol`` for
/// offline entitlement checks.
public struct CustomerInfo: Sendable, Hashable, Codable {

    /// The customer's original App Store or user identifier.
    public let originalAppUserId: String

    /// When this customer record was first seen.
    public let firstSeen: Date

    /// Active entitlements keyed by entitlement identifier.
    public let activeEntitlements: [String: Entitlement]

    /// All product identifiers the customer has ever purchased.
    public let allPurchasedProductIdentifiers: Set<String>

    /// The latest expiration date across all active subscriptions,
    /// or `nil` if no subscription is active.
    public let latestExpirationDate: Date?

    /// URL to manage subscriptions in the App Store, if available.
    public let managementURL: URL?

    /// Creates a `CustomerInfo`.
    public init(
        originalAppUserId: String,
        firstSeen: Date = Date(),
        activeEntitlements: [String: Entitlement] = [:],
        allPurchasedProductIdentifiers: Set<String> = [],
        latestExpirationDate: Date? = nil,
        managementURL: URL? = nil
    ) {
        self.originalAppUserId = originalAppUserId
        self.firstSeen = firstSeen
        self.activeEntitlements = activeEntitlements
        self.allPurchasedProductIdentifiers = allPurchasedProductIdentifiers
        self.latestExpirationDate = latestExpirationDate
        self.managementURL = managementURL
    }
}
