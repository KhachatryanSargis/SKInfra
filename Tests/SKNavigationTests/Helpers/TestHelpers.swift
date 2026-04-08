import Foundation
import SwiftUI
@testable import SKNavigation

// MARK: - Test Route

/// A simple route enum used across all tests.
enum TestRoute: Route {
    case home
    case detail(id: String)
    case settings
    case profile(userId: String)

    var hidesTabBar: Bool {
        switch self {
        case .detail: true
        case .profile: true
        default: false
        }
    }
}

// MARK: - Simple Route (no tab bar hiding)

enum SimpleRoute: Route {
    case first
    case second
}

// MARK: - Test Tab

enum TestTab: String, SKNavigation.Tab, CaseIterable {
    case first
    case second
    case third

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .first:  "1.circle"
        case .second: "2.circle"
        case .third:  "3.circle"
        }
    }
}

// MARK: - Test Tab With Badges

enum BadgedTab: String, SKNavigation.Tab, CaseIterable {
    case inbox
    case notifications

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .inbox: "tray"
        case .notifications: "bell"
        }
    }

    var badge: String? {
        switch self {
        case .inbox: "5"
        case .notifications: nil
        }
    }
}

// MARK: - Test Module

enum TestModule: String, Hashable, Sendable {
    case first
    case second
    case third
}

// MARK: - Test Output

enum TestOutput: Sendable, Equatable {
    case completed(id: String)
    case saved
}
