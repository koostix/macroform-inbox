import XCTest
@testable import MacroformInboxCore

final class LooseFileWrapperTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacroformInbox-wrap-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testWrapsLooseFilesAndLeavesSubfolders() throws {
        try write(name: "orphan.wav", contents: Data("a".utf8))
        try write(name: "note.txt", contents: Data("b".utf8))
        try write(name: "session/keep.wav", contents: Data("c".utf8))
        let dest = tempRoot.appendingPathComponent("260510_tape looper_92", isDirectory: true)

        let result = try LooseFileWrapper().wrap(from: tempRoot, to: dest)

        XCTAssertTrue(result.didMove)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.appendingPathComponent("orphan.wav").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.appendingPathComponent("note.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempRoot.appendingPathComponent("session/keep.wav").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempRoot.appendingPathComponent("orphan.wav").path))
    }

    func testRefusesExistingDestination() throws {
        try write(name: "orphan.wav", contents: Data("a".utf8))
        let dest = tempRoot.appendingPathComponent("existing", isDirectory: true)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)

        XCTAssertThrowsError(try LooseFileWrapper().wrap(from: tempRoot, to: dest)) { error in
            guard case LooseFileWrapperError.destinationExists = error else {
                return XCTFail("expected destinationExists, got \(error)")
            }
        }
    }

    func testRefusesWhenNoLooseFiles() throws {
        try FileManager.default.createDirectory(
            at: tempRoot.appendingPathComponent("only-folder", isDirectory: true),
            withIntermediateDirectories: true
        )
        let dest = tempRoot.appendingPathComponent("260510_empty_92", isDirectory: true)
        XCTAssertThrowsError(try LooseFileWrapper().wrap(from: tempRoot, to: dest)) { error in
            guard case LooseFileWrapperError.noLooseFiles = error else {
                return XCTFail("expected noLooseFiles, got \(error)")
            }
        }
    }

    private func write(name: String, contents: Data) throws {
        let url = tempRoot.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url)
    }
}
