import Foundation
@testable import SKCore

/// A test spy logger that records all log entries for verification.
///
/// Thread-safe via actor isolation pattern — but since Swift Testing
/// runs tests sequentially within a suite, direct mutation is fine here.
/// The logger captures ``LogEntry`` values so tests can assert on
/// message content, levels, and call-site metadata.
final class MockLogger: LoggerProtocol, @unchecked Sendable {
    let minimumLevel: LogLevel
    private(set) var entries: [LogEntry] = []
    
    init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }
    
    func log(
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
    
    /// Resets recorded entries.
    func reset() {
        entries.removeAll()
    }
    
    /// Returns entries filtered by level.
    func entries(at level: LogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }
}
