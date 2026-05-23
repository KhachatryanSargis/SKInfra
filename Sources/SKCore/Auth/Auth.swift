import Foundation

// MARK: - Auth Protocol

/// An abstraction over user-identity sign-in, sign-out, deletion, and state
/// observation.
///
/// `Auth` is the single identity-related customization point used by every
/// other SKInfra product that needs a user UID. Feature code depends on
/// this protocol rather than `FirebaseAuth.Auth` directly, so tests can
/// swap in `MockAuth` (from `SKInfraTesting`) for fully deterministic
/// behavior.
///
/// ## Scope
///
/// The surface is deliberately minimal:
///
/// - Identity observation: ``currentUser`` for a synchronous snapshot,
///   ``stateChanges`` for a hot async stream.
/// - Identity mutation: ``signIn(with:)``, ``signOut()``,
///   ``deleteAccount()``, ``reauthenticate(with:)``.
///
/// Anonymous sign-in, multi-provider linking, password reset, and provider
/// unlinking are explicitly out of scope at this stage. They can be added
/// later behind their own protocols (or by extending this one) once a real
/// feature needs them.
///
/// ## Conformance
///
/// Implementations are responsible for:
///
/// - Replaying the current ``AuthState`` to every new subscriber of
///   ``stateChanges`` immediately on subscription.
/// - Starting in ``AuthState/unknown`` and transitioning to a concrete
///   state exactly once the SDK has determined whether a cached session
///   exists.
/// - Keeping ``currentUser`` and the most recent ``stateChanges`` element
///   in agreement after each mutating call returns.
/// - Translating SDK-specific errors into ``AuthError``.
///
/// ## Usage
///
/// ```swift
/// // Production
/// container.register(Auth.self, scope: .singleton) {
///     FirebaseAuthAdapter()
/// }
///
/// // SwiftUI
/// struct RootView: View {
///     @State private var state: AuthState = .unknown
///     let auth: any Auth
///
///     var body: some View {
///         content(for: state)
///             .task {
///                 for await next in auth.stateChanges {
///                     state = next
///                 }
///             }
///     }
/// }
///
/// // Tests
/// let auth = MockAuth()
/// auth.simulateSignIn(AuthUser(id: "u_42"))
/// ```
public protocol Auth: Sendable {
    /// A synchronous snapshot of the current user, or `nil` when signed out.
    ///
    /// Useful for SwiftUI `init` defaults and any imperative read where
    /// awaiting the stream is overkill. For continuous observation use
    /// ``stateChanges`` instead.
    var currentUser: AuthUser? { get }

    /// A hot stream of authentication state changes.
    ///
    /// The stream emits the current state immediately on subscription,
    /// then one element per subsequent change. ``AuthState/unknown`` is
    /// the initial state at app launch, before the underlying SDK has
    /// reported whether a cached session exists — subscribers who arrive
    /// after that point see the concrete state and never see ``unknown``.
    ///
    /// Multiple concurrent subscribers each receive their own copy of the
    /// stream from their own subscription point onward.
    var stateChanges: AsyncStream<AuthState> { get }

    /// Signs the user in with the supplied credential.
    ///
    /// On success, ``currentUser`` is updated and ``stateChanges`` emits
    /// a ``AuthState/signedIn(_:)`` element before this method returns.
    ///
    /// - Parameter credential: The provider-specific credential.
    /// - Returns: The signed-in user snapshot.
    /// - Throws: ``AuthError`` describing why the sign-in failed.
    @discardableResult
    func signIn(with credential: AuthCredential) async throws -> AuthUser

    /// Signs the current user out.
    ///
    /// Throws ``AuthError/notSignedIn`` if no user is signed in.
    func signOut() async throws

    /// Permanently deletes the current user's account on the backend.
    ///
    /// Required by App Store Review Guideline 5.1.1 for any app that
    /// supports account creation. Implementations are expected to surface
    /// ``AuthError/requiresRecentSignIn`` when the session is too stale —
    /// callers should then prompt for ``reauthenticate(with:)`` and retry.
    ///
    /// Throws ``AuthError/notSignedIn`` if no user is signed in.
    func deleteAccount() async throws

    /// Re-runs the sign-in flow against the current account.
    ///
    /// Required before sensitive operations (such as
    /// ``deleteAccount()`` or password changes) when the session is too
    /// old. Does not change which user is signed in — refreshes the
    /// credential associated with the existing account.
    ///
    /// - Parameter credential: A fresh credential for the same account.
    /// - Throws: ``AuthError/notSignedIn`` if no user is signed in, or
    ///   any standard ``AuthError`` if the re-authentication fails.
    func reauthenticate(with credential: AuthCredential) async throws
}
