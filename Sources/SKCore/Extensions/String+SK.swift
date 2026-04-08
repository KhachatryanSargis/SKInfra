import Foundation

// MARK: - String Namespace Conformance

extension String: SKNamespaceProvider {}

// MARK: - Namespaced String Extensions

extension SKWrapper where Base == String {
    
    /// Returns the string with its first character uppercased.
    ///
    /// Unlike `capitalized` (which capitalizes every word), this only
    /// affects the first character — useful for sentence-case formatting.
    ///
    /// ```swift
    /// "hello world".sk.capitalizingFirstLetter()  // "Hello world"
    /// "".sk.capitalizingFirstLetter()              // ""
    /// "A".sk.capitalizingFirstLetter()             // "A"
    /// ```
    public func capitalizingFirstLetter() -> String {
        guard let first = base.first else { return base }
        return first.uppercased() + base.dropFirst()
    }
    
    /// Returns the string with leading and trailing whitespace and
    /// newlines removed, or `nil` if the result is empty.
    ///
    /// Useful for form validation where blank strings should be treated
    /// as absent values:
    ///
    /// ```swift
    /// "  hello  ".sk.nilIfEmpty()   // "hello"
    /// "   ".sk.nilIfEmpty()         // nil
    /// "".sk.nilIfEmpty()            // nil
    /// ```
    public func nilIfEmpty() -> String? {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    /// Truncates the string, keeping at most `maxCharacters` from the original
    /// and appending a suffix (default `"…"`) if truncation occurs.
    ///
    /// The total length of the returned string may exceed `maxCharacters`
    /// by the length of the suffix. Use `maxCharacters` to control how much
    /// of the *original content* is preserved, not the total output length.
    ///
    /// Operates on `Character` boundaries — never splits a grapheme cluster.
    ///
    /// ```swift
    /// "Hello, World!".sk.truncated(to: 5)          // "Hello…"  (5 + 1 suffix)
    /// "Hi".sk.truncated(to: 5)                     // "Hi"      (no truncation)
    /// "Hello, World!".sk.truncated(to: 5, suffix: "..") // "Hello.." (5 + 2 suffix)
    /// ```
    public func truncated(to maxCharacters: Int, suffix: String = "…") -> String {
        guard base.count > maxCharacters else { return base }
        return String(base.prefix(maxCharacters)) + suffix
    }
    
    /// Returns `true` if the string contains only alphanumeric characters.
    ///
    /// Returns `false` for empty strings.
    ///
    /// ```swift
    /// "Hello123".sk.isAlphanumeric  // true
    /// "Hello 123".sk.isAlphanumeric // false (contains space)
    /// "".sk.isAlphanumeric          // false
    /// ```
    public var isAlphanumeric: Bool {
        !base.isEmpty && base.allSatisfy(\.isLetter || \.isNumber)
    }
}

// MARK: - Private Helpers

/// Combines two `Character` predicates with logical OR.
///
/// Enables the syntax `\.isLetter || \.isNumber` as a predicate
/// for `allSatisfy` and similar higher-order functions.
private func || (
    lhs: @escaping (Character) -> Bool,
    rhs: @escaping (Character) -> Bool
) -> (Character) -> Bool {
    { lhs($0) || rhs($0) }
}
