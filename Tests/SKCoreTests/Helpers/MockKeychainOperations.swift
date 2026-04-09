import Foundation
@testable import SKCore

/// In-memory mock for keychain operations.
///
/// Stores data in a dictionary instead of the real keychain,
/// enabling fast, isolated, and deterministic tests.
///
/// - Note: `@unchecked Sendable` is safe here because this type is only used
///   in `@MainActor`-isolated test suites where access is serialized.
///   Do not use this mock from concurrent contexts without adding synchronization.
final class MockKeychainOperations: KeychainOperations, @unchecked Sendable {
    // MARK: - State

    private var store: [String: Data] = [:]

    /// Tracks the number of add calls for verification.
    private(set) var addCallCount = 0

    /// Tracks the number of delete calls for verification.
    private(set) var deleteCallCount = 0

    /// When set, `add` will return this status instead of succeeding.
    var addOverrideStatus: OSStatus?

    /// When set, `copyMatching` will return this status instead of succeeding.
    var copyOverrideStatus: OSStatus?

    /// When set, `delete` will return this status instead of succeeding.
    var deleteOverrideStatus: OSStatus?

    // MARK: - KeychainOperations

    func add(_ query: CFDictionary) -> OSStatus {
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

    func copyMatching(
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

    func delete(_ query: CFDictionary) -> OSStatus {
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

    /// Resets all state for a clean test.
    func reset() {
        store.removeAll()
        addCallCount = 0
        deleteCallCount = 0
        addOverrideStatus = nil
        copyOverrideStatus = nil
        deleteOverrideStatus = nil
    }
}
