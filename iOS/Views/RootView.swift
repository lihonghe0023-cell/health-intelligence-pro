import SwiftUI
import HealthCore

struct RootView: View {
    @EnvironmentObject private var health: HealthViewModel
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            OverviewView().tabItem { Label("今日", systemImage: "square.grid.2x2.fill") }
            HeartView().tabItem { Label("心脏", systemImage: "heart.text.square.fill") }
            SleepView().tabItem { Label("睡眠", systemImage: "moon.stars.fill") }
            RecordsView().tabItem { Label("健康库", systemImage: "cross.case.fill") }
            ReportView().tabItem { Label("报告", systemImage: "doc.text.image.fill") }
        }
        .tint(HealthTheme.teal)
        .sheet(isPresented: $showOnboarding) { WelcomeHealthView() }
        .onAppear {
            // Screenshot-test hook: reset onboarding so each display mode
            // starts at the welcome screen. Only active when the test
            // passes -resetOnboardingForScreenshots as a launch argument.
            if ProcessInfo.processInfo.arguments.contains("-resetOnboardingForScreenshots") {
                onboardingComplete = false
            }
            if !onboardingComplete { showOnboarding = true }
        }
        .alert("提示", isPresented: Binding(
            get: { health.message != nil },
            set: { if !$0 { health.message = nil } }
        )) {
            Button("好的", role: .cancel) { health.message = nil }
        } message: { Text(health.message ?? "") }
    }
}

struct OverviewView: View {
    @EnvironmentObject private var health: HealthViewModel
    @State private var showSettings = false
    private let primary = ["restingHeartRate", "hrv", "oxygenSaturation", "respiratoryRate"]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    pageHeading
                    hero
                    if health.readings.isEmpty {
                        HealthCard {
                            VStack(alignment: .leading, spacing: 13) {
                                Label("连接 Apple 健康", systemImage: "heart.text.clipboard")
                                    .font(.headline).foregroundStyle(HealthTheme.ink)
                                Text("授权后读取真实健康记录。未授权、没有记录或设备不支持时，都会保持空状态，不生成测试数值。")
                                    .font(.subheadline).foregroundStyle(HealthTheme.muted)
                                HealthPrimaryButton(
                                    title: health.isLoading ? "正在请求授权" : "授权并读取数据",
                                    icon: "lock.open.fill",
                                    state: health.isLoading ? .loading : .idle,
                                    disabled: !health.isHealthAvailable
                                ) {
                                    Task { await health.connectAndRefresh() }
                                }
                            }
                        }
                    }
                    SectionHeadline(title: "核心生命体征", subtitle: "数据直接来自 Apple 健康")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(primary, id: \.self) { id in
                            if let metric = HealthCatalog.byID[id] {
                                NavigationLink { MetricDetailView(metric: metric) } label: {
                                    MetricTile(metric: metric, reading: health.readings[id])
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    SectionHeadline(title: "睡眠与恢复", subtitle: "最近记录，不等于医疗诊断")
                    HealthCard {
                        HStack(alignment: .center, spacing: 14) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.title2).foregroundStyle(HealthTheme.indigo)
                                .frame(width: 52, height: 52)
                                .background(HealthTheme.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 5) {
                                Text("最近一次睡眠").font(.caption).foregroundStyle(HealthTheme.muted)
                                if let sleep = health.sleep, sleep.totalAsleepMinutes > 0 {
                                    Text("\(sleep.totalAsleepMinutes / 60) 小时 \(sleep.totalAsleepMinutes % 60) 分")
                                        .font(.title3.bold()).foregroundStyle(HealthTheme.ink)
                                } else {
                                    Text("尚无睡眠记录").font(.headline).foregroundStyle(HealthTheme.ink)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(HealthTheme.muted)
                        }
                    }
                    SectionHeadline(title: "健康观察", subtitle: "可追溯的本地解释，不使用虚构评分")
                    ForEach(health.insights.prefix(3)) { insight in
                        HealthCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .foregroundStyle(HealthTheme.teal).font(.title3)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(insight.title).font(.headline).foregroundStyle(HealthTheme.ink)
                                    Text(insight.body).font(.subheadline).foregroundStyle(HealthTheme.muted)
                                }
                            }
                        }
                    }
                    Text("本产品用于健康记录与趋势理解，不提供急救监护或疾病诊断。出现胸痛、严重呼吸困难等症状，应立即寻求急救。")
                        .font(.footnote).foregroundStyle(HealthTheme.muted)
                }.padding(.horizontal, 18).padding(.bottom, 28)
            }
            .background(HealthTheme.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { Task { await health.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("刷新健康数据").disabled(health.isLoading)
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("设置与隐私")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .refreshable { await health.refresh() }
            .task { if health.lastRefreshedAt == nil && UserDefaults.standard.bool(forKey: "onboardingComplete") { await health.refresh() } }
        }
    }

    private var pageHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("HEALTH INTELLIGENCE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(2).foregroundStyle(HealthTheme.teal)
                Spacer()
                HealthPill(title: "本机私密", icon: "lock.shield.fill")
            }
            Text("读懂身体的每一天")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(HealthTheme.ink).minimumScaleFactor(0.85)
            Text(Date.now.formatted(.dateTime.year().month(.wide).day().weekday(.wide)))
                .font(.subheadline).foregroundStyle(HealthTheme.muted)
        }.padding(.top, 16)
    }

    private var hero: some View {
        HealthHero {
            ZStack(alignment: .topLeading) {
                Circle().fill(.white.opacity(0.055)).frame(width: 210, height: 210)
                    .offset(x: 210, y: -110).blur(radius: 5)
                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 8) {
                        Circle().fill(HealthTheme.teal).frame(width: 7, height: 7)
                        Text("HEALTH SNAPSHOT")
                            .font(.caption2.weight(.bold)).tracking(2).foregroundStyle(.white.opacity(0.72))
                        Spacer()
                        Image(systemName: "heart.fill").foregroundStyle(.white.opacity(0.85))
                    }
                    Text("身体的变化，值得被看见。")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                    AbstractWave().stroke(LinearGradient(colors: [.white.opacity(0.6), HealthTheme.teal], startPoint: .leading, endPoint: .trailing),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .frame(height: 58)
                        .accessibilityHidden(true)
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("健康记录")
                                .font(.caption2).foregroundStyle(.white.opacity(0.68))
                            Text(health.readings.isEmpty ? "等待同步" : "\(health.readings.count) 项指标已读取")
                                .font(.headline).foregroundStyle(.white)
                        }
                        Spacer()
                        Text(health.lastRefreshedAt.map { "更新于 \($0.formatted(date: .omitted, time: .shortened))" } ?? "未读取")
                            .font(.caption2).foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
