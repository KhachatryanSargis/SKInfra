import Testing
import Foundation
@testable import SKCore

@Suite("LogEntry")
struct LogEntryTests {

    // MARK: - Initialization

    @Test("Stores all provided values")
    func initStoresValues() {
        let date = Date()
        let entry = LogEntry(
            message: "test",
            level: .info,
            file: "/path/to/File.swift",
            function: "doWork()",
            line: 42,
            timestamp: date
        )

        #expect(entry.message == "test")
        #expect(entry.level == .info)
        #expect(entry.file == "/path/to/File.swift")
        #expect(entry.function == "doWork()")
        #expect(entry.line == 42)
        #expect(entry.timestamp == date)
    }

    @Test("Default timestamp is approximately now")
    func defaultTimestamp() {
        let before = Date()
        let entry = LogEntry(
            message: "now",
            level: .debug,
            file: #file,
            function: #function,
            line: #line
        )
        let after = Date()

        #expect(entry.timestamp >= before)
        #expect(entry.timestamp <= after)
    }

    // MARK: - Equatable

    @Test("Entries with same values are equal")
    func equatable() {
        let date = Date()
        let entry1 = LogEntry(message: "a", level: .error, file: "f", function: "g", line: 1, timestamp: date)
        let entry2 = LogEntry(message: "a", level: .error, file: "f", function: "g", line: 1, timestamp: date)

        #expect(entry1 == entry2)
    }

    @Test("Entries with different messages are not equal")
    func notEqualDifferentMessage() {
        let date = Date()
        let entry1 = LogEntry(message: "a", level: .error, file: "f", function: "g", line: 1, timestamp: date)
        let entry2 = LogEntry(message: "b", level: .error, file: "f", function: "g", line: 1, timestamp: date)

        #expect(entry1 != entry2)
    }

    // MARK: - Description

    @Test("Description includes level symbol, filename, line, function, and message")
    func description() {
        let entry = LogEntry(
            message: "hello",
            level: .warning,
            file: "/Users/dev/project/Sources/App.swift",
            function: "start()",
            line: 99
        )

        let desc = entry.description
        #expect(desc.contains("⚠️"))
        #expect(desc.contains("[WARNING]"))
        #expect(desc.contains("App.swift"))
        #expect(desc.contains(":99"))
        #expect(desc.contains("start()"))
        #expect(desc.contains("hello"))
    }

    @Test("Description uses only the filename, not the full path")
    func descriptionUsesFilenameOnly() {
        let entry = LogEntry(
            message: "test",
            level: .debug,
            file: "/very/long/path/to/MyFile.swift",
            function: "f()",
            line: 1
        )

        let desc = entry.description
        #expect(!desc.contains("/very/long"))
        #expect(desc.contains("MyFile.swift"))
    }
}
