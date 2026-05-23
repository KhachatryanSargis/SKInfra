import Foundation

// MARK: - Scheduled Handle

/// An opaque handle representing work scheduled via
/// ``ClockProtocol/schedule(after:_:)``.
///
/// The handle exposes two operations:
///
/// - ``cancel()`` requests that the pending work be cancelled.
/// - ``isCancelled`` reports whether the work has been cancelled.
///
/// Once the scheduled work begins executing, cancelling the handle has no
/// effect on the in-flight closure. If you need to interrupt running work,
/// schedule it inside a `Task` and cancel that `Task` from within the
/// closure.
///
/// ## Thread Safety
///
/// `ScheduledHandle` is `Sendable`. The closures supplied at construction
/// time must themselves be safe to invoke from any concurrency domain — both
/// ``SystemClock`` (Task-backed) and `MockClock` (lock-backed virtual time)
/// satisfy this.
public final class ScheduledHandle: Sendable {
    private let _isCancelled: @Sendable () -> Bool
    private let _cancel: @Sendable () -> Void

    /// Creates a handle from explicit closures.
    ///
    /// Typically constructed only by ``ClockProtocol`` implementations.
    ///
    /// - Parameters:
    ///   - isCancelled: A closure that returns whether the underlying work
    ///     has been cancelled.
    ///   - cancel: A closure that cancels the underlying work.
    public init(
        isCancelled: @escaping @Sendable () -> Bool,
        cancel: @escaping @Sendable () -> Void
    ) {
        self._isCancelled = isCancelled
        self._cancel = cancel
    }

    /// Whether the scheduled work has been cancelled.
    public var isCancelled: Bool {
        _isCancelled()
    }

    /// Cancels the scheduled work if it has not started yet.
    ///
    /// Safe to call multiple times. Calling on an already-fired handle is a
    /// no-op.
    public func cancel() {
        _cancel()
    }
}
