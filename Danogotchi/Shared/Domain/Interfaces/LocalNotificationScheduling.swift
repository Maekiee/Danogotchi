import Foundation

/// 로컬 알림 예약에 대한 도메인 인터페이스. 시각·문구 결정은 `StudyReminderPolicy`가 하고 여기는 전달만 한다.
protocol LocalNotificationScheduling {
    func schedule(_ reminder: StudyReminderPolicy.Reminder)
    func cancel(ids: [String])
}
