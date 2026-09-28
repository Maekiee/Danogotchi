import XCTest
@testable import Danogotchi

final class StudyReportAggregationTests: XCTestCase {
    private let calendar = reportCalendar()
    private let now = reportDate()

    func test_largeSyntheticHistoryAggregationPerformance() {
        let words = makeQuizWords(500)
        let rows = (0..<30_000).map { index in
            LearningHistory(id: UUID(), vocabId: words[index % words.count].id,
                            isCorrect: index % 3 != 0, createAt: now.addingTimeInterval(-Double(index)))
        }
        measure {
            do {
                let report = try aggregate(rows)
                XCTAssertEqual(report.totalAnswers, 30_000)
                XCTAssertEqual(report.allWords.count, 500)
            } catch { XCTFail("\(error)") }
        }
    }

    func test_uniqueWordsWeightedAccuracyAndPartDistribution() throws {
        let words = makeQuizWords(3)
        var rows = [
            makeQuizAnswer(words[0], createAt: now).history,
            makeQuizAnswer(words[0], createAt: now).history,
            makeQuizAnswer(words[0], isCorrect: false, createAt: now).history,
            makeQuizAnswer(words[1], createAt: now).history,
            makeQuizAnswer(words[2], isCorrect: false, createAt: now).history
        ]
        rows[4].partOfSpeechSnapshot = "verb"
        let report = try aggregate(rows)
        XCTAssertEqual(report.words.count, 3)
        XCTAssertEqual(report.totalAnswers, 5)
        XCTAssertEqual(report.accuracy, 0.6)
        XCTAssertEqual(report.parts.first { $0.id == "noun" }?.total, 2)
        XCTAssertEqual(report.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(report.parts.reduce(0) { $0 + $1.total }, report.words.count)
    }

    func test_originalAndCopyShareIdentityButLatestSnapshotRepresentsWord() throws {
        let word = makeQuizWords(1)[0]
        let original = makeQuizAnswer(word, createAt: reportDate(2026, 9, 25)).history
        var copy = LearningHistory(id: UUID(), vocabId: UUID(), isCorrect: false, createAt: now)
        copy.sourceWordIdSnapshot = word.id
        copy.wordSnapshot = "changed"
        copy.meaningSnapshot = "수정한 뜻"
        copy.partOfSpeechSnapshot = "verb"
        let report = try aggregate([copy, original])
        XCTAssertEqual(report.words.count, 1)
        XCTAssertEqual(report.words.first?.snapshot.meaningSnapshot, "수정한 뜻")
        XCTAssertEqual(report.words.first?.total, 2)
        XCTAssertEqual(report.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(report.activity.reduce(0) { $0 + $1.count }, 2)
        XCTAssertEqual(report.weekWordCount, 1)
        XCTAssertEqual(report.allStart, calendar.startOfDay(for: original.createAt))
        XCTAssertEqual([copy, original].statsByVocab().count, 2)
    }

    func test_lastSnapshotIsChosenWithinSelectedPeriodAndUnknownsRemainIncluded() throws {
        let word = makeQuizWords(1)[0]
        var old = makeQuizAnswer(word, createAt: reportDate(2026, 8, 20)).history
        old.partOfSpeechSnapshot = "noun"
        var latest = makeQuizAnswer(word, createAt: now).history
        latest.partOfSpeechSnapshot = "new-part"
        latest.topicSnapshot = "myBook"
        let report = try aggregate([latest, old])
        XCTAssertEqual(report.words.count, 1)
        XCTAssertEqual(report.words.first?.total, 1)
        XCTAssertEqual(report.totalAnswers, 2)
        XCTAssertEqual(report.parts.first { $0.id == "unknown" }?.total, 1)
        XCTAssertEqual(report.topics.first { $0.id == "unknown" }?.total, 1)
    }

    func test_completedSessionUsesAllAnswersBeforeFilteringByCompletionDate() throws {
        let word = makeQuizWords(1)[0]
        let started = reportDate(2026, 9, 19, 23)
        let session = QuizSession(id: UUID(), startedAt: started, questionCount: 2)
        let rows = [
            makeQuizAnswer(word, createAt: started, session: session, questionIndex: 0).history,
            makeQuizAnswer(word, isCorrect: false, createAt: reportDate(2026, 9, 20, 1), session: session, questionIndex: 1).history
        ]
        let report = try aggregate(rows, sessions: [session])
        XCTAssertEqual(report.sessions.count, 1)
        XCTAssertEqual(report.sessions.first?.total, 2)
        XCTAssertEqual(report.sessions.first?.accuracy, 0.5)
        XCTAssertEqual(report.periodAnswerCount, 1)
        XCTAssertEqual(report.totalAnswers, 2)
    }

    func test_sessionRequiresEveryValidIndexAndRejectsConflictingAnswers() throws {
        let word = makeQuizWords(1)[0]
        let session = QuizSession(id: UUID(), startedAt: now, questionCount: 2)
        let first = makeQuizAnswer(word, createAt: now, session: session, questionIndex: 0).history
        var second = makeQuizAnswer(word, createAt: now, session: session, questionIndex: 1).history
        XCTAssertTrue(try aggregate([first, first], sessions: [session]).sessions.isEmpty)
        for index in [nil, -1, 2] as [Int?] {
            second.questionIndex = index
            XCTAssertTrue(try aggregate([first, second], sessions: [session]).sessions.isEmpty)
        }
        second.questionIndex = 0
        XCTAssertThrowsError(try aggregate([first, second], sessions: [session])) {
            XCTAssertEqual($0 as? StudyReportDataError, .conflictingAnswer)
        }
        let empty = QuizSession(id: UUID(), startedAt: now, questionCount: 0)
        XCTAssertTrue(try aggregate([], sessions: [empty]).sessions.isEmpty)
    }

    func test_onlyTenRecentCompletedSessionsAndWeightedTotalAccuracy() throws {
        let word = makeQuizWords(1)[0]
        var sessions: [QuizSession] = []
        var rows: [LearningHistory] = []
        for index in 0..<12 {
            let date = now.addingTimeInterval(Double(index - 12))
            let session = QuizSession(id: UUID(), startedAt: date, questionCount: index == 0 ? 3 : 1)
            sessions.append(session)
            for question in 0..<session.questionCount {
                rows.append(makeQuizAnswer(word, isCorrect: question == 0, createAt: date,
                                           session: session, questionIndex: question).history)
            }
        }
        let report = try aggregate(rows, sessions: sessions)
        XCTAssertEqual(report.sessions.count, 10)
        XCTAssertEqual(report.sessions.first?.id, sessions[2].id)
        XCTAssertEqual(report.totalAnswers, 14)
        XCTAssertEqual(report.totalCorrect, 12)
        XCTAssertEqual(report.accuracy, 12.0 / 14.0)
    }

    func test_streakAllowsUnstudiedTodayAndResetsAfterMissingYesterday() throws {
        let word = makeQuizWords(1)[0]
        var rows = [24, 25].map { makeQuizAnswer(word, createAt: reportDate(2026, 9, $0)).history }
        XCTAssertEqual(try aggregate(rows).streak, 2)
        rows.removeLast()
        XCTAssertEqual(try aggregate(rows).streak, 0)
        rows.append(makeQuizAnswer(word, createAt: now).history)
        XCTAssertEqual(try aggregate(rows).streak, 1)
    }

    func test_calendarBoundariesLeapDayAndDSTHaveSevenBuckets() throws {
        let word = makeQuizWords(1)[0]
        for zone in ["Asia/Seoul", "America/Los_Angeles"] {
            let calendar = reportCalendar(zone)
            for date in [reportDate(2024, 3, 1, calendar: calendar), reportDate(2026, 3, 9, calendar: calendar),
                         reportDate(2027, 1, 1, calendar: calendar)] {
                let start = StudyReportPeriod.week.start(now: date, calendar: calendar)!
                let rows = [makeQuizAnswer(word, createAt: start).history,
                            makeQuizAnswer(word, createAt: start.addingTimeInterval(-1)).history,
                            makeQuizAnswer(word, createAt: date.addingTimeInterval(1)).history]
                let report = try DefaultFetchStudyReportUseCase.aggregate(.init(histories: rows, sessions: []), period: .week, now: date, calendar: calendar)
                XCTAssertEqual(report.activity.count, 7)
                XCTAssertEqual(report.periodAnswerCount, 1)
                XCTAssertEqual(report.totalAnswers, 2)
            }
        }
    }

    func test_timezoneAndMonthSelectionUseQueryCalendar() throws {
        let word = makeQuizWords(1)[0]
        let boundary = reportDate(2026, 10, 1, 0)
        let rows = [makeQuizAnswer(word, createAt: boundary.addingTimeInterval(-1)).history]
        let seoul = try DefaultFetchStudyReportUseCase.aggregate(.init(histories: rows, sessions: []), period: .month,
                                                         now: boundary, calendar: reportCalendar())
        let la = try DefaultFetchStudyReportUseCase.aggregate(.init(histories: rows, sessions: []), period: .month,
                                                      now: boundary, calendar: reportCalendar("America/Los_Angeles"))
        XCTAssertEqual(seoul.monthWordCount, 0)
        XCTAssertEqual(la.monthWordCount, 1)
        let all = try aggregate(rows, period: .all)
        XCTAssertTrue(all.words.isEmpty)
    }

    func test_emptyLegacyMonthlyBucketsAndStableRanking() throws {
        let empty = try aggregate([])
        XCTAssertNil(empty.accuracy)
        XCTAssertEqual(empty.streak, 0)
        XCTAssertEqual(empty.activity.map(\.count), Array(repeating: 0, count: 7))
        let ids = [UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, UUID(uuidString: "00000000-0000-0000-0000-000000000002")!]
        let rows = ids.reversed().map { LearningHistory(id: UUID(), vocabId: $0, isCorrect: true, createAt: now) }
        let legacy = try aggregate(rows)
        XCTAssertEqual(legacy.words.map(\.id), ids)
        XCTAssertTrue(legacy.sessions.isEmpty)
        var old = rows[0]
        old = LearningHistory(id: old.id, vocabId: old.vocabId, isCorrect: true, createAt: reportDate(2026, 7, 31))
        let monthly = try aggregate([old, rows[1]], period: .all)
        XCTAssertEqual(monthly.activity.map(\.count), [1, 0, 1])
    }

    private func aggregate(_ rows: [LearningHistory], sessions: [QuizSession] = [],
                           period: StudyReportPeriod = .week) throws -> StudyReport {
        try DefaultFetchStudyReportUseCase.aggregate(.init(histories: rows, sessions: sessions), period: period, now: now, calendar: calendar)
    }
}
