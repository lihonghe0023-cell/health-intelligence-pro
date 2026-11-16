import Foundation
import WatchConnectivity

/// Only sends a refresh timestamp, never health measurements.
final class WatchStatusBridge: NSObject, WCSessionDelegate {
    static let shared = WatchStatusBridge()
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendRefreshDate(_ date: Date) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(["watchLastRefresh": date.timeIntervalSince1970])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}
