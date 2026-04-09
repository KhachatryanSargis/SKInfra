import Foundation

/// Errors that can occur during storage operations.
///
/// Provides structured error information with the key, operation, and
/// underlying cause — making debugging straightforward.
public enum StorageError: Error, Equatable, Sendable {
    /// The value could not be encoded for storage.
    case encodingFailed(key: String, underlying: String)

    /// The stored data could not be decoded to the expected type.
    case decodingFailed(key: String, underlying: String)

    /// The save operation failed at the persistence layer.
    case saveFailed(key: String, underlying: String)

    /// The load operation failed at the persistence layer.
    case loadFailed(key: String, underlying: String)

    /// The delete operation failed at the persistence layer.
    case deleteFailed(key: String, underlying: String)
}

// MARK: - LocalizedError

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let key, let underlying):
            return "Failed to encode value for key '\(key)': \(underlying)"
        case .decodingFailed(let key, let underlying):
            return "Failed to decode value for key '\(key)': \(underlying)"
        case .saveFailed(let key, let underlying):
            return "Failed to save value for key '\(key)': \(underlying)"
        case .loadFailed(let key, let underlying):
            return "Failed to load value for key '\(key)': \(underlying)"
        case .deleteFailed(let key, let underlying):
            return "Failed to delete value for key '\(key)': \(underlying)"
        }
    }
}
