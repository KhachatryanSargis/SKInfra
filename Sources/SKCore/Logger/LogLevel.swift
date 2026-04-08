import Foundation

// MARK: - Log Level

/// Severity levels for log messages, ordered from most verbose to most critical.
///
/// Each level maps to an appropriate `OSLogType` when used with the
/// ``OSLogLogger`` implementation. The raw values enable filtering:
///
/// ```swift
/// extension LoggerProtocol {
///     func shouldLog(_ level: LogLevel, minimum: LogLevel) -> Bool {
///         level.rawValue >= minimum.rawValue
///     }
/// }
/// ```
public enum LogLevel: Int, Sendable, Comparable, CaseIterable, CustomStringConvertible {
    /// Verbose diagnostic information. Disabled in production.
    case debug = 0
    
    /// General informational messages about app flow.
    case info = 1
    
    /// Potentially problematic situations that aren't failures.
    case warning = 2
    
    /// Recoverable errors that need attention.
    case error = 3
    
    /// Critical failures that may cause data loss or crashes.
    case fatal = 4
    
    // MARK: - Comparable
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        switch self {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        case .fatal:   return "FATAL"
        }
    }
    
    /// Emoji prefix for human-readable console output.
    public var symbol: String {
        switch self {
        case .debug:   return "🔍"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "❌"
        case .fatal:   return "💀"
        }
    }
}
