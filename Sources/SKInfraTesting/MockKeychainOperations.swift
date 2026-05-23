import Foundation
import SKCore

// MARK: - Mock Keychain Operations

/// In-memory test double for ``KeychainOperations``.
///
/// Stores data in a dictionary instead of the real keychain, enabling
/// fast, isolated, and deterministic tests of code built on top of
/// ``KeychainStorage``.
///
/// ## Thread Safety
///
/// `@unchecked Sendable` — this mock is intended for single-test use where
/// access is naturally serialized. Do not share an instance across
/// concurrent tasks without adding synchronization.
public final class MockKeychainOperations: KeychainOperations, @unchecked Sendable {

    // MARK: - State

    private var store: [String: Data] = [:]

    /// Tracks the number of `add` calls for verification.
    public private(set) var addCallCount = 0

    /// Tracks the number of `delete` calls for verification.
    public private(set) var deleteCallCount = 0

    /// When set, ``add(_:)`` will return this status instead of succeeding.
    public var addOverrideStatus: OSStatus?

    /// When set, ``copyMatching(_:_:)`` will return this status instead of
    /// succeeding.
    public var copyOverrideStatus: OSStatus?

    /// When set, ``delete(_:)`` will return this status instead of
    /// succeeding.
    public var deleteOverrideStatus: OSStatus?

    /// Creates an empty mock keychain.
    public init() {}

    // MARK: - KeychainOperations

    public func add(_ query: CFDictionary) -> OSStatus {
        addCallCount += 1

        if let override = addOverrideStatus {
            return override
        }

        guard let dict = query as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String,
              let data = dict[kSecValueData as String] as? Data else {
            return errSecParam
        }

        store[account] = data
        return errSecSuccess
    }

    public func copyMatching(
        _ query: CFDictionary,
        _ result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        if let override = copyOverrideStatus {
            return override
        }

        guard let dict = query as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        guard let data = store[account] else {
            return errSecItemNotFound
        }

        result?.pointee = data as CFTypeRef
        return errSecSuccess
    }

    public func delete(_ query: CFDictionary) -> OSStatus {
        deleteCallCount += 1

        if let override = deleteOverrideStatus {
            return override
        }

        guard let dict = query as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        if store.removeValue(forKey: account) != nil {
            return errSecSuccess
        }
        return errSecItemNotFound
    }

    // MARK: - Test Helpers

    /// Resets all stored data and call counts for a clean test.
    public func reset() {
        store.removeAll()
        addCallCount = 0
        deleteCallCount = 0
        addOverrideStatus = nil
        copyOverrideStatus = nil
        deleteOverrideStatus = nil
    }
}
