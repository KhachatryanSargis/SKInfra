/// Errors that can occur during dependency resolution.
///
/// These errors indicate configuration issues (missing registrations or
/// type mismatches) that should be caught during development. In production,
/// a well-configured container should never produce these errors.
public enum DependencyResolutionError: Error, Sendable, Equatable {
    /// No factory was registered for the requested type and name combination.
    ///
    /// - Parameters:
    ///   - type: A string representation of the requested type.
    ///   - name: The optional name used during resolution, or `nil`.
    case notRegistered(type: String, name: String?)

    /// A factory was registered but returned a value of an unexpected type.
    ///
    /// This typically indicates a programming error in the registration.
    ///
    /// - Parameters:
    ///   - expected: A string representation of the expected type.
    ///   - actual: A string representation of the type that was returned.
    case typeMismatch(expected: String, actual: String)

    /// A parameterized factory was resolved with an argument of the wrong type.
    ///
    /// - Parameters:
    ///   - factory: A string representation of the factory's expected parameter type.
    ///   - provided: A string representation of the argument type that was passed.
    case argumentTypeMismatch(factory: String, provided: String)
}

// MARK: - LocalizedError

import Foundation

extension DependencyResolutionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notRegistered(let type, let name):
            if let name {
                return "No registration found for type '\(type)' with name '\(name)'"
            }
            return "No registration found for type '\(type)'"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected '\(expected)', got '\(actual)'"
        case .argumentTypeMismatch(let factory, let provided):
            return "Argument type mismatch: factory expects '\(factory)', provided '\(provided)'"
        }
    }
}
