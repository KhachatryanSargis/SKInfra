import Foundation
import SKCore

// MARK: - Mock Clock

/// Virtual-time ``ClockProtocol`` for deterministic tests.
///
/// `MockClock` never consults the real OS clock. Wall-clock and monotonic
/// time are independent counters that advance only when a test calls
/// ``advance(by:)`` or ``set(now:)``. Anything that uses the clock — sleeps,
/// timers, debounces — is therefore fully under the test's control.
///
/// ```swift
/// let clock = MockClock()
/// let service = ReminderService(clock: clock)
///
/// async let result = service.scheduleReminderIn(.seconds(10))
/// await clock.advance(by: .seconds(10))
/// #expect(try await result == .fired)
/// ```
///
/// ## Wall vs. monotonic time
///
/// ``now()`` (wall clock) and ``uptime()`` (monotonic) advance together by
/// default. ``set(now:)`` lets a test simulate a wall-clock jump without
/// touching monotonic time — useful for verifying that retry/debounce code
/// does not rely on ``now()``.
///
/// ## Thread Safety
///
/// All state is guarded by an `NSLock`. Marked `@unchecked Sendable`
/// because the lock guarantees exclusive access — the compiler cannot
/// verify lock-based safety statically.
public final class MockClock: ClockProtocol, @unchecked Sendable {
    // MARK: - State

    private let lock = NSLock()
    private var virtualNow: Date
    private var virtualUptime: Duration
    private var pending: [PendingItem] = []
    private var nextID: UInt64 = 0

    /// A scheduled sleep wakeup or delayed work item.
    private final class PendingItem {
        let id: UInt64
        let fireAt: Duration
        var continuation: CheckedContinuation<Void, Error>?
        let work: (@Sendable () async -> Void)?
        var isCancelled: Bool

        init(
            id: UInt64,
            fireAt: Duration,
            continuation: CheckedContinuation<Void, Error>?,
            work: (@Sendable () async -> Void)?
        ) {
            self.id = id
            self.fireAt = fireAt
            self.continuation = continuation
            self.work = work
            self.isCancelled = false
        }
    }

    // MARK: - Init

    /// Creates a mock clock with explicit start times.
    ///
    /// - Parameters:
    ///   - startDate: The initial wall-clock value returned by ``now()``.
    ///     Defaults to the Unix epoch so test expectations stay stable
    ///     across machines.
    ///   - startUptime: The initial monotonic value returned by
    ///     ``uptime()``. Defaults to `.zero`.
    public init(
        startDate: Date = Date(timeIntervalSince1970: 0),
        startUptime: Duration = .zero
    ) {
        self.virtualNow = startDate
        self.virtualUptime = startUptime
    }

    // MARK: - ClockProtocol

    public func now() -> Date {
        lock.withLock { virtualNow }
    }

    public func uptime() -> Duration {
        lock.withLock { virtualUptime }
    }

    public func sleep(for duration: Duration) async throws {
        let id = nextItemID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                // Append the pending item with the continuation already
                // installed, atomically under the lock. This prevents any
                // concurrent advance(by:) from draining the item before its
                // continuation is set.
                lock.withLock {
                    let target = virtualUptime + duration
                    pending.append(PendingItem(
                        id: id,
                        fireAt: target,
                        continuation: cont,
                        work: nil
                    ))
                }
            }
        } onCancel: { [weak self] in
            self?.cancel(id: id, throwing: true)
        }
    }

    @discardableResult
    public func schedule(
        after delay: Duration,
        _ work: @escaping @Sendable () async -> Void
    ) -> ScheduledHandle {
        let id = nextItemID()
        lock.withLock {
            let target = virtualUptime + delay
            pending.append(PendingItem(
                id: id,
                fireAt: target,
                continuation: nil,
                work: work
            ))
        }
        return ScheduledHandle(
            isCancelled: { [weak self] in
                self?.isCancelled(id: id) ?? true
            },
            cancel: { [weak self] in
                self?.cancel(id: id, throwing: false)
            }
        )
    }

    // MARK: - Time Control

    /// Advances virtual time by `duration` and fires every pending item
    /// whose deadline now falls in the past.
    ///
    /// Items fire in `fireAt` order. If a fired item itself schedules new
    /// zero-delay work, that work also fires before this call returns.
    ///
    /// - Parameter duration: How far to advance virtual time. Must be
    ///   non-negative.
    public func advance(by duration: Duration) async {
        lock.withLock {
            virtualUptime += duration
            virtualNow = virtualNow.addingTimeInterval(Self.seconds(in: duration))
        }
        await drain()
    }

    /// Overrides the wall-clock value returned by ``now()`` without
    /// touching monotonic time.
    ///
    /// Useful for simulating a system-clock change. Pending sleeps and
    /// scheduled work are unaffected — they are keyed off ``uptime()``.
    public func set(now: Date) {
        lock.withLock { virtualNow = now }
    }

    /// Whether any sleeps or scheduled work are still pending.
    public var hasPendingWork: Bool {
        lock.withLock { pending.contains { !$0.isCancelled } }
    }

    // MARK: - Private

    private func nextItemID() -> UInt64 {
        lock.withLock {
            let id = nextID
            nextID += 1
            return id
        }
    }

    private func isCancelled(id: UInt64) -> Bool {
        lock.withLock {
            // If the item is no longer in `pending`, it either fired or was
            // explicitly cancelled and reaped — treat as cancelled either
            // way is misleading. The handle contract is "have we been told
            // to cancel?", so absence means "no, but no longer cancellable".
            // We report `isCancelled` only when the entry is still present
            // and marked.
            pending.first { $0.id == id }?.isCancelled ?? false
        }
    }

    private func cancel(id: UInt64, throwing: Bool) {
        let continuation: CheckedContinuation<Void, Error>? = lock.withLock {
            let match = pending.first { $0.id == id }
            guard let item = match else {
                return nil
            }
            item.isCancelled = true
            let cont = item.continuation
            item.continuation = nil
            return cont
        }
        if let continuation, throwing {
            continuation.resume(throwing: CancellationError())
        }
    }

    /// Drains every pending item whose `fireAt` is `<=` current uptime,
    /// in `fireAt` order. Re-runs until no more items are due.
    private func drain() async {
        while true {
            let next: PendingItem? = lock.withLock {
                pending.removeAll { $0.isCancelled }
                let due = pending
                    .enumerated()
                    .filter { $0.element.fireAt <= virtualUptime }
                    .min { $0.element.fireAt < $1.element.fireAt }
                guard let due else { return nil }
                return pending.remove(at: due.offset)
            }
            guard let item = next else { return }
            if let cont = item.continuation {
                cont.resume()
            } else if let work = item.work {
                await work()
            }
        }
    }

    /// Converts a `Duration` to fractional seconds.
    private static func seconds(in duration: Duration) -> TimeInterval {
        let components = duration.components
        let whole = TimeInterval(components.seconds)
        let fraction = TimeInterval(components.attoseconds) / 1e18
        return whole + fraction
    }
}
