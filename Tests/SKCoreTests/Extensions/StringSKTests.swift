import Testing
import Foundation
@testable import SKCore

@Suite("String+SK")
struct StringSKTests {

    // MARK: - capitalizingFirstLetter

    @Test("Capitalizes the first letter of a lowercase string")
    func capitalizeFirstLetter() {
        #expect("hello world".sk.capitalizingFirstLetter() == "Hello world")
    }

    @Test("Returns empty string for empty input")
    func capitalizeEmpty() {
        #expect("".sk.capitalizingFirstLetter().isEmpty)
    }

    @Test("Leaves already-capitalized string unchanged")
    func capitalizeAlreadyCapitalized() {
        #expect("Hello".sk.capitalizingFirstLetter() == "Hello")
    }

    @Test("Handles single character")
    func capitalizeSingleChar() {
        #expect("a".sk.capitalizingFirstLetter() == "A")
    }

    // MARK: - nilIfEmpty

    @Test("Returns trimmed string when non-empty")
    func nilIfEmptyNonEmpty() {
        #expect("  hello  ".sk.nilIfEmpty() == "hello")
    }

    @Test("Returns nil for whitespace-only string")
    func nilIfEmptyWhitespace() {
        #expect("   ".sk.nilIfEmpty() == nil)
    }

    @Test("Returns nil for empty string")
    func nilIfEmptyEmpty() {
        #expect("".sk.nilIfEmpty() == nil)
    }

    @Test("Returns nil for newline-only string")
    func nilIfEmptyNewlines() {
        #expect("\n\t\n".sk.nilIfEmpty() == nil)
    }

    @Test("Preserves inner whitespace")
    func nilIfEmptyInnerWhitespace() {
        #expect("hello world".sk.nilIfEmpty() == "hello world")
    }

    // MARK: - truncated

    @Test("Truncates long string with default suffix")
    func truncateDefault() {
        #expect("Hello, World!".sk.truncated(to: 5) == "Hello…")
    }

    @Test("Returns string unchanged when within limit")
    func truncateNoOp() {
        #expect("Hi".sk.truncated(to: 5) == "Hi")
    }

    @Test("Returns string unchanged when exactly at limit")
    func truncateExactLength() {
        #expect("Hello".sk.truncated(to: 5) == "Hello")
    }

    @Test("Uses custom suffix when provided")
    func truncateCustomSuffix() {
        #expect("Hello, World!".sk.truncated(to: 5, suffix: "..") == "Hello..")
    }

    @Test("Handles empty string")
    func truncateEmpty() {
        #expect("".sk.truncated(to: 5).isEmpty)
    }

    // MARK: - isAlphanumeric

    @Test("Returns true for alphanumeric string")
    func alphanumericTrue() {
        #expect("Hello123".sk.isAlphanumeric == true)
    }

    @Test("Returns false for string with spaces")
    func alphanumericWithSpaces() {
        #expect("Hello 123".sk.isAlphanumeric == false)
    }

    @Test("Returns false for empty string")
    func alphanumericEmpty() {
        #expect("".sk.isAlphanumeric == false)
    }

    @Test("Returns false for string with special characters")
    func alphanumericSpecialChars() {
        #expect("hello@world".sk.isAlphanumeric == false)
    }

    @Test("Returns true for letters only")
    func alphanumericLettersOnly() {
        #expect("Hello".sk.isAlphanumeric == true)
    }

    @Test("Returns true for digits only")
    func alphanumericDigitsOnly() {
        #expect("12345".sk.isAlphanumeric == true)
    }
}
