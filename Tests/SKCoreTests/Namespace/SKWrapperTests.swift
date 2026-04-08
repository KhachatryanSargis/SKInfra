import Testing
import Foundation
@testable import SKCore

@Suite("SKWrapper")
struct SKWrapperTests {
    
    // MARK: - Basic Wrapping
    
    @Test("Wraps and exposes the base value")
    func baseBehavior() {
        let wrapper = SKWrapper("hello")
        #expect(wrapper.base == "hello")
    }
    
    @Test("sk accessor returns a wrapper around self")
    func skAccessor() {
        let value = "test"
        let wrapper = value.sk
        #expect(wrapper.base == value)
    }
    
    // MARK: - Value Semantics
    
    @Test("Wrapper is a value type — copies are independent")
    func valueSemantics() {
        let w1 = SKWrapper([1, 2, 3])
        let w2 = w1
        #expect(w1.base == [1, 2, 3])
        #expect(w2.base == [1, 2, 3])
        #expect(w1 == w2)
    }
    
    // MARK: - Equatable
    
    @Test("Wrappers with equal bases are equal")
    func equatable() {
        let a = SKWrapper(42)
        let b = SKWrapper(42)
        #expect(a == b)
    }
    
    @Test("Wrappers with different bases are not equal")
    func notEqual() {
        let a = SKWrapper(1)
        let b = SKWrapper(2)
        #expect(a != b)
    }
    
    // MARK: - Hashable
    
    @Test("Equal wrappers produce equal hashes")
    func hashable() {
        let a = SKWrapper("key")
        let b = SKWrapper("key")
        #expect(a.hashValue == b.hashValue)
    }
    
    @Test("Wrappers can be used as dictionary keys")
    func dictionaryKey() {
        var dict: [SKWrapper<String>: Int] = [:]
        dict[SKWrapper("a")] = 1
        dict[SKWrapper("b")] = 2
        
        #expect(dict[SKWrapper("a")] == 1)
        #expect(dict[SKWrapper("b")] == 2)
    }
    
    // MARK: - Sendable
    
    @Test("Wrapper is Sendable when Base is Sendable")
    func sendable() async {
        let wrapper = SKWrapper("concurrent")
        
        let result = await Task.detached {
            wrapper.base
        }.value
        
        #expect(result == "concurrent")
    }
    
    // MARK: - Static Accessor
    
    @Test("Static sk accessor returns SKWrapper metatype")
    func staticAccessor() {
        let type = String.sk
        #expect(type == SKWrapper<String>.self)
    }
}
