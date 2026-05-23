import Testing
import Foundation
@testable import SKAuth

@Suite("SignInWithAppleNonce")
struct SignInWithAppleNonceTests {

    @Test("Explicit raw produces a deterministic SHA-256 hash")
    func deterministicHash() {
        let nonce = SignInWithAppleNonce(raw: "abc")
        // SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
        #expect(nonce.raw == "abc")
        #expect(nonce.hashed == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("make() produces a non-empty raw of the requested length")
    func makeRespectsLength() {
        let nonce = SignInWithAppleNonce.make(length: 32)
        #expect(nonce.raw.count == 32)
        #expect(!nonce.hashed.isEmpty)
    }

    @Test("make() returns distinct nonces across invocations")
    func makeIsRandom() {
        let a = SignInWithAppleNonce.make()
        let b = SignInWithAppleNonce.make()
        #expect(a.raw != b.raw)
        #expect(a.hashed != b.hashed)
    }

    @Test("hashed is 64 lowercase hex characters")
    func hashedShape() {
        let nonce = SignInWithAppleNonce.make()
        #expect(nonce.hashed.count == 64)
        let hexCharset = CharacterSet(charactersIn: "0123456789abcdef")
        #expect(nonce.hashed.unicodeScalars.allSatisfy { hexCharset.contains($0) })
    }

    @Test("make() only uses characters from the valid charset")
    func makeCharsetValid() {
        let charset = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = SignInWithAppleNonce.make(length: 256)
        #expect(nonce.raw.allSatisfy { charset.contains($0) })
    }

    @Test("Equality follows the raw value")
    func equality() {
        let a = SignInWithAppleNonce(raw: "same")
        let b = SignInWithAppleNonce(raw: "same")
        let c = SignInWithAppleNonce(raw: "different")
        #expect(a == b)
        #expect(a != c)
    }
}
