import Foundation
import SKCore

// MARK: - Print Analytics Provider

/// A simple analytics provider that writes formatted events to standard output.
///
/// Useful for development, debugging, and unit tests. For production analytics
/// with vendor-backed tracking, implement ``AnalyticsProtocol`` with your
/// preferred SDK (Mixpanel, Amplitude, Firebase, etc.) at the application layer.
///
/// ## Thread Safety
///
/// `PrintAnalyticsProvider` is a value type (`struct`) with no mutable state,
/// making it inherently `Sendable`. The `print()` function itself is thread-safe.
///
/// ## Usage
///
/// ```swift
/// let analytics = PrintAnalyticsProvider()
/// analytics.track("app_launched", properties: ["source": "deeplink"])
/// // 📊 [TRACK] app_launched [source: "deeplink"]
///
/// analytics.screen("HomeScreen")
/// // 📊 [SCREEN] HomeScreen
/// ```
public struct PrintAnalyticsProvider: AnalyticsProtocol {
    public let isEnabled: Bool

    /// Creates a print analytics provider.
    ///
    /// - Parameter isEnabled: Whether events should be printed. Defaults to `true`.
    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func track(_ event: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        let entry = AnalyticsEvent(name: event, properties: properties)
        print("📊 [TRACK] \(entry.name)\(formattedProperties(properties))")
    }

    public func identify(userId: String) {
        guard isEnabled else { return }
        print("📊 [IDENTIFY] \(userId)")
    }

    public func setUserProperties(_ properties: AnalyticsProperties) {
        guard isEnabled else { return }
        print("📊 [USER PROPERTIES] \(properties)")
    }

    public func screen(_ name: String, properties: AnalyticsProperties?) {
        guard isEnabled else { return }
        print("📊 [SCREEN] \(name)\(formattedProperties(properties))")
    }

    public func reset() {
        guard isEnabled else { return }
        print("📊 [RESET]")
    }

    // MARK: - Private

    private func formattedProperties(_ properties: AnalyticsProperties?) -> String {
        guard let properties, !properties.isEmpty else { return "" }
        return " \(properties)"
    }
}
