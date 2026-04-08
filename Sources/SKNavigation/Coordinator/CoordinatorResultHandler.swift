import Foundation
import SKCore

// MARK: - Coordinator Result Handler

/// Manages the async lifecycle of a coordinator's result.
///
/// This is a composable helper that uses `CheckedContinuation` to bridge
/// between SwiftUI's event-driven world and Swift's structured concurrency.
/// A parent coordinator calls ``awaitResult()`` which suspends until the
/// child coordinator calls ``finish(with:)`` or ``cancel()``.
///
/// ## Cancellation Support
///
/// If the parent `Task` is cancelled while awaiting a result, the handler
/// automatically resumes with `.cancelled`. This prevents zombie tasks
/// and integrates with Swift's cooperative cancellation model.
///
/// - Important: Each instance supports exactly one await/resume cycle.
///   Create a new handler for each coordinator start.
@MainActor
public final class CoordinatorResultHandler<Output: Sendable> {

    // MARK: - State

    private var continuation: CheckedContinuation<CoordinatorResult<Output>, Never>?
    private var hasResumed = false

    private let logger: any LoggerProtocol

    // MARK: - Lifecycle

    public init(
        logger: any LoggerProtocol = OSLogLogger(subsystem: "SKNavigation", category: "ResultHandler")
    ) {
        self.logger = logger
    }

    deinit {
        if !hasResumed, continuation != nil {
            logger.warning("CoordinatorResultHandler deallocated without resuming — auto-cancelling to prevent continuation leak.")
            // Safety net: resume with .cancelled to prevent a permanently
            // suspended task. A CheckedContinuation that is never resumed
            // is a memory leak and will trap in debug builds.
            hasResumed = true
            continuation?.resume(returning: .cancelled)
            continuation = nil
        }
    }

    // MARK: - Await

    /// Suspends the calling task until the coordinator produces a result.
    ///
    /// If the parent `Task` is cancelled before the coordinator finishes,
    /// this method automatically resumes with `.cancelled`.
    ///
    /// - Parameter onReady: An optional closure invoked synchronously after the
    ///   continuation is stored but before the task suspends. Use this in tests
    ///   to call ``finish(with:)`` or ``cancel()`` with guaranteed ordering —
    ///   no timing dependencies, no flakiness.
    /// - Returns: The coordinator's result.
    public func awaitResult(
        onReady: (() -> Void)? = nil
    ) async -> CoordinatorResult<Output> {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                self.hasResumed = false
                onReady?()
            }
        } onCancel: {
            // Task was cancelled — resume with .cancelled from any isolation.
            // MainActor.assumeIsolated is safe here because TabRouter/NavigationRouter
            // are MainActor-isolated and this handler is always used on MainActor.
            Task { @MainActor [weak self] in
                self?.resume(with: .cancelled)
            }
        }
    }

    // MARK: - Resume

    /// Completes the coordinator's flow with a successful output.
    ///
    /// - Parameter output: The result value to deliver to the parent.
    public func finish(with output: Output) {
        resume(with: .finished(output))
    }

    /// Completes the coordinator's flow as cancelled.
    public func cancel() {
        resume(with: .cancelled)
    }

    // MARK: - Private

    private func resume(with result: CoordinatorResult<Output>) {
        guard let continuation, !hasResumed else {
            logger.warning("Attempted to resume an already-resumed or uninitialized result handler.")
            return
        }
        hasResumed = true
        self.continuation = nil
        continuation.resume(returning: result)
    }
}
