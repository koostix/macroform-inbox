import XCTest
@testable import MusicProjectsOrganizerCore

final class PileScannerTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MusicProjectsOrganizer-scanner-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testScansInboxStartReviseAndUnnamedLogicPackages() throws {
        let workbench = makeWorkbench()
        try FileManager.default.createDirectory(at: workbench.inbox, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.start, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.revise, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.logicProjects, withIntermediateDirectories: true)

        let inboxPile = workbench.inbox.appendingPathComponent("session-drop", isDirectory: true)
        try writeFile(at: inboxPile.appendingPathComponent("EX000_1.WAV"), contents: Data("a".utf8))

        let startUnnamed = workbench.start.appendingPathComponent("260320_UNNAMED-02", isDirectory: true)
        try writeFile(at: startUnnamed.appendingPathComponent("EX000_2.WAV"), contents: Data("ab".utf8))

        let startNamed = workbench.start.appendingPathComponent("260323_underwater guitar", isDirectory: true)
        try writeFile(at: startNamed.appendingPathComponent("mix.wav"), contents: Data("abc".utf8))

        let reviseUnnamed = workbench.revise.appendingPathComponent("251116_UNNAMED-09", isDirectory: true)
        try writeFile(at: reviseUnnamed.appendingPathComponent("take.mp3"), contents: Data("abcd".utf8))

        let untitledLogic = workbench.logicProjects.appendingPathComponent("Untitled 5.logicx", isDirectory: true)
        try writeFile(at: untitledLogic.appendingPathComponent("Resources/info.plist"), contents: Data("plist".utf8))

        let namedLogic = workbench.logicProjects.appendingPathComponent("Chill 2.logicx", isDirectory: true)
        try writeFile(at: namedLogic.appendingPathComponent("Resources/info.plist"), contents: Data("plist".utf8))

        try writeFile(at: workbench.inbox.appendingPathComponent(".DS_Store"), contents: Data("ds".utf8))

        let piles = try PileScanner().scan(workbench: workbench)
        let byName = Dictionary(uniqueKeysWithValues: piles.map { ($0.displayName, $0) })

        XCTAssertEqual(Set(piles.map(\.displayName)), [
            "session-drop",
            "260320_UNNAMED-02",
            "251116_UNNAMED-09",
            "Untitled 5.logicx",
        ])
        XCTAssertEqual(byName["session-drop"]?.origin, .inbox)
        XCTAssertEqual(byName["260320_UNNAMED-02"]?.origin, .start)
        XCTAssertEqual(byName["251116_UNNAMED-09"]?.origin, .revise)
        XCTAssertEqual(byName["Untitled 5.logicx"]?.origin, .logic)
        XCTAssertEqual(byName["session-drop"]?.fileCount, 1)
        XCTAssertEqual(byName["Untitled 5.logicx"]?.fileCount, 1)
    }

    func testEnsureInboxExistsCreatesMissingInbox() throws {
        let workbench = makeWorkbench()
        XCTAssertFalse(FileManager.default.fileExists(atPath: workbench.inbox.path))
        try PileScanner().ensureInboxExists(workbench: workbench)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workbench.inbox.path))
    }

    func testScannerDoesNotCreateInboxOnItsOwn() throws {
        let workbench = makeWorkbench()
        _ = try PileScanner().scan(workbench: workbench)
        XCTAssertFalse(FileManager.default.fileExists(atPath: workbench.inbox.path))
    }

    private func makeWorkbench() -> Workbench {
        Workbench(
            root: tempRoot.appendingPathComponent("_Music Projects", isDirectory: true),
            logicProjects: tempRoot.appendingPathComponent("Logic", isDirectory: true)
        )
    }

    private func writeFile(at url: URL, contents: Data) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url)
    }
}
