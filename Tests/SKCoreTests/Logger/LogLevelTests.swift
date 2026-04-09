import Testing
@testable import SKCore

@Suite("LogLevel")
struct LogLevelTests {

    // MARK: - Raw Values & Ordering

    @Test("Raw values are ordered from debug (0) to fatal (4)")
    func rawValueOrdering() {
        #expect(LogLevel.debug.rawValue == 0)
        #expect(LogLevel.info.rawValue == 1)
        #expect(LogLevel.warning.rawValue == 2)
        #expect(LogLevel.error.rawValue == 3)
        #expect(LogLevel.fatal.rawValue == 4)
    }

    @Test("Comparable follows severity ordering")
    func comparableOrdering() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.error < LogLevel.fatal)
    }

    @Test("Equal levels are not less than each other")
    func equalLevelsNotLessThan() {
        #expect(!(LogLevel.info < LogLevel.info))
    }

    // MARK: - Description

    @Test("Description returns uppercase level name")
    func description() {
        #expect(LogLevel.debug.description == "DEBUG")
        #expect(LogLevel.info.description == "INFO")
        #expect(LogLevel.warning.description == "WARNING")
        #expect(LogLevel.error.description == "ERROR")
        #expect(LogLevel.fatal.description == "FATAL")
    }

    // MARK: - Symbol

    @Test("Each level has a distinct emoji symbol")
    func symbols() {
        let symbols = LogLevel.allCases.map(\.symbol)
        let uniqueSymbols = Set(symbols)
        #expect(uniqueSymbols.count == LogLevel.allCases.count)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable returns all five levels in order")
    func allCases() {
        let expected: [LogLevel] = [.debug, .info, .warning, .error, .fatal]
        #expect(LogLevel.allCases == expected)
    }
}
