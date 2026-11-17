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

    // MARK: - V3 dual-theme tokens (GitHub Issue #2, 2026-11-17)
    //
    // Light mode: glacier white / mist blue. Dark mode: deep sea blue.
    // Exact hex from the V3 spec; do not change without a new spec.
    // Muted light (#60718A) passes 4.5:1 on card (#FFFFFF, 4.97:1) and
    // canvas (#F6F9FF, 4.71:1) but is 4.45:1 on the secondary background
    // (#EDF3FB), so never put muted text on v3SurfaceSecondary.
    public static let v3Canvas = Token(hexLight: 0xF6F9FF, hexDark: 0x07111F)
    public static let v3SurfaceSecondary = Token(hexLight: 0xEDF3FB, hexDark: 0x172B45)
    public static let v3Card = Token(hexLight: 0xFFFFFF, hexDark: 0x101F33)
    public static let v3Ink = Token(hexLight: 0x14243A, hexDark: 0xF5F8FF)
    public static let v3Muted = Token(hexLight: 0x60718A, hexDark: 0x9AABC3)
    public static let v3Line = Token(hexLight: 0xDDE6F2, hexDark: 0x29415E)

    /// A V3 semantic color. `base` is the spec hex, used for rings, fills
    /// and icons in both modes. `textLight` is a darkened variant used for
    /// TEXT on light backgrounds only: every base hex fails WCAG 4.5:1 as
    /// light-mode text (brand 3.33, sleep 3.13, recovery 1.83, stress 1.71,
    /// energy 1.76, load 3.40, risk 2.84 on white), so light-mode text must
    /// use the darkened variant. `textDark` equals `base`: every base hex
    /// passes 4.5:1 as text on the dark card (#101F33: brand 4.99, sleep
    /// 5.29, recovery 9.08, stress 9.73, energy 9.44, load 4.87, risk 5.83).
    /// textLight variants were verified by computation against white,
    /// #F6F9FF and #EDF3FB (all >= 4.5:1): brand #1B5FC7 (5.99/5.68/5.36),
    /// sleep #6A4FD0 (5.77/5.47/5.17), recovery #0B7A55 (5.34/5.07/4.79),
    /// stress #0A6E85 (5.86/5.56/5.25), energy #8A5A00 (5.93/5.62/5.31),
    /// load #6E33D6 (6.76/6.41/6.05), risk #C22E42 (5.58/5.29/5.00).
    public struct V3Semantic: Equatable, Sendable {
        public let base: RGB
        public let textLight: RGB
        public var textDark: RGB { base }
        public init(base: Int, textLight: Int) {
            self.base = RGB(hex: base)
            self.textLight = RGB(hex: textLight)
        }
    }

    public static let v3Brand = V3Semantic(base: 0x398BFF, textLight: 0x1B5FC7)
    public static let v3Sleep = V3Semantic(base: 0x9A7CFF, textLight: 0x6A4FD0)
    public static let v3Recovery = V3Semantic(base: 0x20D9A0, textLight: 0x0B7A55)
    public static let v3Stress = V3Semantic(base: 0x39D8F5, textLight: 0x0A6E85)
    public static let v3Energy = V3Semantic(base: 0xFFB547, textLight: 0x8A5A00)
    public static let v3Load = V3Semantic(base: 0xA46CFF, textLight: 0x6E33D6)
    public static let v3Risk = V3Semantic(base: 0xFF6578, textLight: 0xC22E42)
}
