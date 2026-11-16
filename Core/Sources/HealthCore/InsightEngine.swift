import Foundation

/// Transparent, offline, rule-based interpretation. Does not diagnose, predict disease,
/// or pretend to call an LLM. Missing data never produces fabricated conclusions.
public enum InsightEngine {
    public static func insights(readings: [String: MetricReading], sleep: SleepSummary?) -> [HealthInsight] {
        var result: [HealthInsight] = []
        if let resting = readings["restingHeartRate"] {
            result.append(HealthInsight(
                id: "resting", title: "静息心率已记录",
                body: "最近记录为 \(formatted(resting.value)) 次/分。单次数值不能说明疾病风险；建议结合个人长期变化、症状与测量条件一起查看。",
                supportingMetricIDs: [resting.id]))
        }
        if let hrv = readings["hrv"] {
            result.append(HealthInsight(
                id: "hrv", title: "HRV 长期趋势更有意义",
                body: "最近记录的 HRV（SDNN）为 \(formatted(hrv.value)) 毫秒。该指标受到年龄、睡眠、运动、压力及测量时间影响，不宜用单次数值判断健康状况。",
                supportingMetricIDs: [hrv.id]))
        }
        if let sleep, sleep.totalAsleepMinutes > 0 {
            let hours = sleep.totalAsleepMinutes / 60
            let minutes = sleep.totalAsleepMinutes % 60
            result.append(HealthInsight(
                id: "sleep", title: "睡眠分期汇总",
                body: "所选时间窗口内，分期记录合计约 \(hours) 小时 \(minutes) 分。数据可能因设备缺失、来源重叠而不完整，不能用于诊断睡眠障碍。",
                supportingMetricIDs: ["sleep"]))
        }
        if result.isEmpty {
            result.append(HealthInsight(
                id: "empty", title: "尚无足够健康记录",
                body: "请在设置页发起 HealthKit 授权，并确保 Apple Watch 已记录相应指标。没有记录时不会填充模拟健康数据。",
                supportingMetricIDs: []))
        }
        return result
    }

    private static func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
