import Foundation

// MARK: - Logger Protocol

/// Type-safe, protocol-oriented logging interface.
///
/// Defines a single core requirement — ``log(_:level:file:function:line:)`` —
/// while protocol extensions provide convenient per-level methods.
/// This design demonstrates several POP principles:
///
/// - **Single requirement** in the protocol; all convenience is in extensions
/// - **Default implementations** for `debug`, `info`, `warning`, `error`, `fatal`
/// - **Protocol composition** with `Sendable` for safe cross-isolation use
/// - **Static dispatch** when used as `some LoggerProtocol` in generics
/// - **Dynamic dispatch** when used as `any LoggerProtocol` for runtime flexibility
///
/// ## Usage
///
/// ```swift
/// func bootstrap(logger: some LoggerProtocol) {
///     logger.info("App launched")
///     logger.debug("Configuration loaded", file: #file)
/// }
/// ```
///
/// ## Implementing a Custom Logger
///
/// Only the `log` method needs implementation:
///
/// ```swift
/// struct ConsoleLogger: LoggerProtocol {
///     let minimumLevel: LogLevel
///
///     func log(_ message: @autoclosure () -> String,
///              level: LogLevel, file: String, function: String, line: Int) {
///         guard level >= minimumLevel else { return }
///         print("[\(level)] \(message())")
///     }
/// }
/// ```
public protocol LoggerProtocol: Sendable {
    /// The minimum severity level this logger will emit.
    ///
    /// Messages below this level are silently discarded.
    /// Default implementations check this before evaluating the message closure.
    var minimumLevel: LogLevel { get }

    /// Core logging method. All convenience methods funnel through here.
    ///
    /// - Parameters:
    ///   - message: An autoclosure that produces the log message.
    ///              Only evaluated if the level passes the filter — avoiding
    ///              string interpolation overhead for suppressed messages.
    ///   - level: The severity of this log message.
    ///   - file: The source file (defaults to `#file`).
    ///   - function: The calling function (defaults to `#function`).
    ///   - line: The source line (defaults to `#line`).
    func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Convenience Methods (Default Implementations)

/// Per-level convenience methods provided via protocol extension.
///
/// These demonstrate the POP "customization point" pattern:
/// - `log(_:level:file:function:line:)` is the single customization point
///   declared in the protocol (dynamic dispatch via witness table).
/// - `debug`, `info`, `warning`, `error`, `fatal` are extension-only
///   convenience methods that delegate to the customization point.
///
/// Conforming types override `log(...)` to control *all* output.
/// They should NOT need to override the convenience methods.
public extension LoggerProtocol {
    /// Log a debug-level message.
    func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .debug, file: file, function: function, line: line)
    }

    /// Log an info-level message.
    func info(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .info, file: file, function: function, line: line)
    }

    /// Log a warning-level message.
    func warning(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .warning, file: file, function: function, line: line)
    }

    /// Log an error-level message.
    func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .error, file: file, function: function, line: line)
    }

    /// Log a fatal-level message.
    func fatal(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .fatal, file: file, function: function, line: line)
    }
}
