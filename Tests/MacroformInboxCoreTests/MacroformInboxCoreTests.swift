import XCTest
@testable import MacroformInboxCore

final class MacroformInboxCoreTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertEqual(MacroformInboxCore.version, "0.1.0")
    }
}
