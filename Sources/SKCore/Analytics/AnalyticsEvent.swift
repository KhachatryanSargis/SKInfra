import Foundation

// MARK: - Analytics Event

/// An immutable record of a single analytics event.
///
/// Captures the event name, properties, and timestamp at the moment
/// of tracking. Used by ``PrintAnalyticsProvider`` and test helpers
/// to inspect tracked events without coupling to a specific output format.
///
/// Mirrors ``LogEntry`` for consistency across the framework.
public struct AnalyticsEvent: Sendable, Equatable {
    /// The event name (e.g. `"button_tapped"`, `"screen_viewed"`).
    public let name: String

    /// The properties attached to this event.
    public let properties: AnalyticsProperties?

    /// The timestamp when this event was tracked.
    public let timestamp: Date

    /// Creates an analytics event record.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - properties: Optional key-value metadata.
    ///   - timestamp: The time the event was tracked. Defaults to now.
    public init(
        name: String,
        properties: AnalyticsProperties? = nil,
        timestamp: Date = Date()
    ) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

// MARK: - CustomStringConvertible

extension AnalyticsEvent: CustomStringConvertible {
    public var description: String {
        if let properties, !properties.isEmpty {
            return "📊 [\(name)] \(properties)"
        }
        return "📊 [\(name)]"
    }
}
