import XCTest
@testable import MacroformInboxCore

final class InboxServiceTests: XCTestCase {
    private var tempRoot: URL!
    private var workbench: Workbench!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacroformInbox-service-\(UUID().uuidString)", isDirectory: true)
        workbench = Workbench(
            root: tempRoot.appendingPathComponent("_Music Projects", isDirectory: true),
            logicProjects: tempRoot.appendingPathComponent("Logic", isDirectory: true)
        )
        try FileManager.default.createDirectory(at: workbench.inbox, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.start, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testLoadPreviewAndFilePileEndToEnd() throws {
        let source = workbench.inbox.appendingPathComponent("session-drop", isDirectory: true)
        try writeFile(at: source.appendingPathComponent("MIXST001.WAV"), contents: Data(repeating: 0x61, count: 10))
        try writeFile(at: source.appendingPathComponent("stem.wav"), contents: Data(repeating: 0x61, count: 100))

        let service = InboxService(workbench: workbench)
        let piles = try service.loadPiles()
        XCTAssertEqual(piles.count, 1)
        XCTAssertEqual(piles[0].displayName, "session-drop")
        XCTAssertEqual(try service.previewURL(for: piles[0])?.lastPathComponent, "MIXST001.WAV")

        let result = try service.file(
            piles[0],
            name: ProjectName(yymmdd: "260323", description: "toy piano", bpm: 92)
        )

        XCTAssertTrue(result.didMove)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: workbench.start.appendingPathComponent("260323_toy piano_92/MIXST001.WAV").path
        ))
        XCTAssertTrue(try service.loadPiles().isEmpty)
    }

    func testEnsureInboxCreatesTheDropFolder() throws {
        try FileManager.default.removeItem(at: workbench.inbox)
        let service = InboxService(workbench: workbench)
        try service.ensureInbox()
        XCTAssertTrue(FileManager.default.fileExists(atPath: workbench.inbox.path))
    }

    private func writeFile(at url: URL, contents: Data) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url)
    }
}
