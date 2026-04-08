import Foundation

// MARK: - Analytics Properties

/// Type-safe key-value container for analytics event and user properties.
///
/// Wraps a `[String: AnalyticsValue]` dictionary, providing a clean API
/// for building property bags without exposing raw dictionary types
/// across module boundaries.
///
/// Supports dictionary literal initialization for ergonomic call sites:
///
/// ```swift
/// analytics.track("purchase_completed", properties: [
///     "item_id": "abc-123",
///     "price": 9.99,
///     "is_first_purchase": true
/// ])
/// ```
///
/// ## Supported Value Types
///
/// Properties accept strings, numbers, booleans, and dates via the
/// ``AnalyticsValue`` enum. Vendor-specific implementations map these
/// to their SDK's expected format.
public struct AnalyticsProperties: Sendable, Equatable {
    /// The underlying key-value storage.
    public let values: [String: AnalyticsValue]

    /// Creates properties from a dictionary of analytics values.
    ///
    /// - Parameter values: The key-value pairs for this property bag.
    public init(_ values: [String: AnalyticsValue] = [:]) {
        self.values = values
    }

    /// Accesses the value for the given key.
    public subscript(key: String) -> AnalyticsValue? {
        values[key]
    }

    /// Whether the property bag contains no entries.
    public var isEmpty: Bool { values.isEmpty }

    /// The number of key-value pairs.
    public var count: Int { values.count }

    /// Returns a new `AnalyticsProperties` by merging the given properties.
    ///
    /// If both contain the same key, the value from `other` wins.
    ///
    /// - Parameter other: The properties to merge in.
    /// - Returns: A new instance containing all key-value pairs.
    public func merging(_ other: AnalyticsProperties) -> AnalyticsProperties {
        AnalyticsProperties(values.merging(other.values) { _, new in new })
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnalyticsProperties: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnalyticsValue)...) {
        self.values = Dictionary(uniqueKeysWithValues: elements)
    }
}

// MARK: - CustomStringConvertible

extension AnalyticsProperties: CustomStringConvertible {
    public var description: String {
        let pairs = values
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        return "[\(pairs)]"
    }
}
