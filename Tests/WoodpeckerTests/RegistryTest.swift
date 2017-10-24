import XCTest

@testable import Woodpecker

class RegistryTests: XCTestCase {
    public static var allTests = [
        ("testRegistryCount", testRegistryCount),
        ("testRegistrySnapshot", testRegistrySnapshot)
    ]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testRegistryCount() {
        let registry = Woodpecker.Registry()
        registry.register(name: "count", instrument: Counter())
        XCTAssertEqual(1, registry.count())
    }

    func testRegistrySnapshot() {
        let registry = Woodpecker.Registry()
        let counter = Counter()
        registry.register(name: "count", instrument: counter)
        let snapshot = registry.snapshot()
        XCTAssertEqual(1, snapshot.count)
        XCTAssertEqual(0, registry.count())
        XCTAssertTrue(snapshot.contains { key, _ in key == "count" })
    }
}
