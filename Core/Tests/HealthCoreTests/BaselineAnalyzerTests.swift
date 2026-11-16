import XCTest
@testable import HealthCore

final class BaselineAnalyzerTests: XCTestCase {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_798_000_000)
    private func p(_ daysAgo: Int, _ value: Double) -> TrendPoint {
        TrendPoint(recordedAt: calendar.date(byAdding: .day, value: -daysAgo, to: now)!, value: value)
    }
    func testMissingDataNeverGetsNormalScore() {
        let actual = BaselineAnalyzer.summarize(points: [], now: now, calendar: calendar)
        XCTAssertEqual(actual.direction, .insufficient)
        XCTAssertNil(actual.baseline)
    }
    func testRequiresSevenDistinctPriorDays() {
        let data = (1...6).map { p($0, 60) } + [p(0, 100)]
        let actual = BaselineAnalyzer.summarize(points: data, now: now, calendar: calendar)
        XCTAssertEqual(actual.direction, .insufficient)
        XCTAssertEqual(actual.uniqueDays, 6)
    }
    func testIncreasedMetricComparedWithPersonalBaseline() {
        let data = (1...14).map { p($0, 60) } + [p(0, 75)]
        let actual = BaselineAnalyzer.summarize(points: data, now: now, calendar: calendar)
        XCTAssertEqual(actual.direction, .higher)
        XCTAssertEqual(actual.baseline, 60)
        XCTAssertEqual(actual.percentageChange!, 0.25, accuracy: 0.0001)
    }
    func testDuplicateDenseDayCannotDominateBaseline() {
        let noisy = (0..<120).map { n in
            TrendPoint(recordedAt: p(10, 60).recordedAt.addingTimeInterval(Double(n)), value: 300)
        }
        let data = (1...14).map { p($0, 60) } + noisy + [p(0, 60)]
        let actual = BaselineAnalyzer.summarize(points: data, now: now, calendar: calendar)
        XCTAssertEqual(actual.direction, .stable)
        XCTAssertEqual(actual.baseline, 60)
    }
    func testOlderOrFutureSamplesExcluded() {
        let data = (1...14).map { p($0, 60) } + [p(-1, 300), p(60, 300), p(0, 60)]
        let actual = BaselineAnalyzer.summarize(points: data, now: now, calendar: calendar)
        XCTAssertEqual(actual.direction, .stable)
    }
    func testNoDataAndOldAndFutureFreshness() {
        XCTAssertEqual(FreshnessEvaluator.evaluate(recordedAt: nil, now: now, acceptableAge: 600), .noData)
        XCTAssertEqual(FreshnessEvaluator.evaluate(recordedAt: now.addingTimeInterval(-3600), now: now, acceptableAge: 600), .old)
        XCTAssertEqual(FreshnessEvaluator.evaluate(recordedAt: now.addingTimeInterval(3600), now: now, acceptableAge: 600), .future)
        XCTAssertEqual(FreshnessEvaluator.evaluate(recordedAt: now, now: now, acceptableAge: 600), .recent)
    }
}
