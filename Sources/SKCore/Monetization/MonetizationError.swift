import Foundation

// MARK: - Monetization Error

/// Errors thrown by ``MonetizationProtocol`` operations.
///
/// Intentionally provider-neutral. Concrete impl modules translate
/// SDK-specific errors into these cases and surface anything they
/// cannot classify through ``underlying(_:)``.
public enum MonetizationError: Error, Sendable {

    /// The user cancelled the purchase flow before completing.
    ///
    /// Typically not a real error from the user's perspective — UI
    /// layers should suppress alerts for this case.
    case purchaseCancelled

    /// The payment is pending external action (e.g., Ask to Buy,
    /// PSD2/SCA verification, or pending price consent).
    case paymentPending

    /// The product is not available for purchase in the current
    /// storefront or configuration.
    case productNotAvailable

    /// The purchase could not be completed because the device or
    /// App Store account does not support purchases.
    case purchaseNotAllowed

    /// The App Store receipt could not be verified.
    case receiptVerificationFailed

    /// The customer already owns this product (non-consumable or
    /// active subscription).
    case alreadyPurchased

    /// The store (App Store) is not reachable or returned an
    /// unexpected error.
    case storeUnavailable

    /// The network is not available.
    case networkUnavailable

    /// The SDK has not been configured. Call configure in the
    /// composition root before performing operations.
    case notConfigured

    /// An underlying SDK error not classifiable as any of the above.
    ///
    /// The wrapped value preserves the original error for logging
    /// while keeping the public surface ``Sendable``.
    case underlying(any Error & Sendable)
}

// MARK: - Equatable

extension MonetizationError: Equatable {
    public static func == (lhs: MonetizationError, rhs: MonetizationError) -> Bool {
        switch (lhs, rhs) {
        case (.purchaseCancelled, .purchaseCancelled),
             (.paymentPending, .paymentPending),
             (.productNotAvailable, .productNotAvailable),
             (.purchaseNotAllowed, .purchaseNotAllowed),
             (.receiptVerificationFailed, .receiptVerificationFailed),
             (.alreadyPurchased, .alreadyPurchased),
             (.storeUnavailable, .storeUnavailable),
             (.networkUnavailable, .networkUnavailable),
             (.notConfigured, .notConfigured):
            return true
        case let (.underlying(a), .underlying(b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }
}
