#if DEBUG
import ComposableArchitecture
import SwiftUI

private struct StudyStatsPreview: View {
    enum Scenario: String, CaseIterable {
        case normal = "학습 기록 있음"
        case empty = "학습 기록 없음"
        case loading = "불러오는 중"
        case error = "불러오기 실패"
    }

    let scenario: Scenario

    var body: some View {
        let records = records
        NavigationStack {
            StudyStatsView(store: Store(initialState: state) {
                StudyStatsFeature(
                    fetch: { now, calendar in
                        DefaultFetchStudyStatsUseCase.aggregate(records, now: now, calendar: calendar)
                    }, reportError: { _ in }, onClose: {}
                )
            })
        }
    }

    private var state: StudyStatsFeature.State {
        var state = StudyStatsFeature.State()
        state.stats = DefaultFetchStudyStatsUseCase.aggregate(records, now: Date(), calendar: .current)
        if scenario == .loading { state.stats = nil; state.loadStatus = .loading(UUID()) }
        if scenario == .error { state.loadStatus = .failed }
        return state
    }

    private var records: StudyStatsRecords {
        guard scenario != .empty else { return StudyStatsRecords(histories: [], sessions: []) }
        let now = Date()
        func vocab(_ word: String, _ meaning: String, _ topic: BookTopic, _ part: PartOfSpeech) -> Vocab {
            Vocab(id: UUID(), word: word, meaning: meaning, bookType: topic,
                  level: nil, partOfSpeech: part, sourceWordId: nil, createAt: now)
        }
        let words = [
            vocab("journey", "여행", .travel, .noun), vocab("prepare", "준비하다", .life, .verb),
            vocab("efficient", "효율적인", .business, .adj), vocab("happily", "행복하게", .emotion, .adv),
            vocab("moment", "순간", .myBook, .noun)
        ]
        var histories: [LearningHistory] = []
        for offset in [20, 8, 5, 4, 3, 2, 1, 0] {
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: now) else { continue }
            let date = day.addingTimeInterval(-600)
            let session = QuizSession(id: UUID(), startedAt: date, questionCount: words.count)
            for (index, word) in words.enumerated() {
                histories.append(QuizAnswer(
                    word: word, isCorrect: (index + offset) % 3 != 0,
                    createAt: date.addingTimeInterval(Double(index * 10)), session: session, questionIndex: index
                ).history)
            }
        }
        return StudyStatsRecords(histories: histories, sessions: [])
    }
}

#Preview("학습 통계") { StudyStatsPreview(scenario: .normal) }
#Preview("학습 기록 없음") { StudyStatsPreview(scenario: .empty) }
#Preview("불러오는 중") { StudyStatsPreview(scenario: .loading) }
#Preview("불러오기 실패") { StudyStatsPreview(scenario: .error) }
#Preview("단어 상세 카드") {
    let date = Date()
    let snapshot = LearningHistory(
        id: UUID(), vocabId: UUID(), isCorrect: true, createAt: date,
        wordSnapshot: "journey", meaningSnapshot: "여행", topicSnapshot: "travel", partOfSpeechSnapshot: "noun"
    )
    let word = VocabStats(id: snapshot.vocabId, snapshot: snapshot, total: 342, correct: 267)
    StudyStatsWordDetailView(word: word)
}
#endif
