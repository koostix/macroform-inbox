import XCTest
@testable import MusicProjectsOrganizerCore

final class DestinationResolverTests: XCTestCase {
    private var tempRoot: URL!
    private var workbench: Workbench!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MusicProjectsOrganizer-dest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        workbench = Workbench(
            root: tempRoot.appendingPathComponent("_Music Projects", isDirectory: true),
            logicProjects: tempRoot.appendingPathComponent("Logic", isDirectory: true)
        )
        try FileManager.default.createDirectory(at: workbench.start, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.revise, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workbench.inbox, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testInboxAndLogicLandInStart() {
        let inboxPile = pile(named: "session-drop", origin: .inbox, parent: workbench.inbox)
        let logicPile = pile(named: "Untitled 5.logicx", origin: .logic, parent: workbench.logicProjects)
        let name = ProjectName(yymmdd: "260323", description: "toy piano", bpm: 92)

        XCTAssertEqual(
            DestinationResolver().destination(for: inboxPile, name: name, workbench: workbench),
            workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        )
        XCTAssertEqual(
            DestinationResolver().destination(for: logicPile, name: name, workbench: workbench),
            workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        )
    }

    func testStartAndReviseRenameInPlace() {
        let startPile = pile(named: "260320_UNNAMED-02", origin: .start, parent: workbench.start)
        let revisePile = pile(named: "251116_UNNAMED-09", origin: .revise, parent: workbench.revise)
        let name = ProjectName(yymmdd: "260320", description: "toy piano", bpm: 92)

        XCTAssertEqual(
            DestinationResolver().destination(for: startPile, name: name, workbench: workbench),
            workbench.start.appendingPathComponent("260320_toy piano_92", isDirectory: true)
        )
        XCTAssertEqual(
            DestinationResolver().destination(for: revisePile, name: name, workbench: workbench),
            workbench.revise.appendingPathComponent("260320_toy piano_92", isDirectory: true)
        )
    }

    func testCollisionAppendsDashTwo() throws {
        let existing = workbench.start.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
        let inboxPile = pile(named: "session-drop", origin: .inbox, parent: workbench.inbox)
        let name = ProjectName(yymmdd: "260323", description: "toy piano", bpm: 92)

        XCTAssertEqual(
            DestinationResolver().destination(for: inboxPile, name: name, workbench: workbench).lastPathComponent,
            "260323_toy piano_92-2"
        )
    }

    func testFolderOriginRenamesInPlace() {
        let dump = tempRoot.appendingPathComponent("Session1232", isDirectory: true)
        let pile = pile(named: "Session1232", origin: .folder, parent: tempRoot)
        let name = ProjectName(yymmdd: "260510", description: "tape looper", bpm: 92)
        XCTAssertEqual(
            DestinationResolver().destination(for: pile, name: name, workbench: workbench),
            dump.deletingLastPathComponent().appendingPathComponent("260510_tape looper_92", isDirectory: true)
        )
    }

    func testCustomParentOverridesOrigin() {
        let inboxPile = pile(named: "session-drop", origin: .inbox, parent: workbench.inbox)
        let custom = tempRoot.appendingPathComponent("chosen", isDirectory: true)
        let name = ProjectName(yymmdd: "260323", description: "toy piano", bpm: 92)
        XCTAssertEqual(
            DestinationResolver().destination(for: inboxPile, name: name, workbench: workbench, parent: custom),
            custom.appendingPathComponent("260323_toy piano_92", isDirectory: true)
        )
    }

    func testLooseFilesStayInTheOpenedFolder() {
        let pile = Pile(
            sourceURL: tempRoot,
            origin: .folder,
            displayName: "2 loose files",
            fileCount: 2,
            oldestFileDate: Date(),
            kind: .looseFiles,
            isUnnamed: true
        )
        let name = ProjectName(yymmdd: "260510", description: "tape looper", bpm: 92)
        XCTAssertEqual(
            DestinationResolver().destination(for: pile, name: name, workbench: workbench),
            tempRoot.appendingPathComponent("260510_tape looper_92", isDirectory: true)
        )
    }

    func testSourceMatchingProposedNameIsNotTreatedAsCollision() {
        let startPile = pile(named: "260323_toy piano_92", origin: .start, parent: workbench.start)
        let name = ProjectName(yymmdd: "260323", description: "toy piano", bpm: 92)
        XCTAssertEqual(
            DestinationResolver().destination(for: startPile, name: name, workbench: workbench).lastPathComponent,
            "260323_toy piano_92"
        )
    }

    private func pile(named: String, origin: Origin, parent: URL) -> Pile {
        Pile(
            sourceURL: parent.appendingPathComponent(named, isDirectory: true),
            origin: origin,
            displayName: named,
            fileCount: 1,
            oldestFileDate: Date()
        )
    }
}
