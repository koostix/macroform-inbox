import XCTest
@testable import MacroformInboxCore

final class MacroformInboxCoreTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertEqual(MacroformInboxCore.version, "0.2.0")
    }
}
