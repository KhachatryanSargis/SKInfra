import Foundation

// MARK: - Log Entry

/// An immutable record of a single log event.
///
/// Captures the message, metadata, and call-site context at the moment
/// of logging. Used by ``PrintLogger`` and test helpers to inspect
/// logged output without coupling to a specific output format.
///
/// Conforms to `Sendable` for safe passage across isolation boundaries.
public struct LogEntry: Sendable, Equatable {
    /// The log message text.
    public let message: String

    /// The severity level of this entry.
    public let level: LogLevel

    /// The source file where the log call originated.
    public let file: String

    /// The function where the log call originated.
    public let function: String

    /// The line number where the log call originated.
    public let line: Int

    /// The timestamp when this entry was created.
    public let timestamp: Date

    /// Creates a log entry with the given metadata.
    public init(
        message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int,
        timestamp: Date = Date()
    ) {
        self.message = message
        self.level = level
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }
}

// MARK: - CustomStringConvertible

extension LogEntry: CustomStringConvertible {
    public var description: String {
        let filename = (file as NSString).lastPathComponent
        return "\(level.symbol) [\(level)] \(filename):\(line) \(function) — \(message)"
    }
}
