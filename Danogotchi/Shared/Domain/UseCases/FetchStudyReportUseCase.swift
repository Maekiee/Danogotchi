import Foundation

protocol FetchStudyReportUseCase {
    func execute(period: StudyReportPeriod, now: Date, calendar: Calendar) async throws -> StudyReport
}

final class DefaultFetchStudyReportUseCase: FetchStudyReportUseCase {
    private let repository: LearningHistoryRepository

    init(repository: LearningHistoryRepository) {
        self.repository = repository
    }

    func execute(period: StudyReportPeriod, now: Date, calendar: Calendar) async throws -> StudyReport {
        let records = try await repository.fetchReportRecords()
        try Task.checkCancellation()
        return try Self.aggregate(records, period: period, now: now, calendar: calendar)
    }

    static func aggregate(_ records: StudyReportRecords, period: StudyReportPeriod,
                          now: Date, calendar: Calendar) throws -> StudyReport {
        let all = records.histories.filter { $0.createAt <= now }
        let start = period.start(now: now, calendar: calendar)
        let rows = all.filter { row in start.map { row.createAt >= $0 } ?? true }
        let allWords = words(from: all)
        let selectedWords = period == .all ? allWords : words(from: rows)
        let days = Set(all.map { calendar.startOfDay(for: $0.createAt) })
        let weekStart = StudyReportPeriod.week.start(now: now, calendar: calendar)!
        let monthStart = StudyReportPeriod.month.start(now: now, calendar: calendar)!
        let firstDate = all.map(\.createAt).min() ?? now
        let periodStart = start ?? calendar.startOfDay(for: firstDate)
        let activityUnit: Calendar.Component = period == .all ? .month : .day
        let activityStart = calendar.dateInterval(of: activityUnit, for: periodStart)!.start
        var bucketWords: [Date: Set<UUID>] = [:]
        for row in rows {
            let bucket = calendar.dateInterval(of: activityUnit, for: row.createAt)!.start
            bucketWords[bucket, default: []].insert(row.reportWordId)
        }
        let activity = dates(from: activityStart, through: now, unit: activityUnit, calendar: calendar)
            .map { StudyReport.Activity(date: $0, count: bucketWords[$0]?.count ?? 0) }
        let recentDays = dates(from: weekStart, through: now, unit: .day, calendar: calendar)
            .map { StudyReport.Activity(date: $0, count: days.contains($0) ? 1 : 0) }

        let partGroups = Dictionary(grouping: selectedWords) {
            StudyReportCategoryKind.partOfSpeech.identifier($0.snapshot.partOfSpeechSnapshot)
        }
        let parts = StudyReportCategoryKind.partOfSpeech.identifiers.map {
            StudyReport.Category(id: $0, total: partGroups[$0]?.count ?? 0)
        }
        return StudyReport(
            period: period, now: now, calendar: calendar, periodStart: periodStart,
            allStart: calendar.startOfDay(for: firstDate),
            totalAnswers: all.count, totalCorrect: all.filter(\.isCorrect).count,
            streak: streak(days: days, now: now, calendar: calendar),
            weekWordCount: Set(all.filter { $0.createAt >= weekStart }.map(\.reportWordId)).count,
            monthWordCount: Set(all.filter { $0.createAt >= monthStart }.map(\.reportWordId)).count,
            recentDays: recentDays, allWords: allWords, words: selectedWords,
            periodAnswerCount: rows.count, activity: activity,
            sessions: try completedSessions(records.sessions, histories: all, start: start),
            topics: categories(rows, kind: .topic), parts: parts,
            mistakesByPart: categories(rows, kind: .partOfSpeech)
        )
    }

    private static func words(from rows: [LearningHistory]) -> [StudyReport.Word] {
        let grouped = Dictionary(grouping: rows, by: \.reportWordId)
        let words = grouped.map { id, answers in
            let latest = answers.max {
                $0.createAt == $1.createAt ? $0.id.uuidString < $1.id.uuidString : $0.createAt < $1.createAt
            }!
            return StudyReport.Word(id: id, snapshot: latest, total: answers.count,
                                    correct: answers.filter(\.isCorrect).count)
        }
        return words.sorted {
            if $0.correct != $1.correct { return $0.correct > $1.correct }
            if $0.accuracy != $1.accuracy { return $0.accuracy > $1.accuracy }
            if $0.snapshot.createAt != $1.snapshot.createAt { return $0.snapshot.createAt > $1.snapshot.createAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private static func categories(_ rows: [LearningHistory], kind: StudyReportCategoryKind) -> [StudyReport.Category] {
        let grouped = Dictionary(grouping: rows) { row in
            kind.identifier(kind == .topic ? row.topicSnapshot : row.partOfSpeechSnapshot)
        }
        return kind.identifiers.map { id in
            let answers = grouped[id] ?? []
            return StudyReport.Category(id: id, total: answers.count,
                                        wrong: answers.filter { !$0.isCorrect }.count)
        }
    }

    private static func completedSessions(_ sessions: [QuizSession], histories: [LearningHistory],
                                          start: Date?) throws -> [StudyReport.Session] {
        let groups = histories.reduce(into: [UUID: [LearningHistory]]()) { result, row in
            if let id = row.sessionId { result[id, default: []].append(row) }
        }
        var results: [StudyReport.Session] = []
        var sessionIDs = Set<UUID>()
        for session in sessions {
            guard sessionIDs.insert(session.id).inserted else { throw StudyReportDataError.invalidIdentifiers }
            guard session.questionCount > 0, let answers = groups[session.id] else { continue }
            var questions: [Int: LearningHistory] = [:]
            var valid = true
            for answer in answers {
                guard let index = answer.questionIndex, (0..<session.questionCount).contains(index) else {
                    valid = false
                    continue
                }
                if let existing = questions[index], existing != answer {
                    throw StudyReportDataError.conflictingAnswer
                }
                questions[index] = answer
            }
            guard valid, questions.count == session.questionCount,
                  let completedAt = questions.values.map(\.createAt).max(),
                  start.map({ completedAt >= $0 }) ?? true else { continue }
            results.append(StudyReport.Session(
                id: session.id, completedAt: completedAt,
                correct: questions.values.filter(\.isCorrect).count, total: session.questionCount
            ))
        }
        return Array(results.sorted {
            $0.completedAt == $1.completedAt ? $0.id.uuidString < $1.id.uuidString : $0.completedAt < $1.completedAt
        }.suffix(10))
    }

    private static func streak(days: Set<Date>, now: Date, calendar: Calendar) -> Int {
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while days.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    private static func dates(from start: Date, through end: Date, unit: Calendar.Component,
                              calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var date = start
        while date <= end {
            result.append(date)
            guard let next = calendar.date(byAdding: unit, value: 1, to: date), next > date else { break }
            date = next
        }
        return result
    }
}
