import Foundation

public enum SleepCalculator {
    /// Deduplicate same-stage and conflicting-stage intervals with a deterministic sweep.
    /// With no source identifier in the input, a stage precedence is used when sources conflict:
    /// awake > deep > REM > core > unspecified. This is NOT a clinical stage arbitration.
    public static func summarize(_ intervals: [SleepInterval]) -> SleepSummary {
        let valid = intervals.filter { $0.end > $0.start }
        var secondsByStage: [SleepStage: TimeInterval] = [:]
        for stage in SleepStage.allCases { secondsByStage[stage] = 0 }
        let timePoints = Array(Set(valid.flatMap { [$0.start, $0.end] })).sorted()
        if timePoints.count >= 2 {
            for i in 0..<(timePoints.count - 1) {
                let start = timePoints[i], end = timePoints[i + 1]
                guard end > start else { continue }
                let active = valid.filter { $0.start < end && $0.end > start }
                if let winningStage = active.map(\.stage).max(by: { priority($0) < priority($1) }) {
                    secondsByStage[winningStage, default: 0] += end.timeIntervalSince(start)
                }
            }
        }
        var minutes: [SleepStage: Int] = [:]
        for stage in SleepStage.allCases { minutes[stage] = Int(((secondsByStage[stage] ?? 0) / 60).rounded()) }
        let asleep = [SleepStage.deep, .rem, .core, .unspecified].reduce(0) { $0 + (minutes[$1] ?? 0) }
        return SleepSummary(minutesByStage: minutes, totalAsleepMinutes: asleep,
                            minutesAwake: minutes[.awake] ?? 0)
    }

    private static func priority(_ stage: SleepStage) -> Int {
        switch stage {
        case .unspecified: return 0
        case .core: return 1
        case .rem: return 2
        case .deep: return 3
        case .awake: return 4
        }
    }
}
