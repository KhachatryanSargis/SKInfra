import Foundation

// MARK: - Storage Protocol

/// Type-safe key-value storage protocol.
///
/// Unlike raw `Data`-based storage, this protocol uses ``StorageKey`` to bind
/// the key string to a specific `Codable` value type, preventing mismatched
/// save/load operations at compile time.
///
/// ## Conforming Types
///
/// Implementations handle encoding/decoding internally:
///
/// ```swift
/// struct UserDefaultsStorage: StorageProtocol {
///     func save<V: Codable>(_ value: V, forKey key: StorageKey<V>) throws { ... }
///     func load<V: Codable>(forKey key: StorageKey<V>) throws -> V? { ... }
///     func delete<V: Codable>(forKey key: StorageKey<V>) throws { ... }
/// }
/// ```
///
/// ## Usage
///
/// ```swift
/// // Define keys with their value types
/// extension StorageKey where Value == String {
///     static let authToken = StorageKey("auth_token")
/// }
///
/// extension StorageKey where Value == User {
///     static let currentUser = StorageKey("current_user")
/// }
///
/// // Type safety is enforced by the compiler
/// try storage.save("abc123", forKey: .authToken)       // ✅
/// try storage.save(user, forKey: .currentUser)          // ✅
/// try storage.save(42, forKey: .authToken)              // ❌ Compile error
///
/// let token: String? = try storage.load(forKey: .authToken)  // Type inferred
/// ```
public protocol StorageProtocol: Sendable {
    /// Persists a value associated with the given key.
    ///
    /// - Parameters:
    ///   - value: The value to store. Must conform to `Codable`.
    ///   - key: A type-safe key that binds to the value type.
    /// - Throws: A ``StorageError`` if encoding or persistence fails.
    func save<V: Codable>(_ value: V, forKey key: StorageKey<V>) throws

    /// Retrieves a value for the given key.
    ///
    /// - Parameter key: A type-safe key that determines the return type.
    /// - Returns: The decoded value, or `nil` if the key doesn't exist.
    /// - Throws: A ``StorageError`` if decoding fails.
    func load<V: Codable>(forKey key: StorageKey<V>) throws -> V?

    /// Removes the value associated with the given key.
    ///
    /// No error is thrown if the key doesn't exist.
    ///
    /// - Parameter key: The key to remove.
    /// - Throws: A ``StorageError`` if the deletion fails.
    func delete<V: Codable>(forKey key: StorageKey<V>) throws

    /// Returns whether a value exists for the given key.
    ///
    /// Default implementation calls `load` and checks for `nil`.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: `true` if a value exists for the key.
    func contains<V: Codable>(forKey key: StorageKey<V>) throws -> Bool
}

// MARK: - Default Implementation

public extension StorageProtocol {
    func contains<V: Codable>(forKey key: StorageKey<V>) throws -> Bool {
        try load(forKey: key) != nil
    }
}
