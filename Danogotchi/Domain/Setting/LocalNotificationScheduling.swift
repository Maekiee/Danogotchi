import Foundation

protocol LocalNotificationScheduling {
    func schedule(_ reminder: StudyReminderPolicy.Reminder)
    func cancel(ids: [String])
}
