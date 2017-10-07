import XCTest
@testable import WoodpeckerTests

XCTMain([
    testCase(RegistryTests.allTests),
    testCase(InstrumentTests.allTests),
])
