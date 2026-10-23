#if DEBUG
import UIKit

// UI 테스트용 단어별 학습 기록 예시
private struct StudyReportExample {
    let word: String
    let meaning: String
    let topic: String
    let part: String
    let total: Int
    let correct: Int
}

extension UITestingSupport {
    private static var studyReportScenario: String? {
        ProcessInfo.processInfo.environment["STUDY_REPORT_UI_TEST"]
    }

    // 저장소 변경 없이 실제 리포트 Coordinator로 진입
    @MainActor
    static func startStudyReportIfRequested(window: UIWindow, container: AppDIContainer) -> MainCoordinator? {
        guard studyReportScenario != nil else { return nil }
        let navigation = UINavigationController(rootViewController: UIViewController())
        let coordinator = MainCoordinator(container: container.makeMainDIContainer(), navigationController: navigation)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        DispatchQueue.main.async { coordinator.exploreVocabDidTapStudyReport() }
        return coordinator
    }

    static func makeStudyReportFeatureIfRequested(
        onClose: @escaping @MainActor @Sendable () -> Void,
        onNavigate: @escaping @MainActor @Sendable (StudyReportDestination) -> Void
    ) -> StudyReportFeature? {
        guard let scenario = studyReportScenario,
              let timeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let fixedCalendar = calendar
        guard let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 12)) else { return nil }
        let examples = [
            StudyReportExample(word: "journey", meaning: "여행", topic: "travel", part: "noun", total: 342, correct: 267),
            StudyReportExample(word: "efficient", meaning: "효율적인", topic: "business", part: "adj", total: 5, correct: 5),
            StudyReportExample(word: "prepare", meaning: "준비하다", topic: "life", part: "verb", total: 4, correct: 0),
            StudyReportExample(word: "moment", meaning: "순간", topic: "unknown", part: "noun", total: 3, correct: 2),
            StudyReportExample(word: "happily", meaning: "행복하게", topic: "unknown", part: "adv", total: 2, correct: 1)
        ]
        // 회차 차트용: journey 첫 풀이(정답)·prepare 마지막 풀이(오답)를 각각 1문제 회차로 묶음
        let sessions = [QuizSession(id: UUID(), startedAt: now, questionCount: 1),
                        QuizSession(id: UUID(), startedAt: now, questionCount: 1)]
        let sessionRows = ["journey": (index: 0, id: sessions[0].id), "prepare": (index: 3, id: sessions[1].id)]
        let histories = examples.flatMap { example in
            let wordID = UUID()
            return (0..<example.total).map { index in
                var history = LearningHistory(
                    id: UUID(), vocabId: wordID, isCorrect: index < example.correct,
                    createAt: now.addingTimeInterval(-Double(example.total - index)),
                    wordSnapshot: example.word, meaningSnapshot: example.meaning,
                    topicSnapshot: example.topic, partOfSpeechSnapshot: example.part
                )
                if let row = sessionRows[example.word], row.index == index {
                    history.sessionId = row.id
                    history.questionIndex = 0
                }
                return history
            }
        }
        let records = scenario == "empty"
            ? StudyReportRecords(histories: [], sessions: [])
            : StudyReportRecords(histories: histories, sessions: sessions)
        return StudyReportFeature(
            fetch: { period, now, calendar in
                if scenario == "error" { throw CocoaError(.fileReadUnknown) }
                return try DefaultFetchStudyReportUseCase.aggregate(records, period: period, now: now, calendar: calendar)
            },
            reportError: { _ in }, onClose: onClose, onNavigate: onNavigate,
            now: { now }, calendar: { fixedCalendar }
        )
    }
}
#endif
