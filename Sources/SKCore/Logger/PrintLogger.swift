import Foundation

// MARK: - Print Logger

/// A simple logger that writes formatted messages to standard output via `print()`.
///
/// Useful for development, debugging, and unit tests. For production logging
/// with system-level integration, use ``OSLogLogger`` instead.
///
/// ## Thread Safety
///
/// `PrintLogger` is a value type (`struct`) with no mutable state, making it
/// inherently `Sendable`. The `print()` function itself is thread-safe.
///
/// ## Usage
///
/// ```swift
/// let logger = PrintLogger(minimumLevel: .debug)
/// logger.info("Server responded with 200")
/// // ℹ️ [INFO] MyFile.swift:42 fetchData() — Server responded with 200
///
/// let releaseLogger = PrintLogger(minimumLevel: .warning)
/// releaseLogger.debug("This won't print")  // Suppressed
/// releaseLogger.error("Connection failed")  // Printed
/// ```
public struct PrintLogger: LoggerProtocol {
    public let minimumLevel: LogLevel
    
    /// Creates a print logger that emits messages at or above the given level.
    ///
    /// - Parameter minimumLevel: The minimum severity to emit. Defaults to `.debug`.
    public init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }
    
    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }
        let entry = LogEntry(
            message: message(),
            level: level,
            file: file,
            function: function,
            line: line
        )
        print(entry.description)
    }
}
