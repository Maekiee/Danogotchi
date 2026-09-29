#if DEBUG
import ComposableArchitecture
import SwiftUI

private struct StudyReportPreview: View {
    enum Scenario: String, CaseIterable {
        case normal = "학습 기록 있음"
        case empty = "학습 기록 없음"
        case loading = "불러오는 중"
        case error = "불러오기 실패"
        case legacy = "이전 기록만 있음"
        case single = "완료 회차 1개"
    }

    let scenario: Scenario

    var body: some View {
        let records = records
        NavigationStack {
            StudyReportView(store: Store(initialState: state) {
                StudyReportFeature(
                    fetch: { period, now, calendar in
                        try DefaultFetchStudyReportUseCase.aggregate(records, period: period, now: now, calendar: calendar)
                    }, reportError: { _ in }, onClose: {}
                )
            })
        }
    }

    private var state: StudyReportFeature.State {
        var state = StudyReportFeature.State()
        state.report = try? DefaultFetchStudyReportUseCase.aggregate(records, period: .week, now: Date(), calendar: .current)
        state.selectedActivity = state.report?.activity.last?.date
        state.selectedSession = state.report?.sessions.indices.last
        if scenario == .loading { state.requestID = UUID() }
        if scenario == .error { state.hasError = true }
        return state
    }

    private var records: StudyReportRecords {
        guard scenario != .empty else { return StudyReportRecords(histories: [], sessions: []) }
        let examples: [(String, String, BookTopic, PartOfSpeech)] = [
            ("journey", "여행", .travel, .noun), ("prepare", "준비하다", .life, .verb),
            ("efficient", "효율적인", .business, .adj), ("happily", "행복하게", .emotion, .adv),
            ("moment", "순간", .myBook, .noun)
        ]
        let now = Date()
        let words = examples.map {
            Vocab(id: UUID(), word: $0.0, meaning: $0.1, bookType: $0.2,
                  level: nil, partOfSpeech: $0.3, sourceWordId: nil, createAt: now)
        }
        var histories: [LearningHistory] = []
        var sessions: [QuizSession] = []
        for offset in (scenario == .single ? [0] : [20, 8, 5, 4, 3, 2, 1, 0]) {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: now)!.addingTimeInterval(-600)
            let session = QuizSession(id: UUID(), startedAt: date, questionCount: words.count)
            sessions.append(session)
            for (index, word) in words.enumerated() {
                var history = QuizAnswer(
                    word: word, isCorrect: (index + offset) % 3 != 0,
                    createAt: date.addingTimeInterval(Double(index * 10)), session: session, questionIndex: index
                ).history
                if scenario == .legacy { history.sessionId = nil; history.questionIndex = nil }
                histories.append(history)
            }
        }
        return StudyReportRecords(histories: histories, sessions: scenario == .legacy ? [] : sessions)
    }
}

#Preview("학습 리포트") { StudyReportPreview(scenario: .normal) }
#Preview("학습 기록 없음") { StudyReportPreview(scenario: .empty) }
#Preview("불러오는 중") { StudyReportPreview(scenario: .loading) }
#Preview("불러오기 실패") { StudyReportPreview(scenario: .error) }
#Preview("이전 기록만 있음") { StudyReportPreview(scenario: .legacy) }
#Preview("완료 회차 1개") { StudyReportPreview(scenario: .single) }
#Preview("정답·오답 막대") {
    StudyReportCategoryBars(
        categories: [.init(id: "travel", total: 342, wrong: 75), .init(id: "business")],
        kind: .topic, showsMistakes: true, selected: nil
    ) { _ in }
    .padding()
}
#Preview("단어 상세 카드") {
    let date = Date()
    let snapshot = LearningHistory(
        id: UUID(), vocabId: UUID(), isCorrect: true, createAt: date,
        wordSnapshot: "journey", meaningSnapshot: "여행", topicSnapshot: "travel", partOfSpeechSnapshot: "noun"
    )
    let word = StudyReport.Word(id: snapshot.vocabId, snapshot: snapshot, total: 342, correct: 267)
    StudyReportWordDetailView(word: word)
}
#endif
