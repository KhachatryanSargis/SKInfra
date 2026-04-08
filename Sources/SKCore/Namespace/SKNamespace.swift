import Foundation

// MARK: - Namespace Wrapper

/// A lightweight, generic struct that acts as a namespace for SKCore extensions.
///
/// Instead of adding methods directly to Foundation types (which risks
/// name collisions with Apple's own additions or other libraries), all
/// SKCore extensions are scoped behind the `.sk` accessor:
///
/// ```swift
/// "hello world".sk.capitalizingFirstLetter()   // "Hello world"
/// myDate.sk.formatted(.iso8601)                // "2024-01-15T..."
/// ```
///
/// ## Why a Struct Namespace?
///
/// This is a textbook value-type design:
/// - `SKWrapper` is a **struct** — no heap allocation, no reference counting
/// - It holds the `Base` type by value (or by reference if `Base` is a class)
/// - It's **generic** — one wrapper works for `String`, `Date`, `Array`, etc.
/// - It's `Sendable` when `Base` is `Sendable`
///
/// ## How It Works
///
/// 1. `SKNamespaceProvider` is a protocol with a single computed property `sk`
/// 2. A default implementation returns `SKWrapper(self)`
/// 3. Types opt in by conforming to `SKNamespaceProvider`
/// 4. Extensions on `SKWrapper where Base == SomeType` add namespaced methods
///
/// This pattern is widely used in the Swift ecosystem (RxSwift's `.rx`,
/// Kingfisher's `.kf`, Moya's `.moya`).
public struct SKWrapper<Base> {
    /// The wrapped value that namespaced methods operate on.
    public let base: Base
    
    /// Creates a namespace wrapper around the given value.
    ///
    /// You typically don't call this directly — use the `.sk` accessor instead.
    public init(_ base: Base) {
        self.base = base
    }
}

// MARK: - Sendable Conformance

extension SKWrapper: Sendable where Base: Sendable {}

// MARK: - Equatable Conformance

extension SKWrapper: Equatable where Base: Equatable {
    public static func == (lhs: SKWrapper, rhs: SKWrapper) -> Bool {
        lhs.base == rhs.base
    }
}

// MARK: - Hashable Conformance

extension SKWrapper: Hashable where Base: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}
