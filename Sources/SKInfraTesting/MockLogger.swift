import Foundation
import SKCore

// MARK: - Mock Logger

/// A test spy ``LoggerProtocol`` that records every log entry for
/// verification.
///
/// Captures ``LogEntry`` values so tests can assert on message content,
/// levels, and call-site metadata.
///
/// ## Thread Safety
///
/// `@unchecked Sendable` — Swift Testing runs assertions within a suite
/// sequentially, and `MockLogger` is intended for that single-test usage
/// pattern. Do not share an instance across concurrent tasks without
/// adding synchronization.
public final class MockLogger: LoggerProtocol, @unchecked Sendable {
    /// The minimum severity this logger will record.
    public let minimumLevel: LogLevel

    /// Every log entry observed since the last ``reset()``.
    public private(set) var entries: [LogEntry] = []

    /// Creates a mock logger.
    ///
    /// - Parameter minimumLevel: The minimum severity to record. Defaults
    ///   to `.debug`.
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
        entries.append(entry)
    }

    /// Clears all recorded entries.
    public func reset() {
        entries.removeAll()
    }

    /// Returns the subset of recorded entries at the given level.
    ///
    /// - Parameter level: The level to filter by.
    public func entries(at level: LogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }
}
