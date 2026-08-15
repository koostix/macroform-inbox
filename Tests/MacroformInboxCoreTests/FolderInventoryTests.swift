import XCTest
@testable import MacroformInboxCore

final class FolderInventoryTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacroformInbox-inventory-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testInspectsImmediateChildrenAndSkipsHidden() throws {
        try write(name: "take.wav", size: 40)
        try write(name: "notes.txt", size: 8)
        try FileManager.default.createDirectory(
            at: tempRoot.appendingPathComponent("Bounces", isDirectory: true),
            withIntermediateDirectories: true
        )
        try write(name: ".DS_Store", size: 4)

        let inventory = try FolderInspector().inspect(at: tempRoot)
        XCTAssertEqual(inventory.entries.map(\.name), ["Bounces", "notes.txt", "take.wav"])
        XCTAssertEqual(inventory.entries.first(where: { $0.name == "take.wav" })?.isAudio, true)
        XCTAssertEqual(inventory.entries.first(where: { $0.name == "Bounces" })?.isDirectory, true)
        XCTAssertEqual(inventory.fileCount, 2)
        XCTAssertEqual(inventory.totalBytes, 48)
        XCTAssertFalse(inventory.hasLogicProject)
        XCTAssertTrue(inventory.summary.contains("1 audio"))
    }

    func testLooseFilesOnlySkipsSubfolders() throws {
        try write(name: "loose.wav", size: 10)
        try write(name: "nested/hidden.wav", size: 20)
        let inventory = try FolderInspector().inspect(at: tempRoot, looseFilesOnly: true)
        XCTAssertEqual(inventory.entries.map(\.name), ["loose.wav"])
        XCTAssertEqual(inventory.fileCount, 1)
        XCTAssertEqual(inventory.totalBytes, 10)
    }

    func testDetectsLogicPackage() throws {
        let logic = tempRoot.appendingPathComponent("Untitled.logicx", isDirectory: true)
        try write(name: "Untitled.logicx/Resources/info.plist", size: 5)
        let pile = Pile(
            sourceURL: logic,
            origin: .folder,
            displayName: "Untitled.logicx",
            fileCount: 1,
            oldestFileDate: Date(),
            kind: .logicPackage
        )
        let inventory = try FolderInspector().inspect(pile)
        XCTAssertTrue(inventory.hasLogicProject)
    }

    private func write(name: String, size: Int) throws {
        let url = tempRoot.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: 0x61, count: size).write(to: url)
    }
}
