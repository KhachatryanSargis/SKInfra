import Testing
import Foundation
@testable import SKCore
@testable import SKAnalytics

@Suite("PrintAnalyticsProvider")
struct PrintAnalyticsProviderTests {

    // MARK: - Enabled State

    @Test("Default provider is enabled")
    func defaultEnabled() {
        let provider = PrintAnalyticsProvider()
        #expect(provider.isEnabled)
    }

    @Test("Provider can be created disabled")
    func createDisabled() {
        let provider = PrintAnalyticsProvider(isEnabled: false)
        #expect(!provider.isEnabled)
    }

    // MARK: - Sendable Conformance

    @Test("PrintAnalyticsProvider can be used across isolation boundaries")
    func sendableConformance() async {
        let provider = PrintAnalyticsProvider()

        await Task.detached {
            provider.track("from detached task")
        }.value

        // If this compiles and runs without error, Sendable conformance works.
        #expect(provider.isEnabled)
    }

    // MARK: - Convenience Methods

    @Test("Track without properties uses nil")
    func trackWithoutProperties() {
        // Verifies the protocol extension convenience method compiles and works.
        let provider = PrintAnalyticsProvider()
        provider.track("simple_event")
        // No crash = success (print output not captured in tests)
    }

    @Test("Screen without properties uses nil")
    func screenWithoutProperties() {
        let provider = PrintAnalyticsProvider()
        provider.screen("HomeScreen")
        // No crash = success
    }
}
