import SwiftUI
import UIKit
import HealthCore

/// Health Intelligence Design System 1.0 — contrast-aware, dynamic and content first.
enum HealthTheme {
    static let jade = Color(red: 0.07, green: 0.37, blue: 0.39)
    static let teal = Color(red: 0.08, green: 0.62, blue: 0.56)
    static let coral = Color(red: 0.88, green: 0.29, blue: 0.33)
    static let indigo = Color(red: 0.36, green: 0.39, blue: 0.78)
    static let amber = Color(red: 0.79, green: 0.48, blue: 0.19)
    static let mint = teal
    static let sky = Color(red: 0.36, green: 0.65, blue: 0.87)
    static let ink = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.94, green: 0.97, blue: 0.97, alpha: 1) : UIColor(red: 0.08, green: 0.16, blue: 0.20, alpha: 1) })
    static let muted = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.66, green: 0.73, blue: 0.75, alpha: 1) : UIColor(red: 0.40, green: 0.48, blue: 0.52, alpha: 1) })
    static let canvas = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.055, green: 0.085, blue: 0.10, alpha: 1) : UIColor(red: 0.963, green: 0.972, blue: 0.967, alpha: 1) })
    static let surface = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.105, green: 0.155, blue: 0.17, alpha: 1) : UIColor.white })
    static let line = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : UIColor(red: 0.84, green: 0.88, blue: 0.88, alpha: 1) })
}

struct HealthCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(HealthTheme.surface, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).strokeBorder(HealthTheme.line.opacity(0.65), lineWidth: 0.7))
            .accessibilityElement(children: .contain)
    }
}

struct SectionHeadline: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title3.weight(.bold)).foregroundStyle(HealthTheme.ink)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(HealthTheme.muted) }
            }
            Spacer()
        }.padding(.horizontal, 2)
    }
}

struct HealthPill: View {
    let title: String
    let icon: String
    var tint: Color = HealthTheme.teal
    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .foregroundStyle(tint)
            .background(tint.opacity(0.11), in: Capsule())
            .accessibilityLabel(title)
    }
}

struct MetricTile: View {
    let metric: HealthMetric
    let reading: MetricReading?
    var body: some View {
        HealthCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold)).foregroundStyle(HealthTheme.muted)
                }
                Text(metric.name).font(.caption.weight(.medium)).foregroundStyle(HealthTheme.muted).lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(reading.map { metric.display($0.value) } ?? "—")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(HealthTheme.ink)
                        .minimumScaleFactor(0.6).lineLimit(1)
                        .contentTransition(.numericText())
                    if reading != nil {
                        Text(metric.unitText).font(.caption2).foregroundStyle(HealthTheme.muted).lineLimit(1)
                    }
                }
                Text(reading.map { $0.recordedAt.formatted(date: .abbreviated, time: .shortened) }
                     ?? "暂无记录 · 可检查授权")
                    .font(.caption2).foregroundStyle(HealthTheme.muted).lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
    private var tint: Color {
        switch metric.group {
        case .heart: return HealthTheme.coral
        case .breathing: return HealthTheme.indigo
        case .body: return HealthTheme.teal
        case .mobility: return HealthTheme.amber
        case .environment: return HealthTheme.sky
        }
    }
}

struct PulseTrace: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let points: [CGFloat] = [0.49,0.49,0.48,0.47,0.50,0.49,0.46,0.45,0.48,0.55,0.27,0.78,0.48,0.48,0.47,0.48,0.46,0.48,0.47,0.47]
        for (i, v) in points.enumerated() {
            let x = rect.minX + CGFloat(i) / CGFloat(points.count-1) * rect.width
            let y = rect.minY + rect.height * v
            if i == 0 { p.move(to: CGPoint(x:x,y:y)) } else { p.addLine(to: CGPoint(x:x,y:y)) }
        }
        return p
    }
}

struct EmptyHealthState: View {
    let title: String
    let detail: String
    var symbol = "waveform.path.ecg"
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.title).foregroundStyle(HealthTheme.teal)
                .frame(width: 60, height: 60)
                .background(HealthTheme.teal.opacity(0.08), in: Circle())
            Text(title).font(.headline).foregroundStyle(HealthTheme.ink)
            Text(detail).font(.subheadline).foregroundStyle(HealthTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}

/// Shared primary action: minimum 48pt target, restrained press feedback and
/// no scale animation when the user enables Reduce Motion.
struct HealthPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(isEnabled ? HealthTheme.jade : HealthTheme.muted,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct HealthSourceBadge: View {
    let source: String
    let date: Date
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.shield.fill")
            Text(source).lineLimit(1)
            Text("·")
            Text(date, style: .relative)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(HealthTheme.muted)
        .accessibilityLabel("数据来自\(source)，记录于\(date.formatted())")
    }
}
