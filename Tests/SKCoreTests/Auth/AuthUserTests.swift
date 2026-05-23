import Testing
import Foundation
@testable import SKCore

@Suite("AuthUser")
struct AuthUserTests {

    @Test("Default init only requires an id")
    func minimalInit() {
        let user = AuthUser(id: "u_1")
        #expect(user.id == "u_1")
        #expect(user.displayName == nil)
        #expect(user.email == nil)
        #expect(user.photoURL == nil)
        #expect(user.isAnonymous == false)
        #expect(user.providerIDs.isEmpty)
        #expect(user.creationDate == nil)
        #expect(user.lastSignInDate == nil)
    }

    @Test("Hashable equality is value-based")
    func hashableEquality() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = AuthUser(
            id: "u_1",
            displayName: "Mootie Lover",
            email: "user@example.com",
            providerIDs: ["apple.com"],
            creationDate: date
        )
        let b = AuthUser(
            id: "u_1",
            displayName: "Mootie Lover",
            email: "user@example.com",
            providerIDs: ["apple.com"],
            creationDate: date
        )
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Codable round-trip preserves every field")
    func codableRoundTrip() throws {
        let original = AuthUser(
            id: "u_42",
            displayName: "Sargis",
            email: "sargis@example.com",
            photoURL: URL(string: "https://example.com/avatar.png"),
            isAnonymous: false,
            providerIDs: ["apple.com", "password"],
            creationDate: Date(timeIntervalSince1970: 1_600_000_000),
            lastSignInDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AuthUser.self, from: data)
        #expect(decoded == original)
    }
}
