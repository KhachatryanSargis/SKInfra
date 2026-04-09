import Foundation

/// `StorageProtocol` implementation backed by `UserDefaults`.
///
/// Suitable for small, non-sensitive values like user preferences,
/// feature flags, and cached settings.
///
/// ## Usage
/// ```swift
/// let storage = UserDefaultsStorage()
///
/// try storage.save(true, forKey: .onboardingComplete)
/// let completed = try storage.load(forKey: .onboardingComplete)  // Bool?
/// ```
///
/// ## Thread Safety
///
/// `UserDefaults` is thread-safe by default. This type is `Sendable`.
public struct UserDefaultsStorage: StorageProtocol {
    // MARK: - Dependencies

    // UserDefaults is thread-safe per Apple documentation.
    // Marked `nonisolated(unsafe)` because UserDefaults does not formally
    // conform to Sendable, but Apple guarantees thread-safe access.
    nonisolated(unsafe) private let defaults: UserDefaults

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Init

    /// Creates a `UserDefaultsStorage` instance.
    ///
    /// - Parameters:
    ///   - defaults: The `UserDefaults` suite to use. Defaults to `.standard`.
    ///   - encoder: The encoder for serializing values. Defaults to `JSONEncoder()`.
    ///   - decoder: The decoder for deserializing values. Defaults to `JSONDecoder()`.
    public init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - StorageProtocol

    public func save<V: Codable>(_ value: V, forKey key: StorageKey<V>) throws {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw StorageError.encodingFailed(
                key: key.rawValue,
                underlying: error.localizedDescription
            )
        }

        defaults.set(data, forKey: key.rawValue)
    }

    public func load<V: Codable>(forKey key: StorageKey<V>) throws -> V? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        do {
            return try decoder.decode(V.self, from: data)
        } catch {
            throw StorageError.decodingFailed(
                key: key.rawValue,
                underlying: error.localizedDescription
            )
        }
    }

    public func delete<V: Codable>(forKey key: StorageKey<V>) throws {
        defaults.removeObject(forKey: key.rawValue)
    }
}
