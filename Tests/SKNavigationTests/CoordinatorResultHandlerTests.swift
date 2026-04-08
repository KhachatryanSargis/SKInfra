import Testing
@testable import SKNavigation

@Suite("CoordinatorResultHandler")
@MainActor
struct CoordinatorResultHandlerTests {

    // MARK: - Finish

    @Test("Finish returns finished result")
    func finishReturnsFinishedResult() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.finish(with: .completed(id: "abc"))
        }

        #expect(result.output == .completed(id: "abc"))
        #expect(result.isFinished)
    }

    @Test("Finish with different outputs")
    func finishWithDifferentOutputs() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.finish(with: .saved)
        }

        #expect(result.output == .saved)
    }

    // MARK: - Cancel

    @Test("Cancel returns cancelled result")
    func cancelReturnsCancelledResult() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.cancel()
        }

        #expect(result.isCancelled)
        #expect(result.output == nil)
    }

    // MARK: - Void Output

    @Test("Void handler finish")
    func voidHandlerFinish() async {
        let handler = CoordinatorResultHandler<Void>()

        let result = await handler.awaitResult {
            handler.finish(with: ())
        }

        #expect(result.isFinished)
    }

    @Test("Void handler cancel")
    func voidHandlerCancel() async {
        let handler = CoordinatorResultHandler<Void>()

        let result = await handler.awaitResult {
            handler.cancel()
        }

        #expect(result.isCancelled)
    }

    // MARK: - String Output

    @Test("String output handler")
    func stringOutputHandler() async {
        let handler = CoordinatorResultHandler<String>()

        let result = await handler.awaitResult {
            handler.finish(with: "group-123")
        }

        #expect(result.output == "group-123")
    }

    // MARK: - Double Resume Safety

    @Test("Double finish does not crash")
    func doubleFinishDoesNotCrash() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.finish(with: .saved)
            handler.finish(with: .completed(id: "xyz"))
        }

        // First finish wins
        #expect(result.output == .saved)
    }

    @Test("Finish then cancel does not crash")
    func finishThenCancelDoesNotCrash() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.finish(with: .saved)
            handler.cancel()
        }

        #expect(result.isFinished)
        #expect(result.output == .saved)
    }

    @Test("Cancel then finish does not crash")
    func cancelThenFinishDoesNotCrash() async {
        let handler = CoordinatorResultHandler<TestOutput>()

        let result = await handler.awaitResult {
            handler.cancel()
            handler.finish(with: .saved)
        }

        #expect(result.isCancelled)
    }

    // MARK: - onReady Guarantees

    @Test("onReady is called synchronously")
    func onReadyIsCalledSynchronously() async {
        let handler = CoordinatorResultHandler<TestOutput>()
        var onReadyCalled = false

        _ = await handler.awaitResult {
            onReadyCalled = true
            handler.finish(with: .saved)
        }

        #expect(onReadyCalled)
    }

    @Test("awaitResult without onReady")
    func awaitResultWithoutOnReady() async {
        let handler = CoordinatorResultHandler<String>()

        Task { @MainActor in
            handler.finish(with: "done")
        }

        let result = await handler.awaitResult()
        #expect(result.output == "done")
    }
}
