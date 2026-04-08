import Testing
import Foundation
@testable import SKCore

@Suite("UserDefaultsStorage")
struct UserDefaultsStorageTests {
    // Use an isolated suite to avoid cross-test contamination
    private let suiteName = "com.skcore.tests.\(UUID().uuidString)"
    private var storage: UserDefaultsStorage
    private var defaults: UserDefaults
    
    init() {
        let defaults = UserDefaults(suiteName: suiteName)!
        self.defaults = defaults
        self.storage = UserDefaultsStorage(defaults: defaults)
    }
    
    // MARK: - Save & Load
    
    @Test("Save and load a String value")
    func saveAndLoadString() throws {
        let key = StorageKey<String>("greeting")
        
        try storage.save("hello", forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == "hello")
    }
    
    @Test("Save and load an Int value")
    func saveAndLoadInt() throws {
        let key = StorageKey<Int>("counter")
        
        try storage.save(42, forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == 42)
    }
    
    @Test("Save and load a Bool value")
    func saveAndLoadBool() throws {
        let key = StorageKey<Bool>("flag")
        
        try storage.save(true, forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == true)
    }
    
    @Test("Save and load a complex Codable struct")
    func saveAndLoadStruct() throws {
        let key = StorageKey<TestUser>("current_user")
        let user = TestUser(id: 1, name: "Sargis", email: "test@example.com")
        
        try storage.save(user, forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == user)
    }
    
    @Test("Save and load an array of Codable values")
    func saveAndLoadArray() throws {
        let key = StorageKey<[String]>("tags")
        let tags = ["swift", "ios", "architecture"]
        
        try storage.save(tags, forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == tags)
    }
    
    @Test("Save and load an optional value wrapped in array")
    func saveAndLoadOptionalWrapped() throws {
        let key = StorageKey<TestSettings>("settings")
        let settings = TestSettings(isDarkMode: true, fontSize: 14, language: "en")
        
        try storage.save(settings, forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == settings)
    }
    
    // MARK: - Overwrite
    
    @Test("Save overwrites previous value for same key")
    func overwrite() throws {
        let key = StorageKey<String>("mutable")
        
        try storage.save("first", forKey: key)
        try storage.save("second", forKey: key)
        let loaded = try storage.load(forKey: key)
        
        #expect(loaded == "second")
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
        try storage.save("value", forKey: key)
        
        #expect(try storage.contains(forKey: key) == true)
    }
    
    @Test("Contains returns false for missing key")
    func containsMissingKey() throws {
        let key = StorageKey<String>("missing")
        
        #expect(try storage.contains(forKey: key) == false)
    }
    
    // MARK: - Type Safety at Runtime
    
    @Test("Loading with wrong key type decodes fails gracefully")
    func typeMismatchAtRuntime() throws {
        // Save as String, but try to load as Int using a different key
        // with the same raw value. This simulates a programmer error
        // where two keys share a raw value but differ in type.
        let stringKey = StorageKey<String>("shared_raw")
        let intKey = StorageKey<Int>("shared_raw")
        
        try storage.save("hello", forKey: stringKey)
        
        // Should throw a decodingFailed error, not crash
        #expect(throws: StorageError.self) {
            _ = try storage.load(forKey: intKey)
        }
    }
    
    // MARK: - Sendable Conformance
    
    @Test("Storage can be used across concurrency boundaries")
    func sendableConformance() async throws {
        let key = StorageKey<String>("concurrent")
        let sendableStorage = storage
        try sendableStorage.save("value", forKey: key)
        
        let loaded = try await Task.detached {
            try sendableStorage.load(forKey: key)
        }.value
        
        #expect(loaded == "value")
    }
}
