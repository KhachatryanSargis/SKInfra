import Testing
@testable import SKNavigation

@Suite("TabRouter")
@MainActor
struct TabRouterTests {

    // MARK: - Initial State

    @Test("Initial state has selected tab and no previous")
    func initialState() {
        let router = TabRouter(initialTab: TestTab.first)

        #expect(router.selectedTab == .first)
        #expect(router.previousTab == nil)
        #expect(router.didRetap == false)
        #expect(router.isTabBarHidden == false)
    }

    // MARK: - Tab Selection

    @Test("Selecting a different tab updates selectedTab")
    func selectDifferentTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)

        #expect(router.selectedTab == .second)
    }

    @Test("Selecting a different tab sets previousTab")
    func selectDifferentTabSetsPreviousTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)

        #expect(router.previousTab == .first)
    }

    @Test("Selecting multiple tabs tracks previous correctly")
    func selectMultipleTabsTracksPrevious() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        router.select(.third)

        #expect(router.selectedTab == .third)
        #expect(router.previousTab == .second)
    }

    @Test("Selecting a different tab resets didRetap flag")
    func selectDifferentTabResetsDidRetap() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first) // retap
        #expect(router.didRetap == true)

        router.select(.second) // switch tab
        #expect(router.didRetap == false)
    }

    // MARK: - Re-tap Detection

    @Test("Selecting same tab sets didRetap flag")
    func selectSameTabSetsDidRetap() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        #expect(router.didRetap == true)
    }

    @Test("Selecting same tab multiple times keeps didRetap true")
    func selectSameTabMultipleTimesKeepsDidRetap() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        router.select(.first)
        router.select(.first)
        #expect(router.didRetap == true)
    }

    @Test("Retap does not change previousTab")
    func retapDoesNotChangePreviousTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        let previousBefore = router.previousTab

        router.select(.second) // retap
        #expect(router.previousTab == previousBefore)
    }

    @Test("Retap does not change selectedTab")
    func retapDoesNotChangeSelectedTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        router.select(.second) // retap
        #expect(router.selectedTab == .second)
    }

    // MARK: - Consume Retap

    @Test("consumeRetap clears didRetap flag")
    func consumeRetapClearsFlag() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        #expect(router.didRetap == true)

        router.consumeRetap()
        #expect(router.didRetap == false)
    }

    @Test("consumeRetap on false is a no-op")
    func consumeRetapOnFalseIsNoOp() {
        let router = TabRouter(initialTab: TestTab.first)
        router.consumeRetap()
        #expect(router.didRetap == false)
    }

    // MARK: - Tab Protocol Defaults

    @Test("Tab id returns self")
    func tabIdReturnsSelf() {
        #expect(TestTab.first.id == .first)
        #expect(TestTab.second.id == .second)
    }

    @Test("Tab accessibilityLabel defaults to title")
    func tabAccessibilityLabelDefaultsToTitle() {
        #expect(TestTab.first.accessibilityLabel == TestTab.first.title)
    }

    @Test("Tab title and icon")
    func tabTitleAndIcon() {
        #expect(TestTab.first.title == "First")
        #expect(TestTab.second.title == "Second")
        #expect(TestTab.third.title == "Third")
        #expect(TestTab.first.icon == "1.circle")
        #expect(TestTab.second.icon == "2.circle")
        #expect(TestTab.third.icon == "3.circle")
    }

    @Test("Tab badge defaults to nil")
    func tabBadgeDefaultsToNil() {
        #expect(TestTab.first.badge == nil)
    }

    @Test("Tab badge can be overridden")
    func tabBadgeCanBeOverridden() {
        #expect(BadgedTab.inbox.badge == "5")
        #expect(BadgedTab.notifications.badge == nil)
    }

    // MARK: - Tab Bar Hidden State

    @Test("isTabBarHidden defaults to false")
    func isTabBarHiddenDefaultsFalse() {
        let router = TabRouter(initialTab: TestTab.first)
        #expect(router.isTabBarHidden == false)
    }

    @Test("isTabBarHidden can be set")
    func isTabBarHiddenCanBeSet() {
        let router = TabRouter(initialTab: TestTab.first)
        router.isTabBarHidden = true
        #expect(router.isTabBarHidden == true)
    }
}
