import Foundation

import FirebaseAuth

import SKCore

// MARK: - Firebase Error Mapping

/// A `Sendable` snapshot of an arbitrary `NSError` from FirebaseAuth.
///
/// Stored in ``AuthError/underlying(_:)`` so the original SDK error's
/// diagnostic information is preserved without forcing `NSError` itself
/// across `Sendable` boundaries.
internal struct FirebaseAuthSDKError: Error, Sendable, CustomStringConvertible {
    let domain: String
    let code: Int
    let message: String

    init(_ error: Error) {
        let nsError = error as NSError
        self.domain = nsError.domain
        self.code = nsError.code
        self.message = error.localizedDescription
    }

    var description: String {
        "FirebaseAuth \(domain)(\(code)): \(message)"
    }
}

internal extension AuthError {
    /// Maps an arbitrary error thrown by FirebaseAuth onto the protocol-
    /// neutral ``AuthError``.
    static func mapping(_ error: Error) -> AuthError {
        let nsError = error as NSError

        // Only attempt the typed mapping for FIRAuthErrorDomain.
        guard nsError.domain == AuthErrorDomain else {
            return .underlying(FirebaseAuthSDKError(error))
        }

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .underlying(FirebaseAuthSDKError(error))
        }

        switch code {
        case .networkError:
            return .networkUnavailable
        case .requiresRecentLogin:
            return .requiresRecentSignIn
        case .invalidCredential,
             .userTokenExpired,
             .invalidUserToken:
            return .invalidCredential
        case .webContextCancelled:
            return .cancelled
        default:
            return .underlying(FirebaseAuthSDKError(error))
        }
    }
}
