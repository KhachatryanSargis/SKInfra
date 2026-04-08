import Testing
@testable import SKNavigation

@Suite("NavigationRouter")
@MainActor
struct NavigationRouterTests {

    // MARK: - Initial State

    @Test("Initial state is empty")
    func initialStateIsEmpty() {
        let router = NavigationRouter<TestRoute>()

        #expect(router.path.isEmpty)
        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
        #expect(router.currentSheetConfiguration == nil)
        #expect(router.isAtRoot)
        #expect(router.stackDepth == 0)
        #expect(router.isPresenting == false)
        #expect(router.topRoute == nil)
        #expect(router.shouldHideTabBar == false)
    }

    // MARK: - Push

    @Test("Push appends to path")
    func pushAppendsToPath() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)

        #expect(router.path == [.home])
        #expect(router.stackDepth == 1)
        #expect(router.isAtRoot == false)
        #expect(router.topRoute == .home)
    }

    @Test("Push multiple routes builds stack")
    func pushMultipleRoutes() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.push(.settings)

        #expect(router.path == [.home, .detail(id: "1"), .settings])
        #expect(router.stackDepth == 3)
    }

    // MARK: - Pop

    @Test("Pop removes last route")
    func popRemovesLastRoute() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.pop()

        #expect(router.path == [.home])
        #expect(router.stackDepth == 1)
    }

    @Test("Pop on empty stack does nothing")
    func popOnEmptyStackDoesNothing() {
        let router = NavigationRouter<TestRoute>()
        router.pop()

        #expect(router.path.isEmpty)
        #expect(router.isAtRoot)
    }

    @Test("Pop count removes multiple routes")
    func popCountRemovesMultiple() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.push(.settings)
        router.pop(count: 2)

        #expect(router.path == [.home])
    }

    @Test("Pop count clamped to stack size")
    func popCountClamped() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.pop(count: 5)

        #expect(router.path.isEmpty)
    }

    @Test("PopToRoot clears stack")
    func popToRootClearsStack() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.push(.settings)
        router.popToRoot()

        #expect(router.path.isEmpty)
        #expect(router.isAtRoot)
    }

    // MARK: - Pop To Route

    @Test("PopTo pops to a specific route")
    func popToSpecificRoute() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.push(.settings)
        router.popTo(.home)

        #expect(router.path == [.home])
    }

    @Test("PopTo with route not in stack does nothing")
    func popToRouteNotInStack() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.settings)
        router.popTo(.detail(id: "missing"))

        #expect(router.path == [.home, .settings])
    }

    // MARK: - Set Stack

    @Test("SetStack replaces entire path")
    func setStackReplacesEntirePath() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)

        let newStack: [TestRoute] = [.detail(id: "a"), .settings]
        router.setStack(newStack)

        #expect(router.path == newStack)
        #expect(router.stackDepth == 2)
    }

    @Test("SetStack with empty array clears path")
    func setStackWithEmptyArrayClearsPath() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.setStack([])

        #expect(router.path.isEmpty)
        #expect(router.isAtRoot)
    }

    // MARK: - Sheet Presentation

    @Test("Present sheet sets sheet route")
    func presentSheetSetsSheetRoute() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet())

        #expect(router.sheet == .settings)
        #expect(router.fullScreenCover == nil)
        #expect(router.isPresenting)
    }

    @Test("Present sheet stores configuration")
    func presentSheetStoresConfiguration() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet(.bottomSheet))

        #expect(router.sheet == .settings)
        #expect(router.currentSheetConfiguration == .bottomSheet)
    }

    @Test("Present sheet with default configuration")
    func presentSheetWithDefaultConfiguration() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet())

        #expect(router.currentSheetConfiguration == .default)
    }

    @Test("Present sheet with custom configuration")
    func presentSheetWithCustomConfiguration() {
        let config = SheetConfiguration(
            detents: [.medium],
            dragIndicatorVisibility: .visible,
            isDismissDisabled: true,
            cornerRadius: 20
        )
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet(config))

        #expect(router.currentSheetConfiguration == config)
    }

    // MARK: - Full Screen Cover Presentation

    @Test("Present fullScreenCover sets route")
    func presentFullScreenCoverSetsRoute() {
        let router = NavigationRouter<TestRoute>()
        router.present(.profile(userId: "u1"), as: .fullScreenCover)

        #if os(macOS)
        // On macOS, fullScreenCover falls back to sheet
        #expect(router.sheet == .profile(userId: "u1"))
        #expect(router.fullScreenCover == nil)
        #else
        #expect(router.fullScreenCover == .profile(userId: "u1"))
        #expect(router.sheet == nil)
        #endif
        #expect(router.isPresenting)
    }

    @Test("Present fullScreenCover clears sheet configuration")
    func presentFullScreenCoverClearsSheetConfiguration() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet(.bottomSheet))
        router.dismiss()
        router.present(.profile(userId: "u1"), as: .fullScreenCover)

        #if os(macOS)
        #expect(router.currentSheetConfiguration == .default)
        #else
        #expect(router.currentSheetConfiguration == nil)
        #endif
    }

    // MARK: - Present with Push Style

    @Test("Present with push style appends to path and logs warning")
    func presentWithPushStyleAppendsToPath() {
        let router = NavigationRouter<TestRoute>()
        router.present(.detail(id: "1"), as: .push)

        #expect(router.path == [.detail(id: "1")])
        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
    }

    // MARK: - Dismiss

    @Test("Dismiss sheet clears sheet and configuration")
    func dismissSheetClearsSheetAndConfiguration() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet(.bottomSheet))
        router.dismiss()

        #expect(router.sheet == nil)
        #expect(router.currentSheetConfiguration == nil)
        #expect(router.isPresenting == false)
    }

    @Test("Dismiss fullScreenCover clears it")
    func dismissFullScreenCoverClearsIt() {
        let router = NavigationRouter<TestRoute>()
        router.present(.profile(userId: "u1"), as: .fullScreenCover)
        router.dismiss()

        #expect(router.fullScreenCover == nil)
        #expect(router.isPresenting == false)
    }

    @Test("Dismiss prioritizes fullScreenCover over sheet")
    func dismissPrioritizesFullScreenCoverOverSheet() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet())
        router.fullScreenCover = .profile(userId: "u1")
        router.dismiss()

        #expect(router.fullScreenCover == nil)
        #expect(router.sheet == .settings)
        #expect(router.isPresenting)
    }

    @Test("Dismiss on clean state does nothing")
    func dismissOnCleanStateDoesNothing() {
        let router = NavigationRouter<TestRoute>()
        router.dismiss()

        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
        #expect(router.isPresenting == false)
    }

    // MARK: - Reset

    @Test("Reset clears everything")
    func resetClearsEverything() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.present(.settings, as: .sheet(.bottomSheet))
        router.reset()

        #expect(router.path.isEmpty)
        #expect(router.isAtRoot)
        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
        #expect(router.currentSheetConfiguration == nil)
        #expect(router.isPresenting == false)
    }

    @Test("Reset clears fullScreenCover and stack")
    func resetClearsFullScreenCoverAndStack() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.present(.profile(userId: "u1"), as: .fullScreenCover)
        router.reset()

        #expect(router.path.isEmpty)
        #expect(router.fullScreenCover == nil)
    }

    // MARK: - Navigate(to:) Action Dispatch

    @Test("Navigate to action push")
    func navigateToActionPush() {
        let router = NavigationRouter<TestRoute>()
        router.navigate(to: .push(.home))
        #expect(router.path == [.home])
    }

    @Test("Navigate to action pop")
    func navigateToActionPop() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.navigate(to: .pop())
        #expect(router.path.isEmpty)
    }

    @Test("Navigate to action popToRoot")
    func navigateToActionPopToRoot() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.push(.detail(id: "1"))
        router.navigate(to: .popToRoot)
        #expect(router.path.isEmpty)
    }

    @Test("Navigate to action present")
    func navigateToActionPresent() {
        let router = NavigationRouter<TestRoute>()
        router.navigate(to: .present(.settings, style: .sheet(.bottomSheet)))

        #expect(router.sheet == .settings)
        #expect(router.currentSheetConfiguration == .bottomSheet)
    }

    @Test("Navigate to action dismiss")
    func navigateToActionDismiss() {
        let router = NavigationRouter<TestRoute>()
        router.present(.settings, as: .sheet())
        router.navigate(to: .dismiss)
        #expect(router.sheet == nil)
    }

    @Test("Navigate to action reset")
    func navigateToActionReset() {
        let router = NavigationRouter<TestRoute>()
        router.push(.home)
        router.present(.settings, as: .sheet())
        router.navigate(to: .reset)

        #expect(router.path.isEmpty)
        #expect(router.sheet == nil)
    }

    @Test("Navigate to action setStack")
    func navigateToActionSetStack() {
        let router = NavigationRouter<TestRoute>()
        router.navigate(to: .setStack([.home, .settings]))
        #expect(router.path == [.home, .settings])
    }

    // MARK: - Tab Bar Hiding

    @Test("shouldHideTabBar reflects top route")
    func shouldHideTabBarReflectsTopRoute() {
        let router = NavigationRouter<TestRoute>()

        #expect(router.shouldHideTabBar == false)

        router.push(.home)
        #expect(router.shouldHideTabBar == false)

        router.push(.detail(id: "1"))
        #expect(router.shouldHideTabBar == true)

        router.pop()
        #expect(router.shouldHideTabBar == false)
    }

    // MARK: - Navigation Action Callback

    @Test("onNavigationAction is called for every action")
    func onNavigationActionCallback() {
        let router = NavigationRouter<TestRoute>()
        var actions: [String] = []

        router.onNavigationAction = { action in
            actions.append(String(describing: action))
        }

        router.push(.home)
        router.pop()
        router.present(.settings, as: .sheet())
        router.dismiss()

        #expect(actions.count == 4)
    }

    // MARK: - Top Route

    @Test("topRoute returns last item in stack")
    func topRouteReturnsLast() {
        let router = NavigationRouter<TestRoute>()
        #expect(router.topRoute == nil)

        router.push(.home)
        #expect(router.topRoute == .home)

        router.push(.settings)
        #expect(router.topRoute == .settings)

        router.pop()
        #expect(router.topRoute == .home)
    }
}
