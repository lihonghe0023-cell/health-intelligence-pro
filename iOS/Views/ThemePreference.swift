import SwiftUI

/// Theme preference for the V3 dual-theme system (GitHub Issue #2).
/// Stored in UserDefaults under "themePreference"; the default is system.
enum AppThemePreference: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    /// The ColorScheme to request, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Resolves the effective color scheme. UI-test launch arguments win over
/// the stored preference (screenshot gate pattern from #43/#48/#49); the
/// preference wins over the system setting; otherwise the system decides.
/// Changing the preference never reloads cards or resets navigation: it
/// only changes the trait the dynamic colors resolve against.
enum ThemeResolver {
    /// Screenshot-test hook: -AppleInterfaceStyle Light/Dark. Only present
    /// under UI tests; normal launches return nil.
    static var forcedColorScheme: ColorScheme? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-AppleInterfaceStyle"), i + 1 < args.count else { return nil }
        return args[i + 1] == "Dark" ? .dark : .light
    }

    /// Screenshot-test hook: -UIPreferredContentSizeCategoryName.
    static var forcedDynamicTypeSize: DynamicTypeSize? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-UIPreferredContentSizeCategoryName"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "UICTContentSizeCategoryAccessibilityMedium": return .accessibility1
        case "UICTContentSizeCategoryAccessibilityLarge": return .accessibility2
        case "UICTContentSizeCategoryAccessibilityExtraLarge": return .accessibility3
        case "UICTContentSizeCategoryAccessibilityExtraExtraLarge": return .accessibility4
        case "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge": return .accessibility5
        default: return .accessibility3
        }
    }

    static func resolvedColorScheme(preference: AppThemePreference) -> ColorScheme? {
        forcedColorScheme ?? preference.colorScheme
    }
}
