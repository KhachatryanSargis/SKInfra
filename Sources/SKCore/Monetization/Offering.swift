import Foundation

// MARK: - Offering

/// A named group of packages available for purchase.
///
/// Each offering has a unique ``id`` and an optional ``metadata``
/// dictionary for paywall customization and A/B testing.
public struct Offering: Sendable, Hashable, Codable, Identifiable {

    /// The unique identifier configured in the monetization dashboard
    /// (e.g., `"default"`, `"premium_annual_promo"`).
    public let id: String

    /// A human-readable description of the offering, if configured.
    public let serverDescription: String

    /// The packages available within this offering.
    public let packages: [Package]

    /// Free-form metadata attached to this offering in the dashboard.
    ///
    /// Used for paywall customization and A/B testing. Keys and values
    /// are strings to keep the domain layer simple; consumers parse
    /// them as needed.
    public let metadata: [String: String]

    /// Creates an `Offering`.
    public init(
        id: String,
        serverDescription: String = "",
        packages: [Package] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.serverDescription = serverDescription
        self.packages = packages
        self.metadata = metadata
    }
}

// MARK: - Convenience

public extension Offering {

    /// Returns the first package matching the given type, if any.
    func package(ofType type: PackageType) -> Package? {
        packages.first { $0.packageType == type }
    }
}
