import Foundation
import Security

// MARK: - Keychain Operations Protocol

/// Abstraction over Security framework keychain operations.
///
/// Enables dependency injection for testing without hitting the real keychain.
public protocol KeychainOperations: Sendable {
    func add(_ query: CFDictionary) -> OSStatus
    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func delete(_ query: CFDictionary) -> OSStatus
}

// MARK: - System Keychain

/// Production implementation using the Security framework.
public struct SystemKeychainOperations: KeychainOperations, Sendable {
    public init() {}

    public func add(_ query: CFDictionary) -> OSStatus {
        SecItemAdd(query, nil)
    }

    public func copyMatching(
        _ query: CFDictionary,
        _ result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        SecItemCopyMatching(query, result)
    }

    public func delete(_ query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }
}

// MARK: - Keychain Storage

/// `StorageProtocol` implementation backed by the iOS Keychain.
///
/// Suitable for sensitive values like auth tokens, API keys, and credentials.
///
/// ## Usage
/// ```swift
/// let storage = KeychainStorage()
///
/// try storage.save("bearer_abc123", forKey: .authToken)
/// let token = try storage.load(forKey: .authToken)  // String?
/// ```
///
/// ## Security
///
/// Items are stored with `kSecAttrAccessibleAfterFirstUnlock` by default,
/// making them available in the background after the first device unlock.
public struct KeychainStorage: StorageProtocol {
    // MARK: - Dependencies

    private let service: String
    private let keychain: KeychainOperations
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Init

    /// Creates a `KeychainStorage` instance.
    ///
    /// - Parameters:
    ///   - service: Service identifier for keychain items. Defaults to bundle identifier.
    ///   - keychain: Keychain operations implementation. Defaults to real Security framework.
    ///   - encoder: The encoder for serializing values. Defaults to `JSONEncoder()`.
    ///   - decoder: The decoder for deserializing values. Defaults to `JSONDecoder()`.
    public init(
        service: String? = nil,
        keychain: KeychainOperations = SystemKeychainOperations(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.sk.keychain"
        self.keychain = keychain
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - StorageProtocol

    public func save<V: Codable>(_ value: V, forKey key: StorageKey<V>) throws {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw StorageError.encodingFailed(
                key: key.rawValue,
                underlying: error.localizedDescription
            )
        }

        // Remove existing item first to avoid errSecDuplicateItem
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = keychain.add(query as CFDictionary)
        guard status == errSecSuccess else {
            throw StorageError.saveFailed(
                key: key.rawValue,
                underlying: "OSStatus \(status)"
            )
        }
    }

    public func load<V: Codable>(forKey key: StorageKey<V>) throws -> V? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = keychain.copyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw StorageError.loadFailed(
                key: key.rawValue,
                underlying: "OSStatus \(status)"
            )
        }

        do {
            return try decoder.decode(V.self, from: data)
        } catch {
            throw StorageError.decodingFailed(
                key: key.rawValue,
                underlying: error.localizedDescription
            )
        }
    }

    public func delete<V: Codable>(forKey key: StorageKey<V>) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = keychain.delete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.deleteFailed(
                key: key.rawValue,
                underlying: "OSStatus \(status)"
            )
        }
    }
}
