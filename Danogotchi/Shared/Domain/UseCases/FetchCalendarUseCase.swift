import Foundation

protocol FetchCalendarUseCase {
    func execute(now: Date, calendar: Calendar) async throws -> StudyCalendar
}

final class DefaultFetchCalendarUseCase: FetchCalendarUseCase {
    private let repository: LearningHistoryRepository

    init(repository: LearningHistoryRepository) {
        self.repository = repository
    }

    func execute(now: Date, calendar: Calendar) async throws -> StudyCalendar {
        let records = try await repository.fetchStatsRecords()
        try Task.checkCancellation()
        return try Self.aggregate(records.histories, now: now, calendar: calendar)
    }

    static func aggregate(_ histories: [LearningHistory], now: Date, calendar: Calendar) throws -> StudyCalendar {
        let rows = histories.filter { $0.createAt <= now }
        let grouped = Dictionary(grouping: rows) { calendar.startOfDay(for: $0.createAt) }
        let days = Dictionary(uniqueKeysWithValues: grouped.map { date, answers in
            (date, StudyCalendar.Day(
                date: date, words: answers.vocabStats(), answerCount: answers.count,
                correctCount: answers.filter(\.isCorrect).count,
                quizCount: Set(answers.compactMap(\.sessionId)).count
            ))
        })
        return StudyCalendar(now: now, calendar: calendar, days: days,
                             streak: streak(days: Set(days.keys), now: now, calendar: calendar))
    }

    // 오늘 기록이 없으면 어제부터 센다
    private static func streak(days: Set<Date>, now: Date, calendar: Calendar) -> Int {
        var day = calendar.startOfDay(for: now)
        if !days.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) { day = yesterday }
        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
