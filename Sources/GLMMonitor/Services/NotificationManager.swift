import Foundation
import UserNotifications

struct AlertThreshold: Hashable {
    let metric: String // "session" or "daily"
    let threshold: Int // 80 or 90
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private var firedAlerts = Set<AlertThreshold>()

    private override init() {
        super.init()
    }

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                NSLog("[GLMMonitor] Notification auth error: \(error.localizedDescription)")
            } else {
                NSLog("[GLMMonitor] Notification auth granted: \(granted)")
            }
        }
    }

    func checkAndNotify(metric: String, percentage: Int, previousPercentage: Int?) {
        let thresholds = [80, 90]

        for threshold in thresholds {
            let alert = AlertThreshold(metric: metric, threshold: threshold)
            let crossed = percentage >= threshold
            let wasBelow = (previousPercentage ?? 0) < threshold

            if crossed && wasBelow && !firedAlerts.contains(alert) {
                firedAlerts.insert(alert)
                sendNotification(metric: metric, threshold: threshold, percentage: percentage)
            }

            // Auto-clear when percentage drops below threshold (period reset)
            if !crossed {
                firedAlerts.remove(alert)
            }
        }
    }

    private func sendNotification(metric: String, threshold: Int, percentage: Int) {
        let content = UNMutableNotificationContent()
        let metricLabel = metric == "session" ? "Session" : "Daily"
        content.title = "GLM Monitor Alert"
        content.body = "\(metricLabel) usage has reached \(percentage)% (threshold: \(threshold)%)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "glm-\(metric)-\(threshold)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("[GLMMonitor] Notification error: \(error.localizedDescription)")
            }
        }
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
