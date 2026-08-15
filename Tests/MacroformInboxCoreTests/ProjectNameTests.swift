import XCTest
@testable import MacroformInboxCore

final class ProjectNameTests: XCTestCase {
    func testFolderNameKeepsSpacesInDescription() {
        let name = ProjectName(yymmdd: "260323", description: "underwater guitar", bpm: 92)
        XCTAssertEqual(name.folderName, "260323_underwater guitar_92")
        XCTAssertTrue(name.isValid)
    }

    func testSlashBecomesSpaceAndCollapses() {
        let name = ProjectName(yymmdd: "260323", description: "toy / piano", bpm: 80)
        XCTAssertEqual(name.folderName, "260323_toy piano_80")
        XCTAssertTrue(name.isValid)
    }

    func testRemovesColonBackslashAndNarrowNoBreakSpace() {
        let narrow = "\u{202F}"
        let name = ProjectName(
            yymmdd: "260318",
            description: "Feb 18: night\(narrow)session\\take",
            bpm: 88
        )
        XCTAssertEqual(name.folderName, "260318_Feb 18 night session take_88")
    }

    func testEmptyDescriptionIsInvalid() {
        XCTAssertFalse(ProjectName(yymmdd: "260323", description: "   ", bpm: 92).isValid)
        XCTAssertFalse(ProjectName(yymmdd: "260323", description: "/", bpm: 92).isValid)
    }

    func testBpmBounds() {
        XCTAssertFalse(ProjectName(yymmdd: "260323", description: "toy", bpm: 19).isValid)
        XCTAssertFalse(ProjectName(yymmdd: "260323", description: "toy", bpm: 301).isValid)
        XCTAssertTrue(ProjectName(yymmdd: "260323", description: "toy", bpm: 20).isValid)
        XCTAssertTrue(ProjectName(yymmdd: "260323", description: "toy", bpm: 300).isValid)
    }

    func testYymmddFromDateUsesInjectedCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 3, day: 23)
        let date = components.date!
        XCTAssertEqual(ProjectName.yymmdd(from: date, calendar: calendar), "260323")
    }

    func testDefaultDatePrefersExistingLeadingYymmdd() {
        let oldest = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(
            ProjectName.defaultDate(fromDisplayName: "260320_UNNAMED-02", oldest: oldest),
            "260320"
        )
    }

    func testDefaultDateFallsBackToOldestWhenNameHasNoDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 2, day: 18)
        let oldest = components.date!
        XCTAssertEqual(
            ProjectName.defaultDate(fromDisplayName: "Untitled 5.logicx", oldest: oldest, calendar: calendar),
            "260218"
        )
    }
}
