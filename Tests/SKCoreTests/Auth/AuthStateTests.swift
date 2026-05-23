import Testing
import Foundation
@testable import SKCore

@Suite("AuthState")
struct AuthStateTests {

    @Test("unknown equals unknown")
    func unknownEquality() {
        #expect(AuthState.unknown == .unknown)
    }

    @Test("signedOut equals signedOut")
    func signedOutEquality() {
        #expect(AuthState.signedOut == .signedOut)
    }

    @Test("signedIn equality depends on the wrapped user")
    func signedInEquality() {
        let user = AuthUser(id: "u_1")
        let other = AuthUser(id: "u_2")
        #expect(AuthState.signedIn(user) == .signedIn(user))
        #expect(AuthState.signedIn(user) != .signedIn(other))
    }

    @Test("Different cases are not equal")
    func crossCaseInequality() {
        let user = AuthUser(id: "u_1")
        #expect(AuthState.unknown != .signedOut)
        #expect(AuthState.unknown != .signedIn(user))
        #expect(AuthState.signedOut != .signedIn(user))
    }
}
