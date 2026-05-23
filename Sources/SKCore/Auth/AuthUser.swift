import Foundation

// MARK: - Auth User

/// A snapshot of a signed-in user.
///
/// `AuthUser` is the protocol-neutral identity value used throughout SKInfra.
/// It exposes only the fields shared by every realistic provider — anything
/// provider-specific (Firebase custom claims, Apple full-name parts, etc.)
/// belongs in the consuming feature, not here.
///
/// The type is `Codable` so it can round-trip through ``StorageProtocol``
/// (for example, caching the last-known user across app launches).
public struct AuthUser: Sendable, Hashable, Codable, Identifiable {
    /// The stable provider identifier for this user.
    ///
    /// For ``Auth`` impls backed by Firebase this is the Firebase UID. The
    /// value is guaranteed stable for the lifetime of the account on the
    /// underlying provider — safe to use as a primary key in domain stores.
    public let id: String

    /// The user's display name, if the provider knows one.
    public let displayName: String?

    /// The user's email address, if the provider knows and exposes one.
    public let email: String?

    /// The user's profile photo URL, if the provider knows one.
    public let photoURL: URL?

    /// `true` when the user is signed in without a real identity provider.
    ///
    /// Reserved for impls that support anonymous sessions. The current
    /// SKCore ``Auth`` surface does not expose anonymous sign-in, but the
    /// flag is present so impl modules can carry it through.
    public let isAnonymous: Bool

    /// The set of provider identifiers the user has linked to this account.
    ///
    /// Conventional provider identifiers follow Firebase's scheme — e.g.
    /// `"apple.com"`, `"google.com"`, `"password"`.
    public let providerIDs: [String]

    /// When the account was first created on the provider, if known.
    public let creationDate: Date?

    /// When the user most recently signed in, if known.
    public let lastSignInDate: Date?

    /// Creates an `AuthUser`.
    ///
    /// All fields except `id` and `isAnonymous` are optional because not
    /// every provider exposes them.
    public init(
        id: String,
        displayName: String? = nil,
        email: String? = nil,
        photoURL: URL? = nil,
        isAnonymous: Bool = false,
        providerIDs: [String] = [],
        creationDate: Date? = nil,
        lastSignInDate: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
        self.providerIDs = providerIDs
        self.creationDate = creationDate
        self.lastSignInDate = lastSignInDate
    }
}
