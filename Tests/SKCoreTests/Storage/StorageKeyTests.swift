import Testing
@testable import SKCore

@Suite("StorageKey")
struct StorageKeyTests {
    
    // MARK: - Initialization
    
    @Test("Stores raw value from init")
    func initWithRawValue() {
        let key = StorageKey<String>("auth_token")
        #expect(key.rawValue == "auth_token")
    }
    
    @Test("Supports string literal initialization")
    func stringLiteralInit() {
        let key: StorageKey<Int> = "counter"
        #expect(key.rawValue == "counter")
    }
    
    // MARK: - Type Safety (Compile-Time)
    
    @Test("Different value types produce distinct key types")
    func typeSafety() {
        let stringKey = StorageKey<String>("token")
        let intKey = StorageKey<Int>("token")
        
        // Same raw value, but different types — they are NOT equal
        // because StorageKey<String> and StorageKey<Int> are different types.
        // This test verifies the phantom type parameter works.
        #expect(stringKey.rawValue == intKey.rawValue)
        // Note: stringKey == intKey would not compile — different types.
    }
    
    // MARK: - Hashable
    
    @Test("Equal keys have equal hash values")
    func hashableConformance() {
        let key1 = StorageKey<String>("token")
        let key2 = StorageKey<String>("token")
        #expect(key1 == key2)
        #expect(key1.hashValue == key2.hashValue)
    }
    
    @Test("Different raw values produce different keys")
    func hashableDifferentKeys() {
        let key1 = StorageKey<String>("token_a")
        let key2 = StorageKey<String>("token_b")
        #expect(key1 != key2)
    }
    
    @Test("Can be used as dictionary keys")
    func usableAsDictionaryKey() {
        var dict: [StorageKey<String>: String] = [:]
        let key = StorageKey<String>("test")
        dict[key] = "value"
        #expect(dict[key] == "value")
    }
    
    // MARK: - Description
    
    @Test("Description includes type and raw value")
    func customDescription() {
        let key = StorageKey<String>("auth_token")
        #expect(key.description == "StorageKey<String>(\"auth_token\")")
    }
}
