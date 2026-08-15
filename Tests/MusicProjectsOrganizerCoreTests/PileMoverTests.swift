import XCTest
@testable import MusicProjectsOrganizerCore

final class PileMoverTests: XCTestCase {
    private var tempRoot: URL!
    private var workbench: Workbench!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MusicProjectsOrganizer-mover-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        workbench = Workbench(
            root: tempRoot.appendingPathComponent("_Music Projects", isDirectory: true),
            logicProjects: tempRoot.appendingPathComponent("Logic", isDirectory: true)
        )
        try FileManager.default.createDirectory(at: workbench.inbox, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.start, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.revise, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testMovesInboxSessionIntoStartAndRemovesSource() throws {
        let source = workbench.inbox.appendingPathComponent("session", isDirectory: true)
        try writeFile(at: source.appendingPathComponent("EX000_1.WAV"), contents: Data("wav".utf8))
        let dest = workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)

        let result = try PileMover().move(from: source, to: dest)

        XCTAssertTrue(result.didMove)
        XCTAssertEqual(result.destination, dest)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.appendingPathComponent("EX000_1.WAV").path))
    }

    func testRenamesStartFolderInPlace() throws {
        let source = workbench.start.appendingPathComponent("260320_UNNAMED-02", isDirectory: true)
        try writeFile(at: source.appendingPathComponent("take.wav"), contents: Data("a".utf8))
        let dest = workbench.start.appendingPathComponent("260320_toy piano_92", isDirectory: true)

        let result = try PileMover().move(from: source, to: dest)

        XCTAssertTrue(result.didMove)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.appendingPathComponent("take.wav").path))
    }

    func testCollisionDestinationStillMovesToProvidedURL() throws {
        let existing = workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
        let source = workbench.inbox.appendingPathComponent("session", isDirectory: true)
        try writeFile(at: source.appendingPathComponent("take.wav"), contents: Data("a".utf8))
        let dest = workbench.start.appendingPathComponent("260323_toy piano_92-2", isDirectory: true)

        _ = try PileMover().move(from: source, to: dest)

        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.appendingPathComponent("take.wav").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: existing.path))
    }

    func testRefusesDestinationInsideSource() throws {
        let source = workbench.start.appendingPathComponent("260320_UNNAMED-02", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let dest = source.appendingPathComponent("nested", isDirectory: true)

        XCTAssertThrowsError(try PileMover().move(from: source, to: dest)) { error in
            guard case PileMoverError.destinationInsideSource = error else {
                return XCTFail("expected destinationInsideSource, got \(error)")
            }
        }
    }

    func testSameSourceAndDestinationIsNoOp() throws {
        let source = workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        try writeFile(at: source.appendingPathComponent("take.wav"), contents: Data("a".utf8))

        let result = try PileMover().move(from: source, to: source)

        XCTAssertFalse(result.didMove)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.appendingPathComponent("take.wav").path))
    }

    func testCrossVolumeIsRejected() throws {
        let source = workbench.inbox.appendingPathComponent("session", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let dest = workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        let mover = PileMover(volumeID: { url in
            url.path.contains("_Inbox") ? "volume-a" : "volume-b"
        })

        XCTAssertThrowsError(try mover.move(from: source, to: dest)) { error in
            guard case PileMoverError.crossVolume = error else {
                return XCTFail("expected crossVolume, got \(error)")
            }
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
    }

    private func writeFile(at url: URL, contents: Data) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url)
    }
}
