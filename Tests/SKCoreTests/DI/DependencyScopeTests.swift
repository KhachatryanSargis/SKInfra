import Testing
@testable import SKCore

@Suite("DependencyScope")
struct DependencyScopeTests {

    // MARK: - CustomStringConvertible

    @Test("Each scope produces its expected description", arguments: [
        (DependencyScope.unique, "unique"),
        (DependencyScope.singleton, "singleton"),
        (DependencyScope.cached, "cached"),
        (DependencyScope.shared, "shared"),
        (DependencyScope.graph, "graph")
    ])
    func scopeDescription(scope: DependencyScope, expected: String) {
        #expect(scope.description == expected)
    }

    // MARK: - Sendable

    @Test("Can be passed across concurrency boundaries")
    func sendable() async {
        let scope = DependencyScope.singleton
        let result = await Task { scope }.value
        #expect(result == .singleton)
    }

    // MARK: - Exhaustiveness

    @Test("All five scope cases exist")
    func allCases() {
        let scopes: [DependencyScope] = [.unique, .singleton, .cached, .shared, .graph]
        #expect(scopes.count == 5)
    }
}
