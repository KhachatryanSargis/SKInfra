import Foundation

// MARK: - Clock Protocol

/// An abstraction over wall-clock and monotonic time, sleep, and delayed work.
///
/// `ClockProtocol` is the single time-related customization point used by every
/// other SKInfra product. Feature code depends on this protocol rather than
/// `Date()` or `Task.sleep` directly, so tests can swap in
/// ``MockClock`` (from `SKInfraTesting`) for fully deterministic virtual time.
///
/// The protocol exposes two distinct notions of "time":
///
/// - ``now()`` returns the current wall-clock ``Date``. It can jump
///   forward or backward when the user changes their system clock.
/// - ``uptime()`` returns a monotonic ``Duration`` that only ever moves
///   forward. Use it for elapsed-time measurements, debounce logic, or
///   anything that should ignore wall-clock changes.
///
/// ## Conformance
///
/// Only ``now()``, ``uptime()``, ``sleep(for:)`` and
/// ``schedule(after:_:)`` need to be implemented; ``measure(_:)`` has a
/// default implementation that subtracts two ``uptime()`` samples.
///
/// ## Usage
///
/// ```swift
/// func waitAndPing(_ clock: some ClockProtocol) async throws {
///     try await clock.sleep(for: .seconds(1))
///     print("Ping at \(clock.now())")
/// }
///
/// // Production
/// try await waitAndPing(SystemClock())
///
/// // Tests
/// let mock = MockClock()
/// async let pinged: Void = waitAndPing(mock)
/// await mock.advance(by: .seconds(1))
/// _ = try await pinged
/// ```
public protocol ClockProtocol: Sendable {
    /// The current wall-clock time.
    ///
    /// May jump forward or backward if the system clock changes. Use
    /// ``uptime()`` instead when measuring elapsed time.
    func now() -> Date

    /// Monotonic time since an unspecified reference point.
    ///
    /// Unaffected by wall-clock changes. Two samples taken in the same
    /// process are guaranteed to be ordered: the later sample is always
    /// greater than or equal to the earlier one.
    func uptime() -> Duration

    /// Suspends the current task for the given duration.
    ///
    /// Cooperatively cancellable: throws ``CancellationError`` if the
    /// enclosing task is cancelled before the duration elapses.
    ///
    /// - Parameter duration: How long to sleep.
    func sleep(for duration: Duration) async throws

    /// Schedules `work` to run after `delay`.
    ///
    /// The returned ``ScheduledHandle`` can be used to cancel the work
    /// before it fires. Once the work begins executing it cannot be
    /// cancelled through the handle — wrap it in a cancellable `Task` if
    /// you need that behavior.
    ///
    /// - Parameters:
    ///   - delay: How long to wait before running `work`.
    ///   - work: The closure to execute after the delay.
    /// - Returns: A handle that can cancel the pending work.
    @discardableResult
    func schedule(
        after delay: Duration,
        _ work: @escaping @Sendable () async -> Void
    ) -> ScheduledHandle
}

// MARK: - Measure (Default Implementation)

/// Default `measure` based on ``ClockProtocol/uptime()``.
public extension ClockProtocol {
    /// Runs `work` and returns its result together with the monotonic time
    /// that elapsed.
    ///
    /// Uses ``ClockProtocol/uptime()`` so the measurement is immune to
    /// wall-clock changes.
    ///
    /// - Parameter work: An async closure to time.
    /// - Returns: A tuple containing the closure's result and the elapsed
    ///   ``Duration``.
    func measure<T>(
        _ work: () async throws -> T
    ) async rethrows -> (result: T, elapsed: Duration) {
        let start = uptime()
        let value = try await work()
        return (value, uptime() - start)
    }
}
