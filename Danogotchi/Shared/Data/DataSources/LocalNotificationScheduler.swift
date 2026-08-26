import Foundation
import UserNotifications
import OSLog

/// 같은 identifier로 add하면 기존 예약이 대체되므로, 재예약이 곧 갱신이다.
final class LocalNotificationScheduler: LocalNotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func schedule(_ reminder: StudyReminderPolicy.Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminder.id,
            content: content,
            trigger: UNCalendarNotificationTrigger(
                dateMatching: reminder.dateComponents,
                repeats: reminder.repeats
            )
        )

        center.add(request) { error in
            if let error {
                AppLogger.push.error("로컬 알림 예약 실패: \(String(describing: error), privacy: .public)")
                CrashReporter.record(error)
            }
        }
    }

    func cancel(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
