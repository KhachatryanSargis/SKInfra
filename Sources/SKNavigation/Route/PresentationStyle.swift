import SwiftUI

// MARK: - Presentation Style

/// Defines how a route is presented in the navigation hierarchy.
public enum PresentationStyle: Sendable, Equatable {

    /// Pushes the destination onto the navigation stack.
    case push

    /// Presents the destination as a sheet with optional configuration.
    case sheet(SheetConfiguration = .default)

    /// Presents the destination as a full-screen cover.
    case fullScreenCover
}

// MARK: - Sheet Configuration

/// Configuration options for sheet presentation.
public struct SheetConfiguration: Sendable, Equatable {

    /// The detents at which the sheet can rest.
    public let detents: Set<PresentationDetent>

    /// Whether the drag indicator is visible.
    public let dragIndicatorVisibility: Visibility

    /// Whether the sheet is dismissible by dragging.
    public let isDismissDisabled: Bool

    /// The corner radius applied to the sheet.
    public let cornerRadius: CGFloat?

    public init(
        detents: Set<PresentationDetent> = [.large],
        dragIndicatorVisibility: Visibility = .automatic,
        isDismissDisabled: Bool = false,
        cornerRadius: CGFloat? = nil
    ) {
        self.detents = detents
        self.dragIndicatorVisibility = dragIndicatorVisibility
        self.isDismissDisabled = isDismissDisabled
        self.cornerRadius = cornerRadius
    }

    /// Sensible defaults: large detent, automatic drag indicator.
    public static let `default` = SheetConfiguration()

    /// Bottom sheet configuration: medium + large detents with visible drag indicator.
    public static let bottomSheet = SheetConfiguration(
        detents: [.medium, .large],
        dragIndicatorVisibility: .visible
    )
}
