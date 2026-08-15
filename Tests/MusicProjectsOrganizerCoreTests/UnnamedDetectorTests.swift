import XCTest
@testable import MusicProjectsOrganizerCore

final class UnnamedDetectorTests: XCTestCase {
    func testUnnamedPipelineAndDefaultNames() {
        let unnamed = [
            "260320_UNNAMED-02",
            "UNNAMED-14",
            "Untitled",
            "Untitled 5.logicx",
            "Untitled.logicx",
            "New Folder With Items",
            "untitled folder",
            "New Folder",
        ]
        for name in unnamed {
            XCTAssertTrue(UnnamedDetector.isUnnamed(name), "expected unnamed: \(name)")
        }
    }

    func testNamedProjectFoldersAreNotUnnamed() {
        let named = [
            "260323_underwater guitar",
            "260812_juno chords_88",
            "250816_sound threads",
            "20250828 Session - MaryLuFlute-Mix",
        ]
        for name in named {
            XCTAssertFalse(UnnamedDetector.isUnnamed(name), "expected named: \(name)")
        }
    }
}
