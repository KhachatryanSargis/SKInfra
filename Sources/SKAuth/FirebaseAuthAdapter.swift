import Foundation

@preconcurrency import FirebaseAuth

import SKCore

// MARK: - Disambiguation
//
// Both `SKCore` and `FirebaseAuth` export a type named `AuthCredential`
// (an enum on our side, a class on theirs). `FirebaseCredential` is the
// alias used everywhere we mean Firebase's class; `SKCore.AuthCredential`
// is spelled out fully wherever we mean ours. Bare `AuthCredential` is
// never used in this file because the compiler can't resolve it.
private typealias FirebaseCredential = FirebaseAuth.AuthCredential

// MARK: - Firebase Auth Adapter

/// `SKCore/Auth` implementation backed by FirebaseAuth.
///
/// Owns a single `FirebaseAuth.Auth` instance and a single state-change
/// listener that fan-outs to ``stateChanges`` subscribers. Sign-in is
/// performed via the protocol-neutral ``SKCore/AuthCredential`` enum;
/// today only `.apple` is supported.
///
/// ## Lifecycle
///
/// Construct once during composition-root setup, after
/// `FirebaseApp.configure()`. The adapter starts in
/// ``SKCore/AuthState/unknown``; the FirebaseAuth state listener fires
/// shortly after construction with the cached session (or `nil`),
/// transitioning the adapter to the first concrete state.
///
/// ```swift
/// FirebaseApp.configure()
/// let auth: any Auth = FirebaseAuthAdapter()
/// ```
///
/// ## Thread Safety
///
/// All state is guarded by an `NSLock`. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot
/// verify lock-based safety statically.
public final class FirebaseAuthAdapter: SKCore.Auth, @unchecked Sendable {

    // MARK: - State

    private let firebaseAuth: FirebaseAuth.Auth
    private let lock = NSLock()
    private var state: AuthState = .unknown
    private var subscribers: [UUID: AsyncStream<AuthState>.Continuation] = [:]
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Init

    /// Creates an adapter bound to the default `FirebaseAuth.Auth` instance.
    public convenience init() {
        self.init(firebaseAuth: FirebaseAuth.Auth.auth())
    }

    /// Creates an adapter bound to an explicit `FirebaseAuth.Auth`.
    ///
    /// Useful for multi-app setups where the consumer wants to point the
    /// adapter at a non-default FirebaseApp.
    public init(firebaseAuth: FirebaseAuth.Auth) {
        self.firebaseAuth = firebaseAuth
        self.listenerHandle = firebaseAuth.addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.handleFirebaseStateChange(user: firebaseUser)
        }
    }

    deinit {
        if let handle = listenerHandle {
            firebaseAuth.removeStateDidChangeListener(handle)
        }
        let toFinish: [AsyncStream<AuthState>.Continuation] = lock.withLock {
            let all = Array(subscribers.values)
            subscribers.removeAll()
            return all
        }
        for continuation in toFinish {
            continuation.finish()
        }
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
    public func signIn(with credential: SKCore.AuthCredential) async throws -> AuthUser {
        let firebaseCredential = makeFirebaseCredential(from: credential)
        do {
            let result = try await firebaseAuth.signIn(with: firebaseCredential)
            let user = AuthUser(firebaseUser: result.user)
            transition(to: .signedIn(user))
            return user
        } catch {
            throw AuthError.mapping(error)
        }
    }

    public func signOut() async throws {
        guard firebaseAuth.currentUser != nil else {
            throw AuthError.notSignedIn
        }
        do {
            try firebaseAuth.signOut()
        } catch {
            throw AuthError.mapping(error)
        }
    }

    public func deleteAccount() async throws {
        guard let user = firebaseAuth.currentUser else {
            throw AuthError.notSignedIn
        }
        do {
            try await user.delete()
            transition(to: .signedOut)
        } catch {
            throw AuthError.mapping(error)
        }
    }

    public func reauthenticate(with credential: SKCore.AuthCredential) async throws {
        guard let user = firebaseAuth.currentUser else {
            throw AuthError.notSignedIn
        }
        let firebaseCredential = makeFirebaseCredential(from: credential)
        do {
            _ = try await user.reauthenticate(with: firebaseCredential)
        } catch {
            throw AuthError.mapping(error)
        }
    }

    // MARK: - Private

    private func makeFirebaseCredential(
        from credential: SKCore.AuthCredential
    ) -> FirebaseCredential {
        switch credential {
        case let .apple(idToken, rawNonce, fullName):
            return OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: rawNonce,
                fullName: fullName
            )
        }
    }

    private func handleFirebaseStateChange(user firebaseUser: FirebaseAuth.User?) {
        let newState: AuthState
        if let firebaseUser {
            newState = .signedIn(AuthUser(firebaseUser: firebaseUser))
        } else {
            newState = .signedOut
        }
        transition(to: newState)
    }

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
