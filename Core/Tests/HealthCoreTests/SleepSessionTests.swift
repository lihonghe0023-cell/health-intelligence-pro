import XCTest
@testable import HealthCore

final class SleepSessionTests: XCTestCase {
    private func interval(_ startOffset: TimeInterval, _ endOffset: TimeInterval, stage: SleepStage = .core) -> SleepInterval {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        return SleepInterval(start: base.addingTimeInterval(startOffset),
                             end: base.addingTimeInterval(endOffset), stage: stage)
    }

    func testEmptyIntervalsHaveNoWindow() {
        XCTAssertNil(SleepSession.window(from: []))
    }

    func testSingleIntervalIsItsOwnWindow() {
        let only = interval(0, 3_600)
        XCTAssertEqual(SleepSession.window(from: [only]), only.start...only.end)
    }

    func testContiguousNightSpansMidnight() {
        // 22:00 -> 06:00 across midnight, with a brief awakening inside.
        let intervals = [
            interval(0, 7_200, stage: .core),
            interval(7_200, 25_200, stage: .deep),
            interval(25_200, 25_800, stage: .awake),
            interval(25_800, 28_800, stage: .core)
        ]
        let window = SleepSession.window(from: intervals)
        XCTAssertEqual(window?.lowerBound, intervals.first!.start)
        XCTAssertEqual(window?.upperBound, intervals.last!.end)
    }

    func testTwoNightsSplitByLongGapKeepsOnlyLatest() {
        let previousNight = [interval(-100_000, -97_000), interval(-97_000, -75_000)]
        let latestNight = [interval(0, 7_200), interval(7_200, 28_800)]
        let window = SleepSession.window(from: previousNight + latestNight)
        XCTAssertEqual(window?.lowerBound, latestNight.first!.start)
        XCTAssertEqual(window?.upperBound, latestNight.last!.end)
    }

    func testShortGapStaysInSameSession() {
        let intervals = [interval(0, 3_600), interval(3_600 + 3_000, 7_200)]
        XCTAssertEqual(SleepSession.window(from: intervals)?.lowerBound, intervals.first!.start)
    }

    func testOverlappingIntervalsFromTwoSourcesJoin() {
        let intervals = [interval(0, 3_600, stage: .rem), interval(1_800, 3_600, stage: .rem)]
        let window = SleepSession.window(from: intervals)
        XCTAssertEqual(window?.lowerBound, intervals.first!.start)
        XCTAssertEqual(window?.upperBound, intervals[0].end)
    }

    func testInvalidIntervalsAreIgnored() {
        let bad = SleepInterval(start: Date(timeIntervalSince1970: 1_700_003_600),
                                end: Date(timeIntervalSince1970: 1_700_000_000), stage: .core)
        XCTAssertNil(SleepSession.window(from: [bad]))
    }
}
