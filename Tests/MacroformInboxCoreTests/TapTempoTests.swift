import XCTest
@testable import MacroformInboxCore

final class TapTempoTests: XCTestCase {
    func testTwoTapsHalfSecondApartAre120() {
        var tap = TapTempo()
        XCTAssertNil(tap.tap(at: 1.0))
        XCTAssertEqual(tap.tap(at: 1.5), 120)
    }

    func testAveragesRecentIntervals() {
        var tap = TapTempo()
        _ = tap.tap(at: 0)
        _ = tap.tap(at: 0.4)
        XCTAssertEqual(tap.tap(at: 0.9), 133)
    }

    func testTimeoutStartsANewSeries() {
        var tap = TapTempo(timeout: 2.0)
        XCTAssertNil(tap.tap(at: 0))
        XCTAssertNil(tap.tap(at: 3.0))
        XCTAssertEqual(tap.tapCount, 1)
        XCTAssertEqual(tap.tap(at: 3.5), 120)
    }

    func testKeepsOnlyTheNewestTaps() {
        var tap = TapTempo(maxTaps: 3)
        _ = tap.tap(at: 0)
        _ = tap.tap(at: 1)
        _ = tap.tap(at: 2)
        XCTAssertEqual(tap.tap(at: 2.5), 80)
        XCTAssertEqual(tap.tapCount, 3)
    }

    func testOutOfRangeIntervalsReturnNil() {
        var tap = TapTempo()
        _ = tap.tap(at: 0)
        XCTAssertNil(tap.tap(at: 0.1))
        _ = tap.tap(at: 10)
        _ = tap.tap(at: 14)
        XCTAssertNil(tap.bpm)
    }

    func testResetClearsTaps() {
        var tap = TapTempo()
        _ = tap.tap(at: 0)
        _ = tap.tap(at: 0.5)
        tap.reset()
        XCTAssertEqual(tap.tapCount, 0)
        XCTAssertNil(tap.bpm)
    }
}
