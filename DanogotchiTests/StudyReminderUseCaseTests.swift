import CoreData
import XCTest
@testable import Danogotchi

final class StudyReminderUseCaseTests: XCTestCase {
    private let now = testBase
    private let studiedAt = hoursAgo(1)

    private enum Event: Equatable {
        case cancel([String])
        case schedule(StudyReminderPolicy.Reminder)
    }

    private final class RecordingNotificationScheduler: LocalNotificationScheduling {
        private(set) var events: [Event] = []
        func schedule(_ reminder: StudyReminderPolicy.Reminder) { events.append(.schedule(reminder)) }
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
            scheduler: scheduler,
            now: { [now] in now }
        )
        return SUT(useCase: useCase, settings: settings, scheduler: scheduler, context: context)
    }

    private func recordStudy(in context: NSManagedObjectContext) throws {
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        try DefaultLearningHistoryRepository(context: context).addHistory(makeQuizAnswer(word, createAt: studiedAt))
    }

    /// 같은 기준 시각으로 정책이 돌려주는 알림 — 시각까지 비교한다
    private func expectedSchedules(studied: Bool) -> [Event] {
        StudyReminderPolicy.reminders(lastStudiedAt: studied ? studiedAt : nil, now: now).map { .schedule($0) }
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

    func test_refreshWhileDisabledOnlyCancels() throws {
        let sut = makeSUT(enabled: false)

        try sut.useCase.refresh()

        XCTAssertEqual(sut.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)])
    }

    func test_refreshWhileEnabledReschedulesFromLastStudy() throws {
        let sut = makeSUT(enabled: true)
        try recordStudy(in: sut.context)

        try sut.useCase.refresh()

        XCTAssertEqual(sut.scheduler.events, [.cancel(StudyReminderPolicy.allIdentifiers)] + expectedSchedules(studied: true))
    }
}
