import SwiftUI
import HealthCore

@main
struct HealthWatchApp: App {
    @StateObject private var store = WatchHealthStore()
    var body: some Scene {
        WindowGroup { WatchDashboard().environmentObject(store) }
    }
}

private enum WatchPalette {
    static let mint = Color(red: 0.31, green: 0.92, blue: 0.79)
    static let pink = Color(red: 1, green: 0.43, blue: 0.49)
    static let secondary = Color.white.opacity(0.60)
}

struct WatchDashboard: View {
    @EnvironmentObject private var store: WatchHealthStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("健康中枢").font(.headline.weight(.bold)).foregroundStyle(.white)
                        Text("WATCH HEALTH").font(.system(size: 9, weight: .bold))
                            .tracking(1.4).foregroundStyle(WatchPalette.mint)
                    }
                    Spacer()
                    Image(systemName: "heart.text.square.fill").foregroundStyle(WatchPalette.mint)
                }
                pulseCard
                HStack(spacing: 8) {
                    smallCard("HRV", id: "hrv", unit: "ms", symbol: "waveform.path.ecg")
                    smallCard("血氧", id: "oxygenSaturation", unit: "%", symbol: "lungs.fill")
                }
                HStack(spacing: 8) {
                    smallCard("呼吸频率", id: "respiratoryRate", unit: "次/分", symbol: "wind")
                    smallCard("静息心率", id: "restingHeartRate", unit: "次/分", symbol: "heart.text.square")
                }
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Label("昨夜睡眠", systemImage: "moon.stars.fill")
                            .font(.caption.weight(.semibold)).foregroundStyle(WatchPalette.mint)
                        Spacer()
                        if let sleep = store.sleep, sleep.totalAsleepMinutes > 0 {
                            Text("\(sleep.totalAsleepMinutes / 60)小时\(sleep.totalAsleepMinutes % 60)分")
                                .font(.caption.weight(.bold)).foregroundStyle(.white)
                        } else {
                            Text("暂无记录").font(.caption2).foregroundStyle(WatchPalette.secondary)
                        }
                    }
                    if let sleep = store.sleep, sleep.totalAsleepMinutes > 0 {
                        GeometryReader { geo in
                            HStack(spacing: 2) {
                                ForEach(SleepStage.allCases, id: \.self) { stage in
                                    let minutes = sleep.minutesByStage[stage, default: 0]
                                    if minutes > 0 {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(stageColor(stage))
                                            .frame(width: max(1, geo.size.width * CGFloat(minutes) / CGFloat(max(1, sleep.totalAsleepMinutes + sleep.minutesAwake)) - 2))
                                    }
                                }
                            }
                        }.frame(height: 7)
                    }
                }.padding(11)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                if store.isLoading { ProgressView().frame(maxWidth: .infinity) }
                Button { Task { await store.authorize() } } label: {
                    Label("授权健康数据", systemImage: "lock.open.fill")
                        .font(.caption.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(WatchPalette.mint).foregroundStyle(.black)
                Button { Task { await store.refresh() } } label: {
                    Label("刷新记录", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.bordered).disabled(store.isLoading)
                Text("仅显示已有系统记录，非实时医疗监护。")
                    .font(.system(size: 10)).foregroundStyle(WatchPalette.secondary)
            }.padding(.horizontal, 8).padding(.bottom, 10)
        }
        .containerBackground(.black, for: .navigation)
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) { Button("好的", role: .cancel) { store.errorMessage = nil } }
        message: { Text(store.errorMessage ?? "") }
    }
    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .deep: return Color(red: 0.34, green: 0.37, blue: 0.90)
        case .core: return Color(red: 0.40, green: 0.65, blue: 0.96)
        case .rem: return Color(red: 0.67, green: 0.45, blue: 0.96)
        case .awake: return Color(red: 0.96, green: 0.58, blue: 0.62)
        case .unspecified: return Color.gray
        }
    }

    private var pulseCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("心率", systemImage: "heart.fill")
                    .font(.caption).foregroundStyle(WatchPalette.pink)
                Spacer()
                Text("最近记录").font(.system(size: 9)).foregroundStyle(WatchPalette.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.readings["heartRate"].map { String(Int($0.value.rounded())) } ?? "—")
                    .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("BPM").font(.caption2).foregroundStyle(WatchPalette.secondary)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.title3).foregroundStyle(WatchPalette.pink)
            }
        }.padding(13)
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(LinearGradient(colors: [Color(red: 0.22, green: 0.13, blue: 0.19), Color(red: 0.11, green: 0.12, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                     in: RoundedRectangle(cornerRadius: 18))
    }
    private func smallCard(_ title: String, id: String, unit: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).foregroundStyle(WatchPalette.mint).font(.caption)
            Text(title).font(.system(size: 10)).foregroundStyle(WatchPalette.secondary).lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(store.readings[id].map { String(format: "%.1f", $0.value) } ?? "—")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6).lineLimit(1)
                if store.readings[id] != nil {
                    Text(unit).font(.system(size: 8)).foregroundStyle(WatchPalette.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(11).frame(maxWidth: .infinity, minHeight: 91, alignment: .leading)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
    }
}
