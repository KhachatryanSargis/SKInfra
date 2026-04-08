import Foundation

// MARK: - Storage Key Protocol

/// Type-safe storage key that binds a key string to a specific value type.
///
/// Instead of stringly-typed keys with manual encoding/decoding:
/// ```swift
/// // Before (unsafe):
/// storage.save(someData, forKey: "user_token")
/// let token: String? = storage.load(forKey: "user_token") // hope it's a String
///
/// // After (type-safe):
/// enum Keys {
///     static let userToken = StorageKey<String>("user_token")
/// }
/// storage.save("abc123", forKey: Keys.userToken)
/// let token = storage.load(forKey: Keys.userToken) // guaranteed String?
/// ```
///
/// The phantom `Value` parameter is never stored — it exists purely
/// to enforce type safety at compile time.
public struct StorageKey<Value: Codable>: Sendable, Hashable {
    /// The raw string identifier used for persistence.
    public let rawValue: String
    
    /// Creates a type-safe storage key.
    /// - Parameter rawValue: The underlying key string used for storage lookup.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension StorageKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

// MARK: - CustomStringConvertible

extension StorageKey: CustomStringConvertible {
    public var description: String {
        "StorageKey<\(Value.self)>(\"\(rawValue)\")"
    }
}
