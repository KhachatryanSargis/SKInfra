import Foundation

// MARK: - System Clock

/// Production ``ClockProtocol`` backed by the real operating-system clock.
///
/// All time comes from Foundation primitives:
///
/// - ``now()`` returns `Date()`.
/// - ``uptime()`` is derived from `ProcessInfo.processInfo.systemUptime`,
///   which counts seconds since the device was booted and is unaffected by
///   wall-clock changes.
/// - ``sleep(for:)`` delegates to `Task.sleep(for:)`.
/// - ``schedule(after:_:)`` spawns a child `Task` that sleeps for the
///   delay and then invokes the supplied closure.
///
/// ## Thread Safety
///
/// `SystemClock` is a value type with no mutable state, making it
/// inherently `Sendable`. It is cheap to construct and copy — feel free to
/// pass it by value or register it as a singleton in the DI container.
///
/// ## Usage
///
/// ```swift
/// container.register(ClockProtocol.self, scope: .singleton) {
///     SystemClock()
/// }
///
/// // Elsewhere:
/// let clock = container.resolve(ClockProtocol.self)
/// try await clock.sleep(for: .milliseconds(250))
/// ```
public struct SystemClock: ClockProtocol {
    /// Creates a system clock.
    public init() {}

    public func now() -> Date {
        Date()
    }

    public func uptime() -> Duration {
        // `systemUptime` is `TimeInterval` (seconds, as `Double`).
        // Convert via fractional seconds — `.seconds(Double)` is supported.
        .seconds(ProcessInfo.processInfo.systemUptime)
    }

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }

    @discardableResult
    public func schedule(
        after delay: Duration,
        _ work: @escaping @Sendable () async -> Void
    ) -> ScheduledHandle {
        let task = Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await work()
        }
        return ScheduledHandle(
            isCancelled: { task.isCancelled },
            cancel: { task.cancel() }
        )
    }
}
