import Foundation

// MARK: - Collection Namespace Conformances

extension Array: SKNamespaceProvider {}
extension Set: SKNamespaceProvider {}
extension Dictionary: SKNamespaceProvider {}

// MARK: - Namespaced Collection Extensions

extension SKWrapper where Base: Collection {

    /// Returns the element at the given index, or `nil` if out of bounds.
    ///
    /// Prevents index-out-of-range crashes with a safe subscript:
    ///
    /// ```swift
    /// let items = [10, 20, 30]
    /// items.sk.element(at: 1)   // Optional(20)
    /// items.sk.element(at: 5)   // nil (no crash)
    /// ```
    public func element(at index: Base.Index) -> Base.Element? {
        base.indices.contains(index) ? base[index] : nil
    }
}

extension SKWrapper where Base: Collection, Base.Element: Equatable {

    /// Returns the collection with duplicate elements removed,
    /// preserving the order of first occurrence.
    ///
    /// - Complexity: O(n²) where n is the number of elements, due to
    ///   linear scans for each element. For `Hashable` elements, prefer
    ///   ``uniqued()`` which runs in O(n) average time.
    ///
    /// ```swift
    /// [1, 2, 2, 3, 1].sk.removingDuplicates()  // [1, 2, 3]
    /// ```
    public func removingDuplicates() -> [Base.Element] {
        var seen: [Base.Element] = []
        return base.filter { element in
            if seen.contains(element) {
                return false
            }
            seen.append(element)
            return true
        }
    }
}

extension SKWrapper where Base: Collection, Base.Element: Hashable {

    /// Returns the collection with duplicate elements removed,
    /// preserving the order of first occurrence.
    ///
    /// - Complexity: O(n) average time, using a `Set` for membership tracking.
    ///
    /// ```swift
    /// [1, 2, 2, 3, 1].sk.uniqued()  // [1, 2, 3]
    /// ```
    public func uniqued() -> [Base.Element] {
        var seen = Set<Base.Element>()
        return base.filter { seen.insert($0).inserted }
    }
}
