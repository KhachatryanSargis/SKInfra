import Foundation

// MARK: - Package

/// A purchasable unit within an ``Offering``.
///
/// Wraps a store product with offering context. The ``id`` is
/// the package identifier (e.g., `"$rc_monthly"`), distinct from
/// the underlying ``product``'s App Store product ID.
public struct Package: Sendable, Hashable, Codable, Identifiable {

    /// The package identifier.
    public let id: String

    /// The type of package (monthly, annual, lifetime, etc.).
    public let packageType: PackageType

    /// The underlying store product.
    public let product: Product

    /// The identifier of the offering this package belongs to.
    public let offeringIdentifier: String

    /// Creates a `Package`.
    public init(
        id: String,
        packageType: PackageType,
        product: Product,
        offeringIdentifier: String
    ) {
        self.id = id
        self.packageType = packageType
        self.product = product
        self.offeringIdentifier = offeringIdentifier
    }
}

// MARK: - Package Type

/// The classification of a ``Package`` within an ``Offering``.
///
/// Closed enum so the supported set is source-visible. Custom
/// packages use ``custom(_:)``.
public enum PackageType: Sendable, Hashable, Codable {
    case monthly
    case annual
    case weekly
    case twoMonth
    case threeMonth
    case sixMonth
    case lifetime
    case custom(String)
    case unknown
}
