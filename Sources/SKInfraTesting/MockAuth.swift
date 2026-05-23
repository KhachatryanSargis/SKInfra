import Foundation
import SKCore

// MARK: - Mock Auth

/// In-memory ``Auth`` test double with explicit state control.
///
/// `MockAuth` never talks to a real identity provider. State changes only
/// when the test calls a `simulate…` method or invokes one of the
/// ``Auth`` mutators (which themselves drive deterministic state). Anything
/// that observes ``Auth`` — UI, view models, sync orchestrators — therefore
/// runs under fully reproducible conditions.
///
/// ```swift
/// let auth = MockAuth()
/// let viewModel = OnboardingViewModel(auth: auth)
///
/// auth.nextSignInResult = .success(AuthUser(id: "u_1"))
/// try await viewModel.signInWithApple()
/// #expect(auth.signInCallCount == 1)
/// #expect(auth.currentUser?.id == "u_1")
/// ```
///
/// ## State control
///
/// Two layers of control are exposed:
///
/// - **Direct simulation** — ``simulateSignIn(_:)``, ``simulateSignOut()``,
///   and ``simulateStateChange(_:)`` set state without going through the
///   ``Auth`` API. Useful for arranging preconditions.
/// - **Result injection** — ``nextSignInResult``, ``nextSignOutError``,
///   ``nextDeleteAccountError``, ``nextReauthenticateError``. When set,
///   the next matching ``Auth`` call consumes the value, mutates state
///   accordingly, then clears the slot. Useful for asserting against
///   real call paths.
///
/// ## Thread Safety
///
/// All state is guarded by an `NSLock`. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot
/// verify lock-based safety statically.
public final class MockAuth: Auth, @unchecked Sendable {
    // MARK: - State

    private let lock = NSLock()
    private var state: AuthState
    private var subscribers: [UUID: AsyncStream<AuthState>.Continuation] = [:]

    // MARK: - Call Tracking

    /// Number of ``signIn(with:)`` calls observed.
    public private(set) var signInCallCount = 0

    /// Number of ``signOut()`` calls observed.
    public private(set) var signOutCallCount = 0

    /// Number of ``deleteAccount()`` calls observed.
    public private(set) var deleteAccountCallCount = 0

    /// Number of ``reauthenticate(with:)`` calls observed.
    public private(set) var reauthenticateCallCount = 0

    /// The credentials passed to ``signIn(with:)``, in call order.
    public private(set) var signInCredentials: [AuthCredential] = []

    /// The credentials passed to ``reauthenticate(with:)``, in call order.
    public private(set) var reauthenticateCredentials: [AuthCredential] = []

    // MARK: - Result Injection

    /// When set, the next ``signIn(with:)`` call consumes this value.
    ///
    /// On `.success(user)`, state transitions to ``AuthState/signedIn(_:)``
    /// and the user is returned. On `.failure(error)`, the error is thrown
    /// and state is left unchanged.
    public var nextSignInResult: Result<AuthUser, AuthError>?

    /// When set, the next ``signOut()`` call throws this error instead of
    /// transitioning state.
    public var nextSignOutError: AuthError?

    /// When set, the next ``deleteAccount()`` call throws this error
    /// instead of transitioning state.
    public var nextDeleteAccountError: AuthError?

    /// When set, the next ``reauthenticate(with:)`` call throws this error
    /// instead of completing successfully.
    public var nextReauthenticateError: AuthError?

    // MARK: - Init

    /// Creates a mock starting in the given state.
    ///
    /// - Parameter initialState: The initial ``AuthState``. Defaults to
    ///   ``AuthState/unknown`` to model the cold-launch case.
    public init(initialState: AuthState = .unknown) {
        self.state = initialState
    }

    // MARK: - Auth

    public var currentUser: AuthUser? {
        lock.withLock {
            switch state {
            case .signedIn(let user): return user
            case .signedOut, .unknown: return nil
            }
        }
    }

    public var stateChanges: AsyncStream<AuthState> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot: AuthState = lock.withLock {
                subscribers[id] = continuation
                return state
            }
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeSubscriber(id: id)
            }
        }
    }

    @discardableResult
    public func signIn(with credential: AuthCredential) async throws -> AuthUser {
        let result: Result<AuthUser, AuthError> = lock.withLock {
            signInCallCount += 1
            signInCredentials.append(credential)
            let pending = nextSignInResult ?? .failure(.invalidCredential)
            nextSignInResult = nil
            return pending
        }
        switch result {
        case .success(let user):
            transition(to: .signedIn(user))
            return user
        case .failure(let error):
            throw error
        }
    }

    public func signOut() async throws {
        try lock.withLock {
            signOutCallCount += 1
            if let error = nextSignOutError {
                nextSignOutError = nil
                throw error
            }
            guard case .signedIn = state else {
                throw AuthError.notSignedIn
            }
        }
        transition(to: .signedOut)
    }

    public func deleteAccount() async throws {
        try lock.withLock {
            deleteAccountCallCount += 1
            if let error = nextDeleteAccountError {
                nextDeleteAccountError = nil
                throw error
            }
            guard case .signedIn = state else {
                throw AuthError.notSignedIn
            }
        }
        transition(to: .signedOut)
    }

    public func reauthenticate(with credential: AuthCredential) async throws {
        try lock.withLock {
            reauthenticateCallCount += 1
            reauthenticateCredentials.append(credential)
            if let error = nextReauthenticateError {
                nextReauthenticateError = nil
                throw error
            }
            guard case .signedIn = state else {
                throw AuthError.notSignedIn
            }
        }
        // State is intentionally unchanged on success — re-authentication
        // refreshes the credential, not the signed-in user.
    }

    // MARK: - Simulation API

    /// Forces the mock into ``AuthState/signedIn(_:)`` with the given user.
    ///
    /// Emits a state change to every active subscriber. Bypasses
    /// ``Auth/signIn(with:)`` — does not increment ``signInCallCount``.
    public func simulateSignIn(_ user: AuthUser) {
        transition(to: .signedIn(user))
    }

    /// Forces the mock into ``AuthState/signedOut``.
    ///
    /// Emits a state change to every active subscriber. Bypasses
    /// ``Auth/signOut()`` — does not increment ``signOutCallCount``.
    public func simulateSignOut() {
        transition(to: .signedOut)
    }

    /// Forces the mock into the given state.
    ///
    /// Useful for asserting against the ``AuthState/unknown`` initial state
    /// or for arranging exotic sequences.
    public func simulateStateChange(_ newState: AuthState) {
        transition(to: newState)
    }

    /// Resets all call counts, injected results, and credential logs to
    /// their initial values. State and subscribers are preserved.
    public func resetCallTracking() {
        lock.withLock {
            signInCallCount = 0
            signOutCallCount = 0
            deleteAccountCallCount = 0
            reauthenticateCallCount = 0
            signInCredentials.removeAll()
            reauthenticateCredentials.removeAll()
            nextSignInResult = nil
            nextSignOutError = nil
            nextDeleteAccountError = nil
            nextReauthenticateError = nil
        }
    }

    // MARK: - Private

    private func transition(to newState: AuthState) {
        let listeners: [AsyncStream<AuthState>.Continuation] = lock.withLock {
            guard state != newState else { return [] }
            state = newState
            return Array(subscribers.values)
        }
        for listener in listeners {
            listener.yield(newState)
        }
    }

    private func removeSubscriber(id: UUID) {
        lock.withLock {
            _ = subscribers.removeValue(forKey: id)
        }
    }
}
