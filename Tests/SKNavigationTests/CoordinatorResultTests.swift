import Testing
@testable import SKNavigation

@Suite("CoordinatorResult")
struct CoordinatorResultTests {

    // MARK: - Finished

    @Test("Finished result provides output")
    func finishedOutput() {
        let result = CoordinatorResult<TestOutput>.finished(.completed(id: "abc"))
        #expect(result.output == .completed(id: "abc"))
    }

    @Test("Finished result reports isFinished")
    func finishedIsFinished() {
        let result = CoordinatorResult<TestOutput>.finished(.saved)
        #expect(result.isFinished)
        #expect(result.isCancelled == false)
    }

    // MARK: - Cancelled

    @Test("Cancelled result has nil output")
    func cancelledOutputIsNil() {
        let result = CoordinatorResult<TestOutput>.cancelled
        #expect(result.output == nil)
    }

    @Test("Cancelled result reports isCancelled")
    func cancelledIsCancelled() {
        let result = CoordinatorResult<TestOutput>.cancelled
        #expect(result.isCancelled)
        #expect(result.isFinished == false)
    }

    // MARK: - Void Convenience

    @Test("Void finished convenience")
    func voidFinishedConvenience() {
        let result: CoordinatorResult<Void> = .finished
        #expect(result.isFinished)
        #expect(result.isCancelled == false)
    }

    @Test("Void finished output is non-nil")
    func voidFinishedOutputIsNotNil() {
        let result: CoordinatorResult<Void> = .finished
        #expect(result.output != nil)
    }

    // MARK: - Sendable

    @Test("Result is Sendable")
    func resultIsSendable() async {
        let result = CoordinatorResult<String>.finished("test")
        await Task {
            _ = result.output
        }.value
    }
}
