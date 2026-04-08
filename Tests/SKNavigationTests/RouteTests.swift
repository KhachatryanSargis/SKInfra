import Testing
@testable import SKNavigation

@Suite("Route Protocol")
struct RouteTests {

    // MARK: - Hashable

    @Test("Routes with same data are equal")
    func routesWithSameDataAreEqual() {
        #expect(TestRoute.home == TestRoute.home)
        #expect(TestRoute.detail(id: "1") == TestRoute.detail(id: "1"))
    }

    @Test("Routes with different data are not equal")
    func routesWithDifferentDataAreNotEqual() {
        #expect(TestRoute.detail(id: "1") != TestRoute.detail(id: "2"))
        #expect(TestRoute.home != TestRoute.settings)
    }

    // MARK: - Identifiable

    @Test("Equal routes have the same id")
    func equalRoutesHaveSameId() {
        let a = TestRoute.detail(id: "abc")
        let b = TestRoute.detail(id: "abc")
        #expect(a.id == b.id)
    }

    @Test("Different routes have different ids")
    func differentRoutesHaveDifferentId() {
        let a = TestRoute.home
        let b = TestRoute.settings
        #expect(a.id != b.id)
    }

    @Test("Route id is stable across invocations")
    func routeIdIsStable() {
        let route = TestRoute.detail(id: "stable-check")
        let id1 = route.id
        let id2 = route.id
        #expect(id1 == id2)
    }

    @Test("Route id is a string representation")
    func routeIdIsString() {
        let route = TestRoute.home
        #expect(route.id == String(describing: route))
    }

    // MARK: - Sendable

    @Test("Route is Sendable")
    func routeIsSendable() async {
        let route: TestRoute = .detail(id: "test")
        await Task {
            _ = route.id
        }.value
    }

    // MARK: - Collections

    @Test("Routes can be used in arrays")
    func routesInArrays() {
        let routes: [TestRoute] = [.home, .detail(id: "1"), .settings]
        #expect(routes.count == 3)
        #expect(routes[1] == .detail(id: "1"))
    }

    @Test("Routes can be used in sets")
    func routesInSets() {
        var routes: Set<TestRoute> = []
        routes.insert(.home)
        routes.insert(.home) // duplicate
        routes.insert(.settings)

        #expect(routes.count == 2)
        #expect(routes.contains(.home))
        #expect(routes.contains(.settings))
    }

    // MARK: - Tab Bar Hiding

    @Test("hidesTabBar defaults to false")
    func hidesTabBarDefaultsFalse() {
        let route = SimpleRoute.first
        #expect(route.hidesTabBar == false)
    }

    @Test("hidesTabBar can be overridden per case")
    func hidesTabBarOverridden() {
        #expect(TestRoute.home.hidesTabBar == false)
        #expect(TestRoute.settings.hidesTabBar == false)
        #expect(TestRoute.detail(id: "1").hidesTabBar == true)
        #expect(TestRoute.profile(userId: "u1").hidesTabBar == true)
    }
}
