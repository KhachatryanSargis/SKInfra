import Foundation

import RevenueCat

import SKCore

// MARK: - RevenueCat SDK Error Snapshot

/// A `Sendable` snapshot of a RevenueCat error for use in
/// ``MonetizationError/underlying(_:)``.
internal struct RevenueCatSDKError: Error, Sendable, CustomStringConvertible {
    let code: Int
    let message: String

    init(_ error: Error) {
        let nsError = error as NSError
        self.code = nsError.code
        self.message = error.localizedDescription
    }

    var description: String {
        "RevenueCat(\(code)): \(message)"
    }
}

// MARK: - Error Mapping

internal extension MonetizationError {

    static func mapping(_ error: Error) -> MonetizationError {
        guard let errorCode = error as? ErrorCode else {
            return .underlying(RevenueCatSDKError(error))
        }

        switch errorCode {
        case .purchaseCancelledError:
            return .purchaseCancelled
        case .paymentPendingError:
            return .paymentPending
        case .productNotAvailableForPurchaseError:
            return .productNotAvailable
        case .purchaseNotAllowedError:
            return .purchaseNotAllowed
        case .receiptAlreadyInUseError:
            return .alreadyPurchased
        case .storeProblemError:
            return .storeUnavailable
        case .networkError,
             .offlineConnectionError:
            return .networkUnavailable
        case .configurationError:
            return .notConfigured
        default:
            return .underlying(RevenueCatSDKError(error))
        }
    }
}
