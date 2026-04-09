import Foundation

// MARK: - Namespace Provider Protocol

/// A protocol that grants access to SKCore's namespaced extensions via `.sk`.
///
/// Conform any type to gain the `.sk` accessor without polluting
/// the type's own API surface:
///
/// ```swift
/// extension String: SKNamespaceProvider {}
///
/// // Now available:
/// "hello".sk.capitalizingFirstLetter()  // "Hello"
/// ```
///
/// Both `sk` (instance) and `SK` (static) accessors are provided.
///
/// ## Adding Custom Namespaced Methods
///
/// Extend `SKWrapper` with a `where Base` constraint:
///
/// ```swift
/// extension SKWrapper where Base == String {
///     func reversed() -> String {
///         String(base.reversed())
///     }
/// }
///
/// "abc".sk.reversed()  // "cba"
/// ```
public protocol SKNamespaceProvider {
    /// The concrete type being wrapped.
    associatedtype NamespaceBase

    /// Instance accessor for namespaced extensions.
    var sk: SKWrapper<NamespaceBase> { get }

    /// Static/type-level accessor for namespaced extensions.
    static var sk: SKWrapper<NamespaceBase>.Type { get }
}

// MARK: - Default Implementation

extension SKNamespaceProvider {
    /// Returns an `SKWrapper` wrapping `self`, providing access to
    /// namespaced instance methods.
    public var sk: SKWrapper<Self> {
        SKWrapper(self)
    }

    /// Returns the `SKWrapper` metatype for this type, providing access
    /// to namespaced static methods.
    public static var sk: SKWrapper<Self>.Type {
        SKWrapper<Self>.self
    }
}
