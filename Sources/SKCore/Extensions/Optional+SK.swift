import Foundation

// MARK: - Optional Namespace Conformance

extension Optional: SKNamespaceProvider {}

// MARK: - Namespaced Optional Extensions

extension SKWrapper where Base: _OptionalProtocol {

    /// Returns `true` if the wrapped optional is `nil`.
    ///
    /// Provides a more readable alternative to `value == nil`
    /// in complex expressions:
    ///
    /// ```swift
    /// let name: String? = nil
    /// name.sk.isNil        // true
    /// name.sk.isNotNil     // false
    /// ```
    public var isNil: Bool {
        base._isNil
    }

    /// Returns `true` if the wrapped optional is not `nil`.
    public var isNotNil: Bool {
        !base._isNil
    }
}

// MARK: - Internal Protocol for Optional Introspection

/// An internal protocol that allows `SKWrapper` to query
/// whether an `Optional` contains a value without knowing
/// the wrapped type.
///
/// This avoids exposing `Optional`'s internals in the public API
/// while still enabling generic extensions on `SKWrapper`.
///
/// - Warning: This is an implementation detail of SKCore and follows
///   Swift's underscore-prefix convention for non-public API.
///   Do not conform additional types to this protocol — doing so
///   has no meaningful effect and is unsupported.
public protocol _OptionalProtocol {
    /// - Warning: Implementation detail. Do not call directly.
    var _isNil: Bool { get }
}

extension Optional: _OptionalProtocol {
    public var _isNil: Bool {
        self == nil
    }
}
