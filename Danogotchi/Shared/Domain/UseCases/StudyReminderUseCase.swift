import Foundation

protocol StudyReminderUseCase {
    /// 사용자가 학습 알림을 켜둔 상태인지
    var isEnabled: Bool { get }
    /// 설정을 저장하고 즉시 재예약한다.
    func setEnabled(_ isEnabled: Bool)
    /// 현재 설정·마지막 학습 시각을 기준으로 재예약한다. (앱 시작 / 퀴즈 완료)
    func refresh()
}

final class DefaultStudyReminderUseCase: StudyReminderUseCase {
    private let userInfo: UserInfoProtocol
    private let learningHistoryRepository: LearningHistoryRepository
    private let scheduler: LocalNotificationScheduling

    init(
        userInfo: UserInfoProtocol,
        learningHistoryRepository: LearningHistoryRepository,
        scheduler: LocalNotificationScheduling
    ) {
        self.userInfo = userInfo
        self.learningHistoryRepository = learningHistoryRepository
        self.scheduler = scheduler
    }

    var isEnabled: Bool {
        return userInfo.isStudyReminderEnabled
    }

    func setEnabled(_ isEnabled: Bool) {
        userInfo.isStudyReminderEnabled = isEnabled
        refresh()
    }

    /// 우리가 만든 id만 취소한다 — FCM 원격 푸시와 무관하다.
    func refresh() {
        scheduler.cancel(ids: StudyReminderPolicy.allIdentifiers)
        guard userInfo.isStudyReminderEnabled else { return }

        // ponytail: 전체 이력을 메모리에 올린다. 호출 시점이 앱 시작·퀴즈 종료·토글뿐이라 감수한다.
        //           행 수가 문제되면 LearningHistoryRepository에 fetchLimit 1 descending 조회를 추가한다.
        let lastStudiedAt = learningHistoryRepository.fetchAllHistory().last?.createAt

        StudyReminderPolicy
            .reminders(lastStudiedAt: lastStudiedAt, now: Date())
            .forEach { scheduler.schedule($0) }
    }
}
