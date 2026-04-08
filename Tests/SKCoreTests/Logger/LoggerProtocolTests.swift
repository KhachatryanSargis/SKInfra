import Testing
import Foundation
@testable import SKCore

@Suite("LoggerProtocol — Default Implementations")
struct LoggerProtocolTests {
    private let logger = MockLogger()
    
    // MARK: - Convenience Methods Delegate to log()
    
    @Test("debug() logs at debug level")
    func debugDelegatesToLog() {
        logger.debug("test message")
        
        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .debug)
        #expect(logger.entries[0].message == "test message")
    }
    
    @Test("info() logs at info level")
    func infoDelegatesToLog() {
        logger.info("info message")
        
        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .info)
        #expect(logger.entries[0].message == "info message")
    }
    
    @Test("warning() logs at warning level")
    func warningDelegatesToLog() {
        logger.warning("warning message")
        
        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .warning)
    }
    
    @Test("error() logs at error level")
    func errorDelegatesToLog() {
        logger.error("error message")
        
        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .error)
    }
    
    @Test("fatal() logs at fatal level")
    func fatalDelegatesToLog() {
        logger.fatal("fatal message")
        
        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .fatal)
    }
    
    // MARK: - Call-Site Metadata
    
    @Test("Convenience methods capture file, function, and line")
    func capturesCallSiteMetadata() {
        let expectedLine = #line + 1
        logger.info("metadata test")
        
        let entry = logger.entries[0]
        #expect(entry.file.contains("LoggerProtocolTests.swift"))
        #expect(entry.function == "capturesCallSiteMetadata()")
        #expect(entry.line == expectedLine)
    }
    
    // MARK: - Level Filtering
    
    @Test("Messages below minimumLevel are suppressed")
    func levelFiltering() {
        let filteredLogger = MockLogger(minimumLevel: .warning)
        
        filteredLogger.debug("suppressed")
        filteredLogger.info("suppressed")
        filteredLogger.warning("visible")
        filteredLogger.error("visible")
        
        #expect(filteredLogger.entries.count == 2)
        #expect(filteredLogger.entries[0].level == .warning)
        #expect(filteredLogger.entries[1].level == .error)
    }
    
    @Test("Messages at exactly minimumLevel are emitted")
    func exactLevelMatch() {
        let errorLogger = MockLogger(minimumLevel: .error)
        
        errorLogger.error("at threshold")
        
        #expect(errorLogger.entries.count == 1)
    }
    
    // MARK: - Autoclosure Lazy Evaluation
    
    @Test("Message closure is not evaluated when level is filtered")
    func lazyEvaluation() {
        let errorLogger = MockLogger(minimumLevel: .error)
        var evaluated = false
        
        errorLogger.debug({
            evaluated = true
            return "expensive computation"
        }())
        
        #expect(!evaluated)
    }
    
    // MARK: - Multiple Messages
    
    @Test("Multiple log calls accumulate entries in order")
    func multipleEntries() {
        logger.info("first")
        logger.warning("second")
        logger.error("third")
        
        #expect(logger.entries.count == 3)
        #expect(logger.entries[0].message == "first")
        #expect(logger.entries[1].message == "second")
        #expect(logger.entries[2].message == "third")
    }
}
