import CoreData
import XCTest
@testable import Danogotchi

final class StudyReminderUseCaseTests: XCTestCase {
    private enum Event: Equatable {
        case cancel([String])
        case schedule(String)
    }

    private final class RecordingNotificationScheduler: LocalNotificationScheduling {
        private(set) var events: [Event] = []
        func schedule(_ reminder: StudyReminderPolicy.Reminder) { events.append(.schedule(reminder.id)) }
        func cancel(ids: [String]) { events.append(.cancel(ids)) }
    }

    private struct SUT {
        let useCase: DefaultStudyReminderUseCase
        let settings: TestUserSettings
        let scheduler: RecordingNotificationScheduler
        let context: NSManagedObjectContext
    }

    private func makeSUT(enabled: Bool) -> SUT {
        let context = makeInMemoryContext()
        let settings = TestUserSettings()
        settings.isStudyReminderEnabled = enabled
        let scheduler = RecordingNotificationScheduler()
        let useCase = DefaultStudyReminderUseCase(
            userSettings: settings,
            learningHistoryRepository: DefaultLearningHistoryRepository(context: context),
            scheduler: scheduler
        )
        return SUT(useCase: useCase, settings: settings, scheduler: scheduler, context: context)
    }

    private func recordStudy(in context: NSManagedObjectContext) throws {
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        try DefaultLearningHistoryRepository(context: context).addHistory(makeQuizAnswer(word))
    }

    /// 정책이 지금 돌려주는 알림 id — 시각은 내부 `Date()`라 id만 비교한다
    private func expectedSchedules(studied: Bool) -> [Event] {
        StudyReminderPolicy.reminders(lastStudiedAt: studied ? Date() : nil, now: Date()).map { .schedule($0.id) }
    }

    func test_enablingCancelsEverythingThenSchedulesDailyAndInactivityWhenStudied() throws {
        let sut = makeSUT(enabled: false)
        try recordStudy(in: sut.context)

        try sut.useCase.setEnabled(true)

        XCTAssertTrue(sut.settings.isStudyReminderEnabled)
        XCTAssertTrue(sut.useCase.isEnabled)
        XCTAssertEqual(sut.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)] + expectedSchedules(studied: true))
        XCTAssertEqual(sut.scheduler.events.count, 4)
    }

    func test_enablingWithoutHistorySchedulesOnlyDailyReminders() throws {
        let sut = makeSUT(enabled: false)

        try sut.useCase.setEnabled(true)

        XCTAssertEqual(sut.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)] + expectedSchedules(studied: false))
        XCTAssertEqual(sut.scheduler.events.count, 3)
    }

    func test_disablingPersistsAndOnlyCancels() throws {
        let sut = makeSUT(enabled: true)
        try recordStudy(in: sut.context)

        try sut.useCase.setEnabled(false)

        XCTAssertFalse(sut.settings.isStudyReminderEnabled)
        XCTAssertEqual(sut.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)])
    }

    func test_refreshFollowsStoredSetting() throws {
        let disabled = makeSUT(enabled: false)
        try disabled.useCase.refresh()
        XCTAssertEqual(disabled.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)])

        let enabled = makeSUT(enabled: true)
        try recordStudy(in: enabled.context)
        try enabled.useCase.refresh()
        XCTAssertEqual(enabled.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)] + expectedSchedules(studied: true))
    }
}
