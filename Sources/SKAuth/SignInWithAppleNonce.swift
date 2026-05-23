import CryptoKit
import Foundation

// MARK: - Sign in with Apple Nonce

/// A matched pair of raw + SHA-256 hashed nonces for the Sign in with Apple
/// + Firebase Auth flow.
///
/// The nonce protects the identity-token exchange from replay attacks. The
/// Apple authorization request receives the **hashed** value as
/// `ASAuthorizationOpenIDRequest.nonce`; Firebase Auth's Apple credential
/// constructor receives the **raw** value to verify the round-trip.
///
/// ```swift
/// let nonce = SignInWithAppleNonce.make()
/// request.nonce = nonce.hashed
///
/// // ...after the ASAuthorization callback:
/// try await auth.signIn(with: .apple(
///     idToken: idTokenString,
///     rawNonce: nonce.raw,
///     fullName: credential.fullName
/// ))
/// ```
///
/// Keep the same `SignInWithAppleNonce` value across both halves of the
/// flow — a fresh nonce per attempt.
public struct SignInWithAppleNonce: Sendable, Hashable {
    /// The unhashed nonce. Pass this to ``SKCore/AuthCredential/apple(idToken:rawNonce:fullName:)``.
    public let raw: String

    /// The SHA-256 hash of ``raw``. Set this on
    /// `ASAuthorizationOpenIDRequest.nonce`.
    public let hashed: String

    /// Creates a nonce pair from an explicit raw value.
    ///
    /// Prefer ``make(length:)`` in production — explicit construction is
    /// intended for tests that need a deterministic value.
    public init(raw: String) {
        self.raw = raw
        self.hashed = Self.sha256(raw)
    }

    /// Generates a fresh cryptographically random nonce.
    ///
    /// - Parameter length: Number of raw characters in the nonce. Apple
    ///   recommends at least 32. Defaults to 32.
    /// - Returns: A nonce pair whose ``raw`` value uses URL- and
    ///   keychain-safe characters only.
    public static func make(length: Int = 32) -> Self {
        precondition(length > 0, "Nonce length must be positive")
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")

        let raw = String(bytes.map { charset[Int($0) % charset.count] })
        return Self(raw: raw)
    }

    /// Computes the lowercase hex SHA-256 hash of `input`.
    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
