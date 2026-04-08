import Foundation

// MARK: - Coordinator Result

/// The outcome of a coordinator's flow.
///
/// When a child coordinator finishes, it returns a typed result to its parent.
/// This enables type-safe, async communication between coordinators without
/// delegate protocols or callback closures.
public enum CoordinatorResult<Output: Sendable>: Sendable {

    /// The flow completed successfully with a typed output.
    case finished(Output)

    /// The flow was cancelled by the user or programmatically.
    case cancelled
}

// MARK: - Convenience

extension CoordinatorResult {

    /// Returns the output if the result is `.finished`, otherwise `nil`.
    public var output: Output? {
        if case .finished(let value) = self { return value }
        return nil
    }

    /// Whether the coordinator finished successfully.
    public var isFinished: Bool {
        if case .finished = self { return true }
        return false
    }

    /// Whether the coordinator was cancelled.
    public var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }
}

// MARK: - Void Output Convenience

/// Convenience for coordinators that don't produce meaningful output.
extension CoordinatorResult where Output == Void {

    /// A finished result with no output.
    public static var finished: CoordinatorResult { .finished(()) }
}
