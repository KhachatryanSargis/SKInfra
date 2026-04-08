import Testing
import Foundation
@testable import SKCore

@Suite("Collection+SK")
struct CollectionSKTests {
    
    // MARK: - element(at:)
    
    @Test("Returns element at valid index")
    func elementAtValidIndex() {
        let items = [10, 20, 30]
        #expect(items.sk.element(at: 1) == 20)
    }
    
    @Test("Returns nil for out-of-bounds index")
    func elementAtOutOfBounds() {
        let items = [10, 20, 30]
        #expect(items.sk.element(at: 5) == nil)
    }
    
    @Test("Returns nil for negative index")
    func elementAtNegativeIndex() {
        let items = [10, 20, 30]
        #expect(items.sk.element(at: -1) == nil)
    }
    
    @Test("Returns nil for empty collection")
    func elementAtEmptyCollection() {
        let items: [Int] = []
        #expect(items.sk.element(at: 0) == nil)
    }
    
    @Test("Returns first element at index 0")
    func elementAtZero() {
        let items = ["a", "b", "c"]
        #expect(items.sk.element(at: 0) == "a")
    }
    
    // MARK: - removingDuplicates (Equatable)
    
    @Test("Removes duplicate elements preserving order")
    func removingDuplicates() {
        let items = [1, 2, 2, 3, 1, 4]
        #expect(items.sk.removingDuplicates() == [1, 2, 3, 4])
    }
    
    @Test("Returns empty array for empty input")
    func removingDuplicatesEmpty() {
        let items: [Int] = []
        #expect(items.sk.removingDuplicates() == [])
    }
    
    @Test("Returns same array when no duplicates")
    func removingDuplicatesNoDuplicates() {
        let items = [1, 2, 3]
        #expect(items.sk.removingDuplicates() == [1, 2, 3])
    }
    
    // MARK: - uniqued (Hashable)
    
    @Test("Removes duplicate elements using Set for performance")
    func uniqued() {
        let items = [1, 2, 2, 3, 1, 4]
        #expect(items.sk.uniqued() == [1, 2, 3, 4])
    }
    
    @Test("uniqued preserves first occurrence order")
    func uniquedPreservesOrder() {
        let items = ["c", "a", "b", "a", "c"]
        #expect(items.sk.uniqued() == ["c", "a", "b"])
    }
    
    @Test("uniqued returns empty array for empty input")
    func uniquedEmpty() {
        let items: [String] = []
        #expect(items.sk.uniqued() == [])
    }
    
    @Test("uniqued returns same array when no duplicates")
    func uniquedNoDuplicates() {
        let items = [1, 2, 3]
        #expect(items.sk.uniqued() == [1, 2, 3])
    }
}
