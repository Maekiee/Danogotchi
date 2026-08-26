import Foundation

/// 학습 리마인더 알림의 시각·문구 정책. 외부 의존이 없는 순수 계산이라 UseCase가 아니다.
enum StudyReminderPolicy {
    /// 매일 리마인더 발화 시각 — 아침·저녁 2회
    static let dailyHours = [8, 18]
    /// 미학습 알림 발화 시각 — 매일 리마인더(8·18시)와 시각을 분리해 같은 시점에 배너가 겹치는 것을 원천 차단한다
    static let inactivityHour = 13
    /// 마지막 학습 이후 이 일수가 지나면 미학습 알림을 보낸다
    static let inactivityDays = 1

    struct Reminder: Equatable {
        let id: String
        let title: String
        let body: String
        let dateComponents: DateComponents
        let repeats: Bool
    }

    private enum Identifier {
        static func daily(hour: Int) -> String { "studyReminder.daily.\(hour)" }
        static let inactivity = "studyReminder.inactivity"
    }

    /// 시각별로 id가 갈리므로 취소 목록도 `dailyHours`에서 파생시킨다 — 상수를 늘려도 취소가 누락되지 않는다
    static let allIdentifiers = dailyHours.map(Identifier.daily(hour:)) + [Identifier.inactivity]

    /// 지금 예약해야 할 알림 전체.
    /// 학습 이력이 없으면 미학습 알림은 만들지 않는다 — 신규 사용자에게 "어제 학습을 쉬었다"는 거짓이다.
    static func reminders(
        lastStudiedAt: Date?,
        now: Date,
        calendar: Calendar = .current
    ) -> [Reminder] {
        var reminders = dailyReminders

        guard let lastStudiedAt,
              let due = calendar.date(byAdding: .day, value: inactivityDays, to: lastStudiedAt),
              let fireDate = calendar.nextDate(
                  after: max(due, now),
                  matching: DateComponents(hour: inactivityHour, minute: 0),
                  matchingPolicy: .nextTime
              )
        else { return reminders }

        reminders.append(inactivity(at: fireDate, calendar: calendar))
        return reminders
    }

    /// 아침·저녁 문구는 같다. 시각별 카피가 필요해지면 `dailyHours`를 (시각, 문구) 배열로 바꾼다.
    private static var dailyReminders: [Reminder] {
        return dailyHours.map { hour in
            Reminder(
                id: Identifier.daily(hour: hour),
                title: "오늘의 단어 학습",
                body: "잠깐 시간 내서 단어 몇 개만 외워볼까요?",
                dateComponents: DateComponents(hour: hour, minute: 0),
                repeats: true
            )
        }
    }

    /// 발화 시각이 지정된 1회성 알림. `max(due, now)` 이후로 잡히므로 과거 시각을 예약하지 않는다.
    private static func inactivity(at fireDate: Date, calendar: Calendar) -> Reminder {
        return Reminder(
            id: Identifier.inactivity,
            title: "다노가 기다려요",
            body: "어제 학습을 쉬었어요. 단어장을 열어볼까요?",
            dateComponents: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            ),
            repeats: false
        )
    }
}
