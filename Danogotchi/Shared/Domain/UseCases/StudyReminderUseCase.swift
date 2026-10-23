import Foundation

protocol StudyReminderUseCase {
    /// 사용자가 학습 알림을 켜둔 상태인지
    var isEnabled: Bool { get }
    /// 설정을 저장하고 즉시 재예약한다.
    func setEnabled(_ isEnabled: Bool) throws
    /// 현재 설정·마지막 학습 시각을 기준으로 재예약한다. (앱 시작 / 퀴즈 완료)
    func refresh() throws
}

final class DefaultStudyReminderUseCase: StudyReminderUseCase {
    private let userSettings: UserSettingsRepository
    private let learningHistoryRepository: LearningHistoryRepository
    private let scheduler: LocalNotificationScheduling

    init(
        userSettings: UserSettingsRepository,
        learningHistoryRepository: LearningHistoryRepository,
        scheduler: LocalNotificationScheduling
    ) {
        self.userSettings = userSettings
        self.learningHistoryRepository = learningHistoryRepository
        self.scheduler = scheduler
    }

    var isEnabled: Bool {
        return userSettings.isStudyReminderEnabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        let lastStudiedAt = isEnabled ? try learningHistoryRepository.fetchAllHistory().last?.createAt : nil
        userSettings.isStudyReminderEnabled = isEnabled
        schedule(lastStudiedAt: lastStudiedAt)
    }

    func refresh() throws {
        let lastStudiedAt = userSettings.isStudyReminderEnabled ? try learningHistoryRepository.fetchAllHistory().last?.createAt : nil
        schedule(lastStudiedAt: lastStudiedAt)
    }

    private func schedule(lastStudiedAt: Date?) {
        scheduler.cancel(ids: StudyReminderPolicy.allIdentifiers)
        guard userSettings.isStudyReminderEnabled else { return }
        StudyReminderPolicy
            .reminders(lastStudiedAt: lastStudiedAt, now: Date())
            .forEach { scheduler.schedule($0) }
    }
}
