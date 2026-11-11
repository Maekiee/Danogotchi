#if DEBUG
import UIKit

// UI 테스트용 단어별 학습 기록 예시
private struct StudyStatsExample {
    let word: String
    let meaning: String
    let topic: String
    let part: String
    let total: Int
    let correct: Int
}

extension UITestingSupport {
    private static var studyStatsScenario: String? {
        ProcessInfo.processInfo.environment["STUDY_STATS_UI_TEST"]
    }

    // 저장소 변경 없이 실제 통계 Coordinator로 진입
    @MainActor
    static func startStudyStatsIfRequested(window: UIWindow, container: AppDIContainer) -> MainCoordinator? {
        guard studyStatsScenario != nil else { return nil }
        let navigation = UINavigationController(rootViewController: UIViewController())
        let coordinator = MainCoordinator(container: container.makeMainDIContainer(), navigationController: navigation)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        DispatchQueue.main.async { coordinator.didTapCalendarButton() }
        return coordinator
    }

    static func makeStudyStatsFeatureIfRequested(
        onClose: @escaping @MainActor @Sendable () -> Void,
        onNavigate: @escaping @MainActor @Sendable (StudyStatsDestination) -> Void
    ) -> StudyStatsFeature? {
        guard let scenario = studyStatsScenario,
              let timeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let fixedCalendar = calendar
        guard let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 12)) else { return nil }
        let examples = [
            StudyStatsExample(word: "journey", meaning: "여행", topic: "travel", part: "noun", total: 342, correct: 267),
            StudyStatsExample(word: "efficient", meaning: "효율적인", topic: "business", part: "adj", total: 5, correct: 5),
            StudyStatsExample(word: "prepare", meaning: "준비하다", topic: "life", part: "verb", total: 4, correct: 1),
            StudyStatsExample(word: "moment", meaning: "순간", topic: "unknown", part: "noun", total: 3, correct: 2),
            StudyStatsExample(word: "happily", meaning: "행복하게", topic: "unknown", part: "adv", total: 2, correct: 1)
        ]
        let histories = examples.flatMap { example in
            let wordID = UUID()
            return (0..<example.total).map { index in
                LearningHistory(
                    id: UUID(), vocabId: wordID, isCorrect: index < example.correct,
                    createAt: now.addingTimeInterval(-Double(example.total - index)),
                    wordSnapshot: example.word, meaningSnapshot: example.meaning,
                    topicSnapshot: example.topic, partOfSpeechSnapshot: example.part
                )
            }
        }
        let records = StudyStatsRecords(histories: scenario == "empty" ? [] : histories, sessions: [])
        return StudyStatsFeature(
            fetch: { now, calendar in
                if scenario == "error" { throw CocoaError(.fileReadUnknown) }
                return DefaultFetchStudyStatsUseCase.aggregate(records, now: now, calendar: calendar)
            },
            reportError: { _ in }, onClose: onClose, onNavigate: onNavigate,
            now: { now }, calendar: { fixedCalendar }
        )
    }
}
#endif
