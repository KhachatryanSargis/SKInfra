import Foundation

// MARK: - Auth Credential

/// A provider-specific credential supplied to ``Auth/signIn(with:)`` and
/// ``Auth/reauthenticate(with:)``.
///
/// Modeled as a closed enum so the supported provider set is part of the
/// public API surface. Adding a new provider is a deliberate, source-visible
/// change in SKCore; impl modules then handle the new case exhaustively.
///
/// ## Sign in with Apple flow
///
/// The Apple case carries the raw nonce because Firebase Auth's Apple
/// credential exchange validates the unhashed nonce against the hashed
/// nonce that was sent to `ASAuthorizationAppleIDProvider`. Callers are
/// responsible for:
///
/// 1. Generating the raw nonce (e.g., 32 cryptographically random bytes).
/// 2. SHA-256 hashing it and setting `ASAuthorizationOpenIDRequest.nonce`
///    to the hex/string-encoded hash.
/// 3. Passing the **raw** (unhashed) nonce into ``apple(idToken:rawNonce:fullName:)``.
///
/// `fullName` is provided only on the user's first sign-in with Apple;
/// subsequent sign-ins must pass `nil`.
public enum AuthCredential: Sendable, Equatable {
    /// A Sign in with Apple credential.
    ///
    /// - Parameters:
    ///   - idToken: The identity token returned in
    ///     `ASAuthorizationAppleIDCredential.identityToken`, decoded as
    ///     UTF-8 string.
    ///   - rawNonce: The unhashed nonce whose SHA-256 hash was set on the
    ///     authorization request.
    ///   - fullName: The user's name, available only on the first Apple
    ///     sign-in for this Apple ID on this app.
    case apple(idToken: String, rawNonce: String, fullName: PersonNameComponents?)
}
