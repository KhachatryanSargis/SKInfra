import Testing
import Foundation
@testable import SKCore

@Suite("PaywallExperiment")
struct PaywallExperimentTests {

    @Test("Init and Codable round-trip")
    func codableRoundTrip() throws {
        let original = PaywallExperiment(id: "exp_1", variantIdentifier: "variant_a")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PaywallExperiment.self, from: data)
        #expect(decoded == original)
    }

    @Test("Offering.experiment parses from metadata")
    func offeringExperimentPresent() {
        let offering = Offering(
            id: "default",
            metadata: [
                "rc_experiment_id": "exp_42",
                "rc_experiment_variant": "variant_b"
            ]
        )
        let experiment = offering.experiment
        #expect(experiment?.id == "exp_42")
        #expect(experiment?.variantIdentifier == "variant_b")
    }

    @Test("Offering.experiment returns nil when keys are missing")
    func offeringExperimentMissing() {
        let noMetadata = Offering(id: "default")
        #expect(noMetadata.experiment == nil)

        let partialMetadata = Offering(
            id: "default",
            metadata: ["rc_experiment_id": "exp_42"]
        )
        #expect(partialMetadata.experiment == nil)
    }
}
