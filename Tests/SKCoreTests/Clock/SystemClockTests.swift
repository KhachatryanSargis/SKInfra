import Testing
import Foundation
@testable import SKCore

@Suite("SystemClock")
struct SystemClockTests {

    // MARK: - Wall Clock

    @Test("now() returns a time close to Date()")
    func nowReturnsCurrentTime() {
        let clock = SystemClock()
        let before = Date()
        let observed = clock.now()
        let after = Date()
        #expect(observed >= before.addingTimeInterval(-0.5))
        #expect(observed <= after.addingTimeInterval(0.5))
    }

    // MARK: - Monotonic Clock

    @Test("uptime() is non-decreasing across consecutive calls")
    func uptimeMonotonic() {
        let clock = SystemClock()
        let first = clock.uptime()
        let second = clock.uptime()
        #expect(second >= first)
    }

    // MARK: - Sleep

    @Test("sleep(for:) suspends for approximately the requested duration")
    func sleepWaits() async throws {
        let clock = SystemClock()
        let start = clock.uptime()
        try await clock.sleep(for: .milliseconds(50))
        let elapsed = clock.uptime() - start
        // Allow generous tolerance for CI jitter; just check we slept at all.
        #expect(elapsed >= .milliseconds(40))
    }

    @Test("sleep(for:) throws CancellationError when the task is cancelled")
    func sleepCancellation() async {
        let clock = SystemClock()
        let task = Task {
            try await clock.sleep(for: .seconds(60))
        }
        task.cancel()
        let result = await task.result
        switch result {
        case .success:
            Issue.record("Expected sleep to throw on cancellation")
        case .failure(let error):
            #expect(error is CancellationError)
        }
    }

    // MARK: - Schedule

    @Test("schedule(after:) fires the work after the delay")
    func scheduleFires() async throws {
        let clock = SystemClock()
        let signal = AsyncSignal()
        clock.schedule(after: .milliseconds(30)) {
            await signal.fire()
        }
        try await withTimeout(seconds: 2) {
            await signal.wait()
        }
    }

    @Test("schedule(after:) handle reports cancellation and skips work")
    func scheduleCancellation() async throws {
        let clock = SystemClock()
        let signal = AsyncSignal()
        let handle = clock.schedule(after: .milliseconds(50)) {
            await signal.fire()
        }
        handle.cancel()
        #expect(handle.isCancelled)
        // Wait past the original delay to confirm the work never ran.
        try await clock.sleep(for: .milliseconds(120))
        #expect(await signal.fired == false)
    }

    // MARK: - Measure

    @Test("measure(_:) returns the elapsed duration")
    func measureReturnsElapsed() async throws {
        let clock = SystemClock()
        let (value, elapsed) = try await clock.measure {
            try await clock.sleep(for: .milliseconds(20))
            return 42
        }
        #expect(value == 42)
        #expect(elapsed >= .milliseconds(15))
    }
}

// MARK: - Test Helpers

private actor AsyncSignal {
    private(set) var fired = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func fire() {
        fired = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }

    func wait() async {
        if fired { return }
        await withCheckedContinuation { cont in
            waiters.append(cont)
        }
    }
}

private struct TimeoutError: Error {}

private func withTimeout<T: Sendable>(
    seconds: Double,
    _ work: @escaping @Sendable () async -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            await work()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError()
        }
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}
