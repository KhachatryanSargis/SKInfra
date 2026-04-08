import Foundation
import OSLog

// MARK: - Log Privacy Level

/// Controls the privacy level of log messages in the unified logging system.
///
/// Maps to `OSLogPrivacy` when used with ``OSLogLogger``. Use `.auto` (default)
/// to let the system redact dynamic content in non-debug builds, or `.public`
/// to make all messages visible in Console.app and `log stream`.
///
/// - Important: Using `.public` will expose all log message content in system
///   logs, including potentially sensitive data (tokens, PII, etc.). Use with
///   caution in production builds.
public enum LogPrivacy: Sendable {
    /// The system's default privacy behavior. Dynamic values are redacted
    /// in non-debug builds. This is the recommended setting for production.
    case auto

    /// All message content is visible in Console.app and `log stream`,
    /// even in release builds. Useful for development and debugging,
    /// but risks exposing sensitive data in production logs.
    case `public`

    /// All dynamic content is redacted, even in debug builds.
    /// Use for messages that may contain sensitive information.
    case `private`
}

// MARK: - OSLog Logger

/// Production-quality logger backed by Apple's unified logging system (`os.Logger`).
///
/// Maps ``LogLevel`` to `OSLogType` for proper system-level filtering,
/// privacy controls, and performance. Messages below ``minimumLevel``
/// are discarded before reaching `os.Logger`, avoiding unnecessary work.
///
/// ## Privacy
///
/// By default, the logger uses ``LogPrivacy/auto`` which lets the system
/// redact dynamic content in non-debug builds. You can override this with
/// ``LogPrivacy/public`` for development or ``LogPrivacy/private`` for
/// messages containing sensitive data.
///
/// - Important: When using `.public`, all log content is visible in Console.app
///   and `log stream` without redaction. Do not log sensitive data (auth tokens,
///   PII, credentials) with `.public` privacy in production builds.
///
/// ## Thread Safety
///
/// `os.Logger` is documented as thread-safe by Apple. This struct stores it
/// using `nonisolated(unsafe)` because `os.Logger` doesn't formally conform
/// to `Sendable`, but is safe to use from any thread.
///
/// ## Usage
///
/// ```swift
/// // Development: all messages visible
/// let devLogger = OSLogLogger(
///     subsystem: "com.example.myapp",
///     category: "Networking",
///     minimumLevel: .debug,
///     privacy: .public
/// )
///
/// // Production: system-managed redaction (recommended)
/// let prodLogger = OSLogLogger(
///     subsystem: "com.example.myapp",
///     category: "Networking",
///     minimumLevel: .info
/// )
///
/// logger.info("Request started")   // Sent to Console.app / log stream
/// logger.debug("Payload: ...")     // Suppressed (below .info)
/// ```
public struct OSLogLogger: LoggerProtocol {
    /// The minimum severity to emit.
    public let minimumLevel: LogLevel

    /// The privacy level applied to all log messages.
    public let privacy: LogPrivacy

    /// The underlying `os.Logger` instance.
    private let logger: os.Logger

    /// Creates an OSLog-backed logger.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier, typically your bundle ID.
    ///   - category: The category within the subsystem (e.g., "Networking", "Storage").
    ///   - minimumLevel: The minimum severity to emit. Defaults to `.info`.
    ///   - privacy: The privacy level for log messages. Defaults to `.auto`,
    ///     which lets the system redact dynamic content in non-debug builds.
    public init(
        subsystem: String,
        category: String,
        minimumLevel: LogLevel = .info,
        privacy: LogPrivacy = .auto
    ) {
        self.minimumLevel = minimumLevel
        self.privacy = privacy
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }
        let text = message()
        switch (level, privacy) {
        // .public privacy
        case (.debug, .public):
            logger.debug("\(text, privacy: .public)")
        case (.info, .public):
            logger.info("\(text, privacy: .public)")
        case (.warning, .public):
            logger.warning("\(text, privacy: .public)")
        case (.error, .public):
            logger.error("\(text, privacy: .public)")
        case (.fatal, .public):
            logger.critical("\(text, privacy: .public)")
        // .private privacy
        case (.debug, .private):
            logger.debug("\(text, privacy: .private)")
        case (.info, .private):
            logger.info("\(text, privacy: .private)")
        case (.warning, .private):
            logger.warning("\(text, privacy: .private)")
        case (.error, .private):
            logger.error("\(text, privacy: .private)")
        case (.fatal, .private):
            logger.critical("\(text, privacy: .private)")
        // .auto privacy (system default)
        case (.debug, .auto):
            logger.debug("\(text, privacy: .auto)")
        case (.info, .auto):
            logger.info("\(text, privacy: .auto)")
        case (.warning, .auto):
            logger.warning("\(text, privacy: .auto)")
        case (.error, .auto):
            logger.error("\(text, privacy: .auto)")
        case (.fatal, .auto):
            logger.critical("\(text, privacy: .auto)")
        }
    }
}
