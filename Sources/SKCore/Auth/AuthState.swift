import Foundation

// MARK: - Auth State

/// The high-level authentication state observed by ``Auth/stateChanges``.
///
/// Consumers should treat ``unknown`` as a real, distinct state — not a
/// shorthand for "signed out". Without it, UI would briefly flash the
/// signed-out experience on cold launch before the underlying SDK has
/// finished restoring the cached user.
///
/// ``unknown`` only ever surfaces while the underlying SDK is still
/// determining whether a cached session exists. After the first concrete
/// state has been observed, the impl transitions to ``signedOut`` or
/// ``signedIn(_:)`` and does not return to ``unknown``.
///
/// ```swift
/// for await state in auth.stateChanges {
///     switch state {
///     case .unknown:
///         // Initial state — show a splash, not the sign-in screen
///     case .signedOut:
///         // Real signed-out state — show the sign-in screen
///     case .signedIn(let user):
///         // Route to the authenticated experience
///     }
/// }
/// ```
public enum AuthState: Sendable, Equatable {
    /// The initial state before the SDK has determined whether a cached
    /// session exists. Replaced by ``signedOut`` or ``signedIn(_:)`` once
    /// the SDK reports its first concrete state, and never returned to.
    case unknown

    /// No user is currently signed in.
    case signedOut

    /// A user is signed in. The associated value is the current snapshot.
    case signedIn(AuthUser)
}
