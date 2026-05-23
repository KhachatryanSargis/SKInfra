import Foundation

// MARK: - Paywall Experiment

/// Metadata about a paywall A/B test variant.
///
/// RevenueCat Experiments assigns users to offering variants. This
/// type exposes the experiment identifier and variant so the app
/// can render the correct paywall UI or log experiment events.
///
/// Derived from ``Offering/metadata`` by convention. Consumers
/// parse experiments from the offering metadata using the
/// convenience property on ``Offering``.
public struct PaywallExperiment: Sendable, Hashable, Codable, Identifiable {

    /// The experiment identifier from the dashboard.
    public let id: String

    /// The variant identifier assigned to this user.
    public let variantIdentifier: String

    /// Creates a `PaywallExperiment`.
    public init(id: String, variantIdentifier: String) {
        self.id = id
        self.variantIdentifier = variantIdentifier
    }
}

// MARK: - Offering Convenience

public extension Offering {

    /// The experiment variant metadata on this offering, if present.
    ///
    /// Parses from the offering metadata under keys
    /// `"rc_experiment_id"` and `"rc_experiment_variant"`.
    var experiment: PaywallExperiment? {
        guard let experimentId = metadata["rc_experiment_id"],
              let variant = metadata["rc_experiment_variant"] else {
            return nil
        }
        return PaywallExperiment(id: experimentId, variantIdentifier: variant)
    }
}
