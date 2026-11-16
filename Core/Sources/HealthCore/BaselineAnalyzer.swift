import Foundation

/// Independent of Apple APIs. This is an observational wellness trend, never a diagnosis.
public enum TrendDirection: String, Codable, Sendable {
    case insufficient = "数据不足"
    case stable = "接近个人基线"
    case higher = "高于个人基线"
    case lower = "低于个人基线"
}

public struct BaselineSummary: Equatable, Sendable {
    public let direction: TrendDirection
    public let current: Double?
    public let baseline: Double?
    public let percentageChange: Double?
    public let uniqueDays: Int
    public let measuredAt: Date?

    public init(direction: TrendDirection, current: Double?, baseline: Double?,
                percentageChange: Double?, uniqueDays: Int, measuredAt: Date?) {
        self.direction = direction
        self.current = current
        self.baseline = baseline
        self.percentageChange = percentageChange
        self.uniqueDays = uniqueDays
        self.measuredAt = measuredAt
    }
}

public enum BaselineAnalyzer {
    /// At least seven distinct *previous* days are needed. The most recent day is
    /// deliberately kept out of the reference window to avoid self-comparison.
    /// `changeThreshold` is a visualization heuristic, not a medical threshold.
    public static func summarize(points: [TrendPoint], now: Date, calendar: Calendar = .current,
                                 windowDays: Int = 30, minBaselineDays: Int = 7,
                                 changeThreshold: Double = 0.12) -> BaselineSummary {
        let eligible = points.filter {
            $0.value.isFinite && $0.value >= 0 && $0.recordedAt <= now &&
            $0.recordedAt >= calendar.date(byAdding: .day, value: -windowDays, to: now)!
        }.sorted { $0.recordedAt < $1.recordedAt }
        guard let current = eligible.last else {
            return BaselineSummary(direction: .insufficient, current: nil, baseline: nil,
                                   percentageChange: nil, uniqueDays: 0, measuredAt: nil)
        }
        let today = calendar.startOfDay(for: current.recordedAt)
        // Use daily medians. Dense modern heart-rate samples must not outweigh sparse days.
        let previous = Dictionary(grouping: eligible.filter { calendar.startOfDay(for: $0.recordedAt) < today },
                                  by: { calendar.startOfDay(for: $0.recordedAt) })
        let medians = previous.values.compactMap { median($0.map(\.value)) }
        guard medians.count >= minBaselineDays, let baseline = median(medians), baseline > 0 else {
            return BaselineSummary(direction: .insufficient, current: current.value,
                                   baseline: nil, percentageChange: nil,
                                   uniqueDays: medians.count, measuredAt: current.recordedAt)
        }
        let change = (current.value - baseline) / baseline
        let direction: TrendDirection = change > changeThreshold ? .higher :
            (change < -changeThreshold ? .lower : .stable)
        return BaselineSummary(direction: direction, current: current.value,
                               baseline: baseline, percentageChange: change,
                               uniqueDays: medians.count, measuredAt: current.recordedAt)
    }

    private static func median(_ values: [Double]) -> Double? {
        let numbers = values.filter(\.isFinite).sorted()
        guard !numbers.isEmpty else { return nil }
        let middle = numbers.count / 2
        return numbers.count.isMultiple(of: 2) ? (numbers[middle - 1] + numbers[middle]) / 2 : numbers[middle]
    }
}

public enum Freshness: String, Equatable, Sendable {
    case noData = "暂无数据"
    case recent = "近期记录"
    case old = "记录较旧"
    case future = "时间异常"
}

public enum FreshnessEvaluator {
    public static func evaluate(recordedAt: Date?, now: Date, acceptableAge: TimeInterval) -> Freshness {
        guard let recordedAt else { return .noData }
        guard recordedAt <= now.addingTimeInterval(120) else { return .future }
        return now.timeIntervalSince(recordedAt) <= acceptableAge ? .recent : .old
    }
}
