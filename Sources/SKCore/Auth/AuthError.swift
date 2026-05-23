import Foundation

// MARK: - Auth Error

/// Errors thrown by ``Auth`` operations.
///
/// `AuthError` is intentionally provider-neutral. Concrete impl modules
/// (e.g., `SKAuth` wrapping FirebaseAuth) translate SDK-specific errors into
/// these cases and surface anything they cannot classify through
/// ``underlying(_:)``.
public enum AuthError: Error, Sendable {
    /// The user cancelled the sign-in UI before the flow completed.
    ///
    /// Typically *not* a real error from the user's perspective — UI layers
    /// should suppress alerts for this case and silently return to the
    /// previous screen.
    case cancelled

    /// ``Auth/signOut()`` or ``Auth/deleteAccount()`` was invoked while no
    /// user was signed in.
    case notSignedIn

    /// The current session is too old for the requested sensitive operation.
    ///
    /// Recover by calling ``Auth/reauthenticate(with:)`` with a fresh
    /// credential, then retrying the original call.
    case requiresRecentSignIn

    /// The supplied credential is malformed or invalid (expired token,
    /// missing nonce, mismatched audience, etc.).
    case invalidCredential

    /// The current credential's provider is not configured or not supported
    /// by the underlying impl module. The associated value is the offending
    /// provider identifier (e.g., `"apple.com"`).
    case providerNotSupported(String)

    /// The operation failed because the device is offline or the auth
    /// backend is unreachable.
    case networkUnavailable

    /// An underlying SDK error not classifiable as any of the above.
    ///
    /// The wrapped value preserves the original error for logging while
    /// keeping the public surface ``Sendable``.
    case underlying(any Error & Sendable)
}

// MARK: - Equatable

extension AuthError: Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled),
             (.notSignedIn, .notSignedIn),
             (.requiresRecentSignIn, .requiresRecentSignIn),
             (.invalidCredential, .invalidCredential),
             (.networkUnavailable, .networkUnavailable):
            return true
        case let (.providerNotSupported(a), .providerNotSupported(b)):
            return a == b
        case let (.underlying(a), .underlying(b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }
}
