import SwiftUI

// MARK: - Coordinated View

/// A SwiftUI view that wires a ``Coordinator`` to a `NavigationStack` with
/// automatic sheet and full-screen cover presentation.
///
/// This is the primary view integration point. Wrap any coordinator in a
/// `CoordinatedView` to get fully managed navigation.
///
/// Example:
/// ```swift
/// struct ProductTabView: View {
///     let coordinator: ProductCoordinator
///
///     var body: some View {
///         CoordinatedView(coordinator: coordinator)
///     }
/// }
/// ```
public struct CoordinatedView<C: Coordinator>: View {

    // MARK: - Properties

    private let coordinator: C

    // MARK: - Lifecycle

    public init(coordinator: C) {
        self.coordinator = coordinator
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.router.path },
            set: { newValue in
                // Detect SwiftUI-initiated path changes (e.g., back button,
                // swipe-to-go-back) vs programmatic setStack calls.
                // When SwiftUI shortens the path, treat it as pop operations
                // rather than a generic setStack, so analytics/callbacks
                // receive the correct action type.
                let currentPath = coordinator.router.path
                if newValue.count < currentPath.count
                    && currentPath.starts(with: newValue)
                {
                    let popCount = currentPath.count - newValue.count
                    coordinator.router.pop(count: popCount)
                } else {
                    coordinator.router.setStack(newValue)
                }
            }
        )) {
            coordinator.rootView()
                .navigationDestination(for: C.RouteType.self) { route in
                    coordinator.destination(for: route)
                }
        }
        .sheet(
            item: Binding(
                get: { coordinator.router.sheet },
                set: { newValue in
                    if newValue == nil { coordinator.router.dismiss() }
                }
            )
        ) { route in
            coordinator.destination(for: route)
                .applySheetConfiguration(coordinator.router.currentSheetConfiguration)
        }
        #if os(iOS)
        .fullScreenCover(
            item: Binding(
                get: { coordinator.router.fullScreenCover },
                set: { newValue in
                    if newValue == nil { coordinator.router.dismiss() }
                }
            )
        ) { route in
            coordinator.destination(for: route)
        }
        #endif
    }
}

// MARK: - Sheet Configuration Modifier

extension View {

    /// Applies a ``SheetConfiguration`` to a sheet-presented view.
    @ViewBuilder
    func applySheetConfiguration(_ configuration: SheetConfiguration?) -> some View {
        if let config = configuration {
            self
                .presentationDetents(config.detents)
                .presentationDragIndicator(config.dragIndicatorVisibility)
                .interactiveDismissDisabled(config.isDismissDisabled)
                .modifier(OptionalCornerRadius(cornerRadius: config.cornerRadius))
        } else {
            self
        }
    }
}

// MARK: - Optional Corner Radius Modifier

private struct OptionalCornerRadius: ViewModifier {
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        if let radius = cornerRadius {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}
