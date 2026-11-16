import SwiftUI

@main
struct HealthIntelligenceApp: App {
    @StateObject private var health = HealthViewModel()
    @StateObject private var journal = JournalStore()

    init() { _ = WatchStatusReceiver.shared }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .environmentObject(journal)
                .tint(HealthTheme.teal)
        }
    }
}
