import Foundation

/// Semantic color tokens (DESIGN_SYSTEM_V2), as light/dark RGB triples.
/// Pure data on purpose: no SwiftUI or UIKit here, so HealthCore stays a
/// logic-only package that still compiles on macOS for unit tests. Each app
/// target resolves these through its own tiny helper (HealthTheme on iOS,
/// WatchTheme on watchOS). The hex values are the single source of truth;
/// no view may hard-code a brand color.
public enum HealthDesignTokens {
    public struct RGB: Equatable, Sendable {
        public let red: Double
        public let green: Double
        public let blue: Double
        public init(_ red: Double, _ green: Double, _ blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
        /// Exact sRGB hex, e.g. RGB(hex: 0x125E63).
        public init(hex: Int) {
            self.red = Double((hex >> 16) & 0xFF) / 255
            self.green = Double((hex >> 8) & 0xFF) / 255
            self.blue = Double(hex & 0xFF) / 255
        }
    }

    public struct Token: Equatable, Sendable {
        public let light: RGB
        public let dark: RGB
        public init(light: RGB, dark: RGB) {
            self.light = light
            self.dark = dark
        }
        public init(hexLight: Int, hexDark: Int) {
            self.light = RGB(hex: hexLight)
            self.dark = RGB(hex: hexDark)
        }
    }

    public static let jade = Token(hexLight: 0x125E63, hexDark: 0x1A777B)
    public static let teal = Token(hexLight: 0x14A38E, hexDark: 0x23CCB0)
    public static let heart = Token(hexLight: 0xE04A54, hexDark: 0xFF7A85)
    public static let sleep = Token(hexLight: 0x5C64C7, hexDark: 0x959CFF)
    public static let amber = Token(hexLight: 0xCA7A30, hexDark: 0xF0AD60)
    /// Sky has no dark value in the spec; the dark value is a brightened sky
    /// chosen for dark backgrounds, documented here rather than guessed inline.
    public static let sky = Token(hexLight: 0x5CA6DE, hexDark: 0x8CC3EE)
    public static let ink = Token(hexLight: 0x142932, hexDark: 0xF0F7F7)
    public static let muted = Token(hexLight: 0x667A83, hexDark: 0xA7BABC)
    public static let canvas = Token(hexLight: 0xF6F9F7, hexDark: 0x0E161A)
    public static let surface = Token(hexLight: 0xFFFFFF, hexDark: 0x1B282B)

    /// Sleep stage colors, shared by iPhone and Watch so the five stages
    /// always mean the same thing on both devices. Labels always accompany
    /// the colors; no state is ever carried by color alone.
    public static func stageToken(for stage: SleepStage) -> Token {
        switch stage {
        case .deep: return sleep
        case .core: return sky
        case .rem: return teal
        case .unspecified: return muted
        case .awake: return amber
        }
    }
}
