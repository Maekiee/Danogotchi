import Foundation

protocol FetchStudyStatsUseCase {
    func execute(now: Date, calendar: Calendar) async throws -> StudyStats
}

final class DefaultFetchStudyStatsUseCase: FetchStudyStatsUseCase {
    private let repository: LearningHistoryRepository

    init(repository: LearningHistoryRepository) {
        self.repository = repository
    }

    func execute(now: Date, calendar: Calendar) async throws -> StudyStats {
        let records = try await repository.fetchStatsRecords()
        try Task.checkCancellation()
        return Self.aggregate(records, now: now, calendar: calendar)
    }

    static func aggregate(_ records: StudyStatsRecords, now: Date, calendar: Calendar) -> StudyStats {
        let rows = records.histories.filter { $0.createAt <= now }
        let words = rows.vocabStats()
        let firstDate = rows.map(\.createAt).min() ?? now
        let partGroups = Dictionary(grouping: words) {
            StudyStatsCategoryKind.partOfSpeech.identifier($0.snapshot.partOfSpeechSnapshot)
        }
        let topicGroups = Dictionary(grouping: rows) { StudyStatsCategoryKind.topic.identifier($0.topicSnapshot) }
        // 정답 횟수순 정렬의 반대: 오답 횟수 → 낮은 정답률 → 최근 풀이 → id
        let mistakeWords = words.filter(StudyStatsMistakeThreshold.seventy.contains).sorted {
            let left = $0.total - $0.correct, right = $1.total - $1.correct
            if left != right { return left > right }
            if $0.accuracy != $1.accuracy { return $0.accuracy < $1.accuracy }
            if $0.snapshot.createAt != $1.snapshot.createAt { return $0.snapshot.createAt > $1.snapshot.createAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        return StudyStats(
            now: now, calendar: calendar, start: calendar.startOfDay(for: firstDate),
            totalAnswers: rows.count, totalCorrect: rows.filter(\.isCorrect).count,
            words: words, mistakeWords: mistakeWords,
            topics: StudyStatsCategoryKind.topic.identifiers.map {
                StudyStats.Category(id: $0, total: topicGroups[$0]?.count ?? 0)
            },
            parts: StudyStatsCategoryKind.partOfSpeech.identifiers.map {
                StudyStats.Category(id: $0, total: partGroups[$0]?.count ?? 0)
            }
        )
    }
}
