import XCTest

@testable import Woodpecker

class RegistryTests: XCTestCase {
    public static var allTests = [
        ("testRegistryCount", testRegistryCount),
        ("testRegistrySnapshot", testRegistrySnapshot),
    ]
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testRegistryCount() {
        let Registry = Woodpecker.Registry()
        XCTAssertEqual(0, Registry.count())
    }

    func testRegistrySnapshot() {
        let Registry = Woodpecker.Registry()
        let snapshot = Registry.snapshot()
        XCTAssertEqual(0, snapshot.count)
    }
}
