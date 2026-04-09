import Foundation

// MARK: - Composite Logger

/// A logger that forwards messages to multiple underlying loggers.
///
/// Demonstrates the composite pattern applied through protocol-oriented
/// programming: because `LoggerProtocol` is a protocol (not a base class),
/// any combination of loggers can be composed without inheritance.
///
/// Each child logger applies its own ``LoggerProtocol/minimumLevel`` filter
/// independently. The composite's own `minimumLevel` acts as a pre-filter
/// to avoid iterating children for messages that no child would accept.
///
/// ## Usage
///
/// ```swift
/// let logger = CompositeLogger(
///     loggers: [
///         PrintLogger(minimumLevel: .debug),
///         OSLogLogger(subsystem: "com.app", category: "Main", minimumLevel: .info),
///         analyticsLogger  // any LoggerProtocol
///     ]
/// )
///
/// logger.debug("Verbose detail")  // Only PrintLogger handles this
/// logger.error("Something broke")  // All three loggers handle this
/// ```
public struct CompositeLogger: LoggerProtocol {
    /// Pre-filter level — the minimum across all children.
    ///
    /// Computed as the lowest `minimumLevel` among all child loggers.
    /// Messages below this level are guaranteed to be ignored by every child,
    /// so we skip the iteration entirely.
    public let minimumLevel: LogLevel

    /// The child loggers, stored as existentials for heterogeneous collection.
    ///
    /// This is a deliberate use of `any LoggerProtocol` — we need a
    /// heterogeneous array since each logger can be a different concrete type.
    /// The existential overhead is acceptable here because logging is not
    /// in a hot path.
    private let loggers: [any LoggerProtocol]

    /// Creates a composite logger that forwards to all provided loggers.
    ///
    /// - Parameter loggers: The child loggers to forward messages to.
    public init(loggers: [any LoggerProtocol]) {
        self.loggers = loggers
        self.minimumLevel = loggers.map(\.minimumLevel).min() ?? .debug
    }

    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }
        // Evaluate the message once, then forward the string to each child.
        let evaluatedMessage = message()
        for logger in loggers {
            logger.log(evaluatedMessage, level: level, file: file, function: function, line: line)
        }
    }
}
