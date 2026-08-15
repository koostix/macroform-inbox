import XCTest
@testable import MusicProjectsOrganizerCore

final class MusicProjectsOrganizerCoreTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertEqual(MusicProjectsOrganizerCore.version, "0.4.0")
    }
}
