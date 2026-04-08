import Foundation

// MARK: - Analytics Value

/// A type-safe union of values supported in analytics properties.
///
/// Constrains property values to types universally supported by
/// analytics backends — strings, integers, doubles, booleans, and dates.
/// This prevents accidental use of complex types that would fail
/// serialization at the vendor layer.
///
/// Conforms to the relevant `ExpressibleBy*Literal` protocols so values
/// can be written inline without explicit wrapping:
///
/// ```swift
/// let properties: AnalyticsProperties = [
///     "name": "Sargis",       // .string
///     "age": 28,              // .int
///     "score": 99.5,          // .double
///     "premium": true         // .bool
/// ]
/// ```
public enum AnalyticsValue: Sendable, Equatable {
    /// A string value.
    case string(String)

    /// An integer value.
    case int(Int)

    /// A floating-point value.
    case double(Double)

    /// A boolean value.
    case bool(Bool)

    /// A date value.
    case date(Date)
}

// MARK: - Literal Conformances

extension AnalyticsValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AnalyticsValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension AnalyticsValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnalyticsValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - CustomStringConvertible

extension AnalyticsValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let value): return "\"\(value)\""
        case .int(let value):    return "\(value)"
        case .double(let value): return "\(value)"
        case .bool(let value):   return "\(value)"
        case .date(let value):   return "\(value)"
        }
    }
}
