import Testing
import Foundation
@testable import SKCore

@Suite("KeychainStorage")
struct KeychainStorageTests {
    private let mockKeychain: MockKeychainOperations
    private let storage: KeychainStorage

    init() {
        let mock = MockKeychainOperations()
        self.mockKeychain = mock
        self.storage = KeychainStorage(
            service: "com.skcore.tests",
            keychain: mock
        )
    }

    // MARK: - Save & Load

    @Test("Save and load a String value")
    func saveAndLoadString() throws {
        let key = StorageKey<String>("auth_token")

        try storage.save("bearer_abc123", forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == "bearer_abc123")
    }

    @Test("Save and load a complex Codable struct")
    func saveAndLoadStruct() throws {
        let key = StorageKey<TestUser>("secure_user")
        let user = TestUser(id: 1, name: "Sargis", email: "test@example.com")

        try storage.save(user, forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == user)
    }

    @Test("Save and load an Int value")
    func saveAndLoadInt() throws {
        let key = StorageKey<Int>("pin_code")

        try storage.save(1234, forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == 1234)
    }

    // MARK: - Overwrite

    @Test("Save overwrites previous value (delete + add)")
    func overwrite() throws {
        let key = StorageKey<String>("token")

        try storage.save("first", forKey: key)
        let initialDeleteCount = mockKeychain.deleteCallCount

        try storage.save("second", forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == "second")
        // Verify delete was called before the second add (delete-before-add pattern)
        #expect(mockKeychain.deleteCallCount > initialDeleteCount)
    }

    // MARK: - Load Missing Key

    @Test("Load returns nil for non-existent key")
    func loadMissing() throws {
        let key = StorageKey<String>("does_not_exist")
        let loaded = try storage.load(forKey: key)

        #expect(loaded == nil)
    }

    // MARK: - Delete

    @Test("Delete removes the stored value")
    func delete() throws {
        let key = StorageKey<String>("to_delete")

        try storage.save("temporary", forKey: key)
        try storage.delete(forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == nil)
    }

    @Test("Delete for non-existent key does not throw")
    func deleteNonExistent() throws {
        let key = StorageKey<String>("never_saved")
        #expect(throws: Never.self) {
            try storage.delete(forKey: key)
        }
    }

    // MARK: - Contains

    @Test("Contains returns true for existing key")
    func containsExistingKey() throws {
        let key = StorageKey<String>("exists")
        try storage.save("secret", forKey: key)

        #expect(try storage.contains(forKey: key) == true)
    }

    @Test("Contains returns false for missing key")
    func containsMissingKey() throws {
        let key = StorageKey<String>("missing")

        #expect(try storage.contains(forKey: key) == false)
    }

    // MARK: - Error Handling

    @Test("Save throws saveFailed when keychain add fails")
    func saveFailure() throws {
        mockKeychain.addOverrideStatus = errSecDuplicateItem
        let key = StorageKey<String>("fail_save")

        #expect {
            try storage.save("value", forKey: key)
        } throws: { error in
            guard let storageError = error as? StorageError,
                  case .saveFailed(let errorKey, _) = storageError else {
                return false
            }
            return errorKey == "fail_save"
        }
    }

    @Test("Load throws loadFailed when keychain read fails")
    func loadFailure() {
        mockKeychain.copyOverrideStatus = errSecInteractionNotAllowed
        let key = StorageKey<String>("fail_load")

        #expect {
            _ = try storage.load(forKey: key)
        } throws: { error in
            guard let storageError = error as? StorageError,
                  case .loadFailed(let errorKey, _) = storageError else {
                return false
            }
            return errorKey == "fail_load"
        }
    }

    @Test("Delete throws deleteFailed when keychain delete fails")
    func deleteFailure() {
        mockKeychain.deleteOverrideStatus = errSecInteractionNotAllowed
        let key = StorageKey<String>("fail_delete")

        #expect {
            try storage.delete(forKey: key)
        } throws: { error in
            guard let storageError = error as? StorageError,
                  case .deleteFailed(let errorKey, _) = storageError else {
                return false
            }
            return errorKey == "fail_delete"
        }
    }

    // MARK: - Sendable Conformance

    @Test("Storage can be used across concurrency boundaries")
    func sendableConformance() async throws {
        let key = StorageKey<String>("concurrent")
        let sendableStorage = storage
        try sendableStorage.save("secret", forKey: key)

        let loaded = try await Task.detached {
            try sendableStorage.load(forKey: key)
        }.value

        #expect(loaded == "secret")
    }
}
