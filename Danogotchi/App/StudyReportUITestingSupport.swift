#if DEBUG
import UIKit

extension UITestingSupport {
    private static var studyReportScenario: String? {
        ProcessInfo.processInfo.environment["STUDY_REPORT_UI_TEST"]
    }

    // 저장소 변경 없이 실제 리포트 Coordinator로 진입
    @MainActor
    static func startStudyReportIfRequested(window: UIWindow, container: AppDIContainer) -> MainCoordinator? {
        guard studyReportScenario != nil else { return nil }
        let navigation = UINavigationController(rootViewController: UIViewController())
        let coordinator = MainCoordinator(container: container, navigationController: navigation)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        DispatchQueue.main.async { coordinator.exploreVocabDidTapStudyReport() }
        return coordinator
    }

    static func makeStudyReportFeatureIfRequested(
        onClose: @escaping @MainActor @Sendable () -> Void,
        onNavigate: @escaping @MainActor @Sendable (StudyReportDestination) -> Void
    ) -> StudyReportFeature? {
        guard let scenario = studyReportScenario else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let fixedCalendar = calendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 12))!
        let examples: [(String, String, String, String, Int, Int)] = [
            ("journey", "여행", "travel", "noun", 342, 267),
            ("efficient", "효율적인", "business", "adj", 5, 5),
            ("prepare", "준비하다", "life", "verb", 4, 0),
            ("moment", "순간", "unknown", "noun", 3, 2),
            ("happily", "행복하게", "unknown", "adv", 2, 1)
        ]
        let histories = examples.flatMap { word, meaning, topic, part, total, correct in
            let wordID = UUID()
            return (0..<total).map { index in
                LearningHistory(
                    id: UUID(), vocabId: wordID, isCorrect: index < correct,
                    createAt: now.addingTimeInterval(-Double(total - index)),
                    wordSnapshot: word, meaningSnapshot: meaning,
                    topicSnapshot: topic, partOfSpeechSnapshot: part
                )
            }
        }
        let records = StudyReportRecords(histories: scenario == "empty" ? [] : histories, sessions: [])
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
