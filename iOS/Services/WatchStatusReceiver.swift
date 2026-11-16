import Foundation
import WatchConnectivity

/// Receive Watch app activity timestamps; do not transfer health measurements.
final class WatchStatusReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchStatusReceiver()
    private(set) var lastRefresh: Date?
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let timestamp = applicationContext["watchLastRefresh"] as? Double {
            DispatchQueue.main.async { self.lastRefresh = Date(timeIntervalSince1970: timestamp) }
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
