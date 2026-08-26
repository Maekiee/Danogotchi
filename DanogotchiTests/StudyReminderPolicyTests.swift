import XCTest
@testable import Danogotchi


final class StudyReminderPolicyTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar, year: year, month: month, day: day, hour: hour, minute: minute
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    func test_학습_이력이_없으면_매일_알림_두_건만_예약한다() {
        let reminders = StudyReminderPolicy.reminders(
            lastStudiedAt: nil,
            now: date(2026, 8, 26, 10),
            calendar: calendar
        )

        XCTAssertEqual(reminders.count, 2)
        XCTAssertEqual(reminders.map { $0.dateComponents.hour }, [8, 18])
        XCTAssertTrue(reminders.allSatisfy(\.repeats))
        // 반복 알림이므로 날짜는 지정하지 않는다
        XCTAssertTrue(reminders.allSatisfy { $0.dateComponents.day == nil })
    }

    func test_마지막_학습_하루_뒤_13시에_미학습_알림을_예약한다() {
        let reminders = StudyReminderPolicy.reminders(
            lastStudiedAt: date(2026, 8, 26, 9),
            now: date(2026, 8, 26, 10),
            calendar: calendar
        )

        XCTAssertEqual(reminders.count, 3)

        let inactivity = reminders[2].dateComponents
        XCTAssertEqual(inactivity.year, 2026)
        XCTAssertEqual(inactivity.month, 8)
        XCTAssertEqual(inactivity.day, 27)
        XCTAssertEqual(inactivity.hour, StudyReminderPolicy.inactivityHour)
        XCTAssertFalse(reminders[2].repeats)
    }

    func test_마지막_학습이_오래_전이면_과거가_아닌_다음_13시에_예약한다() {
        // 발화 기준일(8/11)이 이미 지났다 — 지금(8/26 15시) 이후의 다음 13시인 8/27로 잡혀야 한다
        let reminders = StudyReminderPolicy.reminders(
            lastStudiedAt: date(2026, 8, 10, 9),
            now: date(2026, 8, 26, 15),
            calendar: calendar
        )

        let inactivity = reminders[2].dateComponents
        XCTAssertEqual(inactivity.month, 8)
        XCTAssertEqual(inactivity.day, 27)
        XCTAssertEqual(inactivity.hour, StudyReminderPolicy.inactivityHour)
    }

    func test_모든_알림의_시각과_식별자가_겹치지_않는다() {
        let hours = StudyReminderPolicy.dailyHours + [StudyReminderPolicy.inactivityHour]
        XCTAssertEqual(Set(hours).count, hours.count)

        let reminders = StudyReminderPolicy.reminders(
            lastStudiedAt: date(2026, 8, 26, 9),
            now: date(2026, 8, 26, 10),
            calendar: calendar
        )

        XCTAssertEqual(Set(reminders.map(\.id)).count, reminders.count)
        XCTAssertEqual(Set(reminders.map(\.id)), Set(StudyReminderPolicy.allIdentifiers))
    }
}
