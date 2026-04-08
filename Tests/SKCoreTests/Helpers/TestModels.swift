import Foundation

/// Shared test models used across storage tests.
struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
}

struct TestSettings: Codable, Equatable {
    let isDarkMode: Bool
    let fontSize: Int
    let language: String
}

/// Non-codable type for compile-time safety verification.
/// (Intentionally does not conform to Codable.)
struct NonCodableType {
    let value: Int
}
