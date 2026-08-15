import XCTest
@testable import MusicProjectsOrganizerCore

final class WorkbenchTests: XCTestCase {
    func testInboxStartAndReviseAreChildrenOfRoot() {
        let root = URL(fileURLWithPath: "/tmp/music-projects", isDirectory: true)
        let logic = URL(fileURLWithPath: "/tmp/Logic", isDirectory: true)
        let workbench = Workbench(root: root, logicProjects: logic)

        XCTAssertEqual(workbench.inbox.lastPathComponent, "_Inbox")
        XCTAssertEqual(workbench.start.lastPathComponent, "_Start")
        XCTAssertEqual(workbench.revise.lastPathComponent, "2_Revise")
        XCTAssertEqual(workbench.inbox.deletingLastPathComponent(), root)
        XCTAssertEqual(workbench.start.deletingLastPathComponent(), root)
        XCTAssertEqual(workbench.revise.deletingLastPathComponent(), root)
        XCTAssertEqual(workbench.logicProjects, logic)
    }

    func testLivePointsAtDesktopMusicProjectsAndMusicLogic() {
        let live = Workbench.live()
        let home = FileManager.default.homeDirectoryForCurrentUser

        XCTAssertEqual(
            live.root,
            home.appendingPathComponent("Desktop/_Music Projects", isDirectory: true)
        )
        XCTAssertEqual(
            live.logicProjects,
            home.appendingPathComponent("Music/Logic", isDirectory: true)
        )
    }
}
