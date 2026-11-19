import Foundation

/// Explicit Chinese date formatting for Date.formatted() call sites.
/// SwiftUI's locale environment does not affect Foundation Date.formatted().
/// Uses the device's current time zone and 24-hour clock.
enum ChineseDateTime {
    static func full(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
