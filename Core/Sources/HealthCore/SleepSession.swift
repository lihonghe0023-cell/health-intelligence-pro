import Foundation

/// Derives the latest sleep session window from raw sleep intervals.
/// A session is a run of intervals where each consecutive interval starts
/// less than `maxGap` (default 2 hours) after the previous one ends; a longer
/// gap starts a new session. Overlapping intervals from multiple sources
/// belong to the same session. This is display-only sessionization for the
/// sleep page: it does not change how SleepCalculator summarizes stages,
/// and it never invents samples. A window may span midnight.
public enum SleepSession {
    /// Return only intervals overlapping the latest sleep session. The caller
    /// must summarize this subset, not the entire 36-hour query, to keep the
    /// displayed duration consistent with the displayed session window.
    /// Original HealthKit intervals are preserved; no synthetic stages.
    public static func latestIntervals(from intervals: [SleepInterval], maxGap: TimeInterval = 2 * 3600) -> [SleepInterval] {
        guard let latest = window(from: intervals, maxGap: maxGap) else { return [] }
        return intervals.filter { $0.end > $0.start && $0.start < latest.upperBound && $0.end > latest.lowerBound }
    }

    public static func window(from intervals: [SleepInterval], maxGap: TimeInterval = 2 * 3600) -> ClosedRange<Date>? {
        let sorted = intervals.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        guard let last = sorted.last else { return nil }
        var runStart = last.start
        var index = sorted.count - 1
        while index > 0 {
            let previous = sorted[index - 1]
            if runStart.timeIntervalSince(previous.end) < maxGap {
                runStart = min(runStart, previous.start)
                index -= 1
            } else {
                break
            }
        }
        return runStart...last.end
    }
}
