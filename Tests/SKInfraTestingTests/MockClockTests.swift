import Testing
import Foundation
import SKCore
import SKInfraTesting

@Suite("MockClock")
struct MockClockTests {

    // MARK: - Initial State

    @Test("Default start is Unix epoch and zero uptime")
    func defaultStart() {
        let clock = MockClock()
        #expect(clock.now() == Date(timeIntervalSince1970: 0))
        #expect(clock.uptime() == .zero)
    }

    @Test("Custom start values are honored")
    func customStart() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = MockClock(startDate: date, startUptime: .seconds(42))
        #expect(clock.now() == date)
        #expect(clock.uptime() == .seconds(42))
    }

    // MARK: - advance(by:)

    @Test("advance(by:) advances wall and monotonic time together")
    func advanceMovesBothClocks() async {
        let clock = MockClock()
        await clock.advance(by: .seconds(5))
        #expect(clock.now() == Date(timeIntervalSince1970: 5))
        #expect(clock.uptime() == .seconds(5))
    }

    @Test("set(now:) shifts wall time but leaves monotonic time untouched")
    func setNowDoesNotMoveUptime() async {
        let clock = MockClock()
        await clock.advance(by: .seconds(10))
        clock.set(now: Date(timeIntervalSince1970: 99))
        #expect(clock.now() == Date(timeIntervalSince1970: 99))
        #expect(clock.uptime() == .seconds(10))
    }

    // MARK: - sleep

    @Test("sleep(for:) suspends until advance(by:) reaches the deadline")
    func sleepSuspendsUntilAdvance() async throws {
        let clock = MockClock()
        let signal = SuccessSignal()

        let task = Task {
            try await clock.sleep(for: .seconds(3))
            await signal.fire()
        }

        // Yield so the sleep has a chance to enqueue its continuation.
        await Task.yield()
        #expect(await signal.fired == false)

        await clock.advance(by: .seconds(3))
        try await task.value
        #expect(await signal.fired)
    }

    @Test("Partial advance does not wake the sleeper")
    func partialAdvanceKeepsSleeping() async throws {
        let clock = MockClock()
        let signal = SuccessSignal()

        let task = Task {
            try await clock.sleep(for: .seconds(5))
            await signal.fire()
        }
        await Task.yield()

        await clock.advance(by: .seconds(2))
        #expect(await signal.fired == false)

        await clock.advance(by: .seconds(3))
        try await task.value
        #expect(await signal.fired)
    }

    @Test("Cancelling the surrounding task wakes sleep with CancellationError")
    func sleepCancellationThrows() async {
        let clock = MockClock()
        let task = Task {
            try await clock.sleep(for: .seconds(100))
        }
        await Task.yield()
        task.cancel()
        let result = await task.result
        switch result {
        case .success:
            Issue.record("Expected sleep to throw on cancellation")
        case .failure(let error):
            #expect(error is CancellationError)
        }
    }

    // MARK: - schedule

    @Test("schedule(after:) fires its work when virtual time advances past delay")
    func scheduleFires() async {
        let clock = MockClock()
        let signal = SuccessSignal()
        clock.schedule(after: .seconds(2)) {
            await signal.fire()
        }
        await clock.advance(by: .seconds(2))
        #expect(await signal.fired)
    }

    @Test("schedule(after:) does not fire before the delay elapses")
    func scheduleHoldsUntilDeadline() async {
        let clock = MockClock()
        let signal = SuccessSignal()
        clock.schedule(after: .seconds(4)) {
            await signal.fire()
        }
        await clock.advance(by: .seconds(3))
        #expect(await signal.fired == false)
    }

    @Test("Cancelling a scheduled handle skips the work")
    func scheduleCancellation() async {
        let clock = MockClock()
        let signal = SuccessSignal()
        let handle = clock.schedule(after: .seconds(2)) {
            await signal.fire()
        }
        handle.cancel()
        #expect(handle.isCancelled)
        await clock.advance(by: .seconds(10))
        #expect(await signal.fired == false)
    }

    @Test("Multiple scheduled items fire in fireAt order")
    func ordering() async {
        let clock = MockClock()
        let order = OrderRecorder()
        clock.schedule(after: .seconds(3)) { await order.append("c") }
        clock.schedule(after: .seconds(1)) { await order.append("a") }
        clock.schedule(after: .seconds(2)) { await order.append("b") }
        await clock.advance(by: .seconds(5))
        #expect(await order.values == ["a", "b", "c"])
    }

    @Test("Work scheduled during a drain also fires within the same advance")
    func recursiveScheduling() async {
        let clock = MockClock()
        let order = OrderRecorder()

        clock.schedule(after: .seconds(1)) { [clock] in
            await order.append("outer")
            clock.schedule(after: .zero) {
                await order.append("inner")
            }
        }
        await clock.advance(by: .seconds(1))
        #expect(await order.values == ["outer", "inner"])
    }

    // MARK: - hasPendingWork

    @Test("hasPendingWork reflects scheduled and drained state")
    func hasPendingWorkTracks() async {
        let clock = MockClock()
        #expect(clock.hasPendingWork == false)
        clock.schedule(after: .seconds(1)) { }
        #expect(clock.hasPendingWork)
        await clock.advance(by: .seconds(1))
        #expect(clock.hasPendingWork == false)
    }

    // MARK: - measure

    @Test("measure(_:) returns virtual elapsed duration")
    func measureReturnsVirtualElapsed() async throws {
        let clock = MockClock()
        let task = Task {
            try await clock.measure {
                try await clock.sleep(for: .seconds(7))
                return "ok"
            }
        }
        await Task.yield()
        await clock.advance(by: .seconds(7))
        let (value, elapsed) = try await task.value
        #expect(value == "ok")
        #expect(elapsed == .seconds(7))
    }
}

// MARK: - Test Helpers

private actor SuccessSignal {
    private(set) var fired = false
    func fire() { fired = true }
}

private actor OrderRecorder {
    private(set) var values: [String] = []
    func append(_ value: String) {
        values.append(value)
    }
}
