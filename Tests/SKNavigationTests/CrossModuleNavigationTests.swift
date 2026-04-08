import Testing
@testable import SKNavigation

@Suite("CrossModuleNavigation")
struct CrossModuleNavigationTests {

    // MARK: - CrossModuleDestination Init

    @Test("Destination stores all properties")
    func destinationStoresAllProperties() {
        let destination = CrossModuleDestination(
            targetModule: TestModule.second,
            identifier: "conv-123",
            parameters: ["conversationId": "conv-123", "source": "history"],
            preferredStrategy: .switchTabAndPush
        )

        #expect(destination.targetModule == .second)
        #expect(destination.identifier == "conv-123")
        #expect(destination.parameters["conversationId"] == "conv-123")
        #expect(destination.parameters["source"] == "history")
        #expect(destination.preferredStrategy == .switchTabAndPush)
    }

    @Test("Destination defaults to empty parameters")
    func destinationDefaultsToEmptyParameters() {
        let destination = CrossModuleDestination(
            targetModule: TestModule.first,
            identifier: "d-456",
            preferredStrategy: .presentSheet
        )

        #expect(destination.parameters.isEmpty)
    }

    // MARK: - Type Safety

    @Test("Target module is type-safe")
    func targetModuleIsTypeSafe() {
        let destination = CrossModuleDestination(
            targetModule: TestModule.third,
            identifier: "id",
            preferredStrategy: .switchTabAndPush
        )

        let target: TestModule = destination.targetModule
        #expect(target == .third)
    }

    @Test("Destination works with String target")
    func destinationWorksWithStringTarget() {
        let destination = CrossModuleDestination(
            targetModule: "chat",
            identifier: "id",
            preferredStrategy: .presentSheet
        )

        #expect(destination.targetModule == "chat")
    }

    @Test("Destination works with Int target")
    func destinationWorksWithIntTarget() {
        let destination = CrossModuleDestination(
            targetModule: 42,
            identifier: "id",
            preferredStrategy: .presentFullScreenCover
        )

        #expect(destination.targetModule == 42)
    }

    // MARK: - CrossModuleStrategy

    @Test("Strategy equality")
    func strategyEquality() {
        #expect(CrossModuleStrategy.switchTabAndPush == .switchTabAndPush)
        #expect(CrossModuleStrategy.presentSheet == .presentSheet)
        #expect(CrossModuleStrategy.presentFullScreenCover == .presentFullScreenCover)
    }

    @Test("Strategy inequality")
    func strategyInequality() {
        #expect(CrossModuleStrategy.switchTabAndPush != .presentSheet)
        #expect(CrossModuleStrategy.presentSheet != .presentFullScreenCover)
        #expect(CrossModuleStrategy.switchTabAndPush != .presentFullScreenCover)
    }

    // MARK: - Integration with NavigationRouter

    @Test("SwitchTabAndPush strategy integration")
    @MainActor
    func switchTabAndPushStrategy() {
        let tabRouter = TabRouter(initialTab: TestTab.first)
        let targetRouter = NavigationRouter<TestRoute>()

        let destination = CrossModuleDestination(
            targetModule: TestModule.second,
            identifier: "detail-1",
            parameters: ["id": "detail-1"],
            preferredStrategy: .switchTabAndPush
        )

        switch destination.targetModule {
        case .second:
            tabRouter.select(.second)
            targetRouter.push(.detail(id: destination.parameters["id"]!))
        default:
            Issue.record("Unexpected target module")
        }

        #expect(tabRouter.selectedTab == .second)
        #expect(targetRouter.path == [.detail(id: "detail-1")])
    }

    @Test("PresentSheet strategy integration")
    @MainActor
    func presentSheetStrategy() {
        let targetRouter = NavigationRouter<TestRoute>()

        let destination = CrossModuleDestination(
            targetModule: TestModule.first,
            identifier: "conv-1",
            parameters: ["id": "conv-1"],
            preferredStrategy: .presentSheet
        )

        targetRouter.present(
            .detail(id: destination.parameters["id"]!),
            as: .sheet()
        )

        #expect(targetRouter.sheet == .detail(id: "conv-1"))
        #expect(targetRouter.isPresenting)
    }

    @Test("PresentFullScreenCover strategy integration")
    @MainActor
    func presentFullScreenCoverStrategy() {
        let targetRouter = NavigationRouter<TestRoute>()

        let destination = CrossModuleDestination(
            targetModule: TestModule.first,
            identifier: "conv-1",
            parameters: ["id": "conv-1"],
            preferredStrategy: .presentFullScreenCover
        )

        targetRouter.present(
            .detail(id: destination.parameters["id"]!),
            as: .fullScreenCover
        )

        // On macOS, fullScreenCover falls back to sheet presentation
        #if os(macOS)
        #expect(targetRouter.sheet == .detail(id: "conv-1"))
        #else
        #expect(targetRouter.fullScreenCover == .detail(id: "conv-1"))
        #endif
    }

    // MARK: - Strategy-Based Routing

    @Test("All strategies apply correctly")
    @MainActor
    func allStrategiesApplyCorrectly() {
        let router = NavigationRouter<TestRoute>()
        let route = TestRoute.detail(id: "x")

        // switchTabAndPush → push
        applyStrategy(.switchTabAndPush, route: route, to: router)
        #expect(router.path == [route])
        router.reset()

        // presentSheet → sheet
        applyStrategy(.presentSheet, route: route, to: router)
        #expect(router.sheet == route)
        router.reset()

        // presentFullScreenCover → fullScreenCover (or sheet on macOS)
        applyStrategy(.presentFullScreenCover, route: route, to: router)
        #if os(macOS)
        #expect(router.sheet == route)
        #else
        #expect(router.fullScreenCover == route)
        #endif
    }

    // MARK: - Helpers

    /// Applies a strategy to a router, avoiding constant-switch warnings.
    @MainActor
    private func applyStrategy(
        _ strategy: CrossModuleStrategy,
        route: TestRoute,
        to router: NavigationRouter<TestRoute>
    ) {
        switch strategy {
        case .switchTabAndPush: router.push(route)
        case .presentSheet: router.present(route, as: .sheet())
        case .presentFullScreenCover: router.present(route, as: .fullScreenCover)
        }
    }
}
