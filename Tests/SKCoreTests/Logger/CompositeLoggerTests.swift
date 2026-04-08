import Testing
import Foundation
@testable import SKCore

@Suite("CompositeLogger")
struct CompositeLoggerTests {
    
    // MARK: - Forwarding
    
    @Test("Forwards messages to all child loggers")
    func forwardsToAll() {
        let logger1 = MockLogger()
        let logger2 = MockLogger()
        let composite = CompositeLogger(loggers: [logger1, logger2])
        
        composite.info("broadcast")
        
        #expect(logger1.entries.count == 1)
        #expect(logger1.entries[0].message == "broadcast")
        #expect(logger2.entries.count == 1)
        #expect(logger2.entries[0].message == "broadcast")
    }
    
    // MARK: - Per-Child Filtering
    
    @Test("Each child applies its own minimum level filter")
    func perChildFiltering() {
        let debugLogger = MockLogger(minimumLevel: .debug)
        let errorLogger = MockLogger(minimumLevel: .error)
        let composite = CompositeLogger(loggers: [debugLogger, errorLogger])
        
        composite.debug("only debug sees this")
        composite.error("both see this")
        
        #expect(debugLogger.entries.count == 2)
        #expect(errorLogger.entries.count == 1)
        #expect(errorLogger.entries[0].message == "both see this")
    }
    
    // MARK: - Minimum Level Computation
    
    @Test("Composite minimumLevel is the lowest among children")
    func minimumLevelIsLowest() {
        let composite = CompositeLogger(loggers: [
            MockLogger(minimumLevel: .warning),
            MockLogger(minimumLevel: .debug),
            MockLogger(minimumLevel: .error)
        ])
        
        #expect(composite.minimumLevel == .debug)
    }
    
    @Test("Empty composite defaults to debug")
    func emptyCompositeDefaultsToDebug() {
        let composite = CompositeLogger(loggers: [])
        #expect(composite.minimumLevel == .debug)
    }
    
    // MARK: - Message Evaluation
    
    @Test("Message is evaluated only once across multiple children")
    func messageEvaluatedOnce() {
        var evaluationCount = 0
        let logger1 = MockLogger()
        let logger2 = MockLogger()
        let composite = CompositeLogger(loggers: [logger1, logger2])
        
        composite.info({
            evaluationCount += 1
            return "evaluated"
        }())
        
        // The message autoclosure is evaluated once in the composite,
        // then the resulting string is forwarded to each child.
        #expect(evaluationCount == 1)
        #expect(logger1.entries[0].message == "evaluated")
        #expect(logger2.entries[0].message == "evaluated")
    }
    
    // MARK: - Pre-filter Optimization
    
    @Test("Messages below composite minimumLevel skip iteration entirely")
    func preFilterSkipsIteration() {
        let warningLogger = MockLogger(minimumLevel: .warning)
        let errorLogger = MockLogger(minimumLevel: .error)
        let composite = CompositeLogger(loggers: [warningLogger, errorLogger])
        
        // composite.minimumLevel == .warning
        // debug is below .warning, so it's pre-filtered
        composite.debug("should be pre-filtered")
        
        #expect(warningLogger.entries.isEmpty)
        #expect(errorLogger.entries.isEmpty)
    }
    
    // MARK: - Sendable Conformance
    
    @Test("CompositeLogger can be used across isolation boundaries")
    func sendableConformance() async {
        let mock = MockLogger()
        let composite = CompositeLogger(loggers: [mock])
        
        await Task.detached {
            composite.info("from detached task")
        }.value
        
        #expect(mock.entries.count == 1)
    }
    
    // MARK: - Metadata Preservation
    
    @Test("Call-site metadata is preserved through forwarding")
    func metadataPreservation() {
        let mock = MockLogger()
        let composite = CompositeLogger(loggers: [mock])
        
        let expectedLine = #line + 1
        composite.error("with metadata")
        
        let entry = mock.entries[0]
        #expect(entry.file.contains("CompositeLoggerTests.swift"))
        #expect(entry.line == expectedLine)
    }
}
