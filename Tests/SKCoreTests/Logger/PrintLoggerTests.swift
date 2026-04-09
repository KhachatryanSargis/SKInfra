import Testing
import Foundation
@testable import SKCore

@Suite("PrintLogger")
struct PrintLoggerTests {

    // MARK: - Initialization

    @Test("Default minimumLevel is debug")
    func defaultMinimumLevel() {
        let logger = PrintLogger()
        #expect(logger.minimumLevel == .debug)
    }

    @Test("Custom minimumLevel is stored")
    func customMinimumLevel() {
        let logger = PrintLogger(minimumLevel: .warning)
        #expect(logger.minimumLevel == .warning)
    }

    // MARK: - Sendable Conformance

    @Test("PrintLogger can be sent across isolation boundaries")
    func sendableConformance() async {
        let logger = PrintLogger(minimumLevel: .info)

        // Verify the logger can cross a Task boundary without issues
        let level = await Task.detached {
            logger.minimumLevel
        }.value

        #expect(level == .info)
    }

    // MARK: - LoggerProtocol Conformance

    @Test("PrintLogger conforms to LoggerProtocol")
    func protocolConformance() {
        let logger: any LoggerProtocol = PrintLogger()
        #expect(logger.minimumLevel == .debug)
    }
}
