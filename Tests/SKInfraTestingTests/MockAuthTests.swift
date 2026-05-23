import Testing
import Foundation
import SKCore
import SKInfraTesting

@Suite("MockAuth")
struct MockAuthTests {

    // MARK: - Initial State

    @Test("Default initial state is .unknown with no current user")
    func defaultInitialState() {
        let auth = MockAuth()
        #expect(auth.currentUser == nil)
    }

    @Test("Custom initial signedIn state exposes currentUser")
    func customSignedInInitialState() {
        let user = AuthUser(id: "u_42")
        let auth = MockAuth(initialState: .signedIn(user))
        #expect(auth.currentUser == user)
    }

    // MARK: - Stream Replay

    @Test("stateChanges replays the current state immediately on subscription")
    func streamReplaysCurrentState() async {
        let user = AuthUser(id: "u_42")
        let auth = MockAuth(initialState: .signedIn(user))
        var iterator = auth.stateChanges.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == .signedIn(user))
    }

    @Test("simulateSignIn emits a state change to active subscribers")
    func simulateSignInEmits() async {
        let auth = MockAuth()
        var iterator = auth.stateChanges.makeAsyncIterator()
        let initial = await iterator.next()
        #expect(initial == .unknown)

        let user = AuthUser(id: "u_7")
        auth.simulateSignIn(user)
        let next = await iterator.next()
        #expect(next == .signedIn(user))
    }

    @Test("Multiple subscribers each see state changes from their subscription point")
    func multipleSubscribers() async {
        let auth = MockAuth()
        var first = auth.stateChanges.makeAsyncIterator()
        _ = await first.next()  // .unknown

        let user = AuthUser(id: "u_first")
        auth.simulateSignIn(user)
        let firstSignedIn = await first.next()
        #expect(firstSignedIn == .signedIn(user))

        // Second subscriber joins after the sign-in — should replay current.
        var second = auth.stateChanges.makeAsyncIterator()
        let secondInitial = await second.next()
        #expect(secondInitial == .signedIn(user))

        auth.simulateSignOut()
        let firstSignedOut = await first.next()
        let secondSignedOut = await second.next()
        #expect(firstSignedOut == .signedOut)
        #expect(secondSignedOut == .signedOut)
    }

    // MARK: - signIn(with:)

    @Test("signIn returns the injected user and updates state")
    func signInSuccess() async throws {
        let auth = MockAuth()
        let user = AuthUser(id: "u_1", displayName: "Mootie Owner")
        auth.nextSignInResult = .success(user)

        let result = try await auth.signIn(with: .apple(
            idToken: "tok",
            rawNonce: "nonce",
            fullName: nil
        ))
        #expect(result == user)
        #expect(auth.currentUser == user)
        #expect(auth.signInCallCount == 1)
        #expect(auth.signInCredentials.count == 1)
    }

    @Test("signIn throws the injected failure and leaves state unchanged")
    func signInFailure() async throws {
        let auth = MockAuth()
        auth.nextSignInResult = .failure(.networkUnavailable)
        await #expect(throws: AuthError.networkUnavailable) {
            try await auth.signIn(with: .apple(
                idToken: "tok",
                rawNonce: "nonce",
                fullName: nil
            ))
        }
        #expect(auth.currentUser == nil)
    }

    @Test("signIn without an injected result defaults to .invalidCredential")
    func signInDefaultsToInvalidCredential() async throws {
        let auth = MockAuth()
        await #expect(throws: AuthError.invalidCredential) {
            try await auth.signIn(with: .apple(
                idToken: "tok",
                rawNonce: "nonce",
                fullName: nil
            ))
        }
    }

    // MARK: - signOut

    @Test("signOut transitions to signedOut when a user is present")
    func signOutSuccess() async throws {
        let auth = MockAuth(initialState: .signedIn(AuthUser(id: "u_1")))
        try await auth.signOut()
        #expect(auth.currentUser == nil)
        #expect(auth.signOutCallCount == 1)
    }

    @Test("signOut throws .notSignedIn when no user is present")
    func signOutWhenSignedOut() async throws {
        let auth = MockAuth(initialState: .signedOut)
        await #expect(throws: AuthError.notSignedIn) {
            try await auth.signOut()
        }
    }

    // MARK: - deleteAccount

    @Test("deleteAccount signs the user out on success")
    func deleteAccountSuccess() async throws {
        let auth = MockAuth(initialState: .signedIn(AuthUser(id: "u_1")))
        try await auth.deleteAccount()
        #expect(auth.currentUser == nil)
        #expect(auth.deleteAccountCallCount == 1)
    }

    @Test("deleteAccount surfaces injected errors without changing state")
    func deleteAccountRequiresReauth() async throws {
        let user = AuthUser(id: "u_1")
        let auth = MockAuth(initialState: .signedIn(user))
        auth.nextDeleteAccountError = .requiresRecentSignIn
        await #expect(throws: AuthError.requiresRecentSignIn) {
            try await auth.deleteAccount()
        }
        #expect(auth.currentUser == user)
    }

    // MARK: - reauthenticate

    @Test("reauthenticate leaves currentUser unchanged on success")
    func reauthenticateSuccess() async throws {
        let user = AuthUser(id: "u_1")
        let auth = MockAuth(initialState: .signedIn(user))
        try await auth.reauthenticate(with: .apple(
            idToken: "tok2",
            rawNonce: "nonce2",
            fullName: nil
        ))
        #expect(auth.currentUser == user)
        #expect(auth.reauthenticateCallCount == 1)
        #expect(auth.reauthenticateCredentials.count == 1)
    }

    // MARK: - resetCallTracking

    @Test("resetCallTracking clears counts and injected results but preserves state")
    func resetCallTrackingPreservesState() async throws {
        let user = AuthUser(id: "u_1")
        let auth = MockAuth(initialState: .signedIn(user))
        try await auth.signOut()
        #expect(auth.signOutCallCount == 1)
        auth.simulateSignIn(user)
        auth.nextSignInResult = .success(user)
        auth.resetCallTracking()
        #expect(auth.signOutCallCount == 0)
        #expect(auth.nextSignInResult == nil)
        #expect(auth.currentUser == user)
    }
}
