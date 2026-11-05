import XCTest
@testable import Danogotchi

final class StudyStatsAggregationTests: XCTestCase {
    private let calendar = statsCalendar()
    private let now = statsDate()

    func test_largeSyntheticHistoryAggregationPerformance() {
        let words = makeQuizWords(500)
        let rows = (0..<30_000).map { index in
            LearningHistory(id: UUID(), vocabId: words[index % words.count].id,
                            isCorrect: index % 3 != 0, createAt: now.addingTimeInterval(-Double(index)))
        }
        measure {
            do {
                let stats = try aggregate(rows)
                XCTAssertEqual(stats.totalAnswers, 30_000)
                XCTAssertEqual(stats.allWords.count, 500)
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
        let stats = try aggregate(rows)
        XCTAssertEqual(stats.words.count, 3)
        XCTAssertEqual(stats.totalAnswers, 5)
        XCTAssertEqual(stats.accuracy, 0.6)
        XCTAssertEqual(stats.parts.first { $0.id == "noun" }?.total, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(stats.parts.reduce(0) { $0 + $1.total }, stats.words.count)
    }

    func test_originalAndCopyShareIdentityButLatestSnapshotRepresentsWord() throws {
        let word = makeQuizWords(1)[0]
        let original = makeQuizAnswer(word, createAt: statsDate(2026, 9, 25)).history
        var copy = LearningHistory(id: UUID(), vocabId: UUID(), isCorrect: false, createAt: now)
        copy.sourceWordIdSnapshot = word.id
        copy.wordSnapshot = "changed"
        copy.meaningSnapshot = "수정한 뜻"
        copy.partOfSpeechSnapshot = "verb"
        let stats = try aggregate([copy, original])
        XCTAssertEqual(stats.words.count, 1)
        XCTAssertEqual(stats.words.first?.snapshot.meaningSnapshot, "수정한 뜻")
        XCTAssertEqual(stats.words.first?.total, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(stats.activity.reduce(0) { $0 + $1.count }, 2)
        XCTAssertEqual(stats.weekWordCount, 1)
        XCTAssertEqual(stats.allStart, calendar.startOfDay(for: original.createAt))
        XCTAssertEqual([copy, original].statsByVocab().count, 2)
    }

    func test_lastSnapshotIsChosenWithinSelectedPeriodAndUnknownsRemainIncluded() throws {
        let word = makeQuizWords(1)[0]
        var old = makeQuizAnswer(word, createAt: statsDate(2026, 8, 20)).history
        old.partOfSpeechSnapshot = "noun"
        var latest = makeQuizAnswer(word, createAt: now).history
        latest.partOfSpeechSnapshot = "new-part"
        latest.topicSnapshot = "myBook"
        let stats = try aggregate([latest, old])
        XCTAssertEqual(stats.words.count, 1)
        XCTAssertEqual(stats.words.first?.total, 1)
        XCTAssertEqual(stats.totalAnswers, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "unknown" }?.total, 1)
        XCTAssertEqual(stats.topics.first { $0.id == "unknown" }?.total, 1)
    }

    func test_completedSessionUsesAllAnswersBeforeFilteringByCompletionDate() throws {
        let word = makeQuizWords(1)[0]
        let started = statsDate(2026, 9, 19, 23)
        let session = QuizSession(id: UUID(), startedAt: started, questionCount: 2)
        let rows = [
            makeQuizAnswer(word, createAt: started, session: session, questionIndex: 0).history,
            makeQuizAnswer(word, isCorrect: false, createAt: statsDate(2026, 9, 20, 1), session: session, questionIndex: 1).history
        ]
        let stats = try aggregate(rows, sessions: [session])
        XCTAssertEqual(stats.sessions.count, 1)
        XCTAssertEqual(stats.sessions.first?.total, 2)
        XCTAssertEqual(stats.sessions.first?.accuracy, 0.5)
        XCTAssertEqual(stats.periodAnswerCount, 1)
        XCTAssertEqual(stats.totalAnswers, 2)
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
            XCTAssertEqual($0 as? StudyStatsDataError, .conflictingAnswer)
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
        let stats = try aggregate(rows, sessions: sessions)
        XCTAssertEqual(stats.sessions.count, 10)
        XCTAssertEqual(stats.sessions.first?.id, sessions[2].id)
        XCTAssertEqual(stats.totalAnswers, 14)
        XCTAssertEqual(stats.totalCorrect, 12)
        XCTAssertEqual(stats.accuracy, 12.0 / 14.0)
    }

    func test_streakAllowsUnstudiedTodayAndResetsAfterMissingYesterday() throws {
        let word = makeQuizWords(1)[0]
        var rows = [24, 25].map { makeQuizAnswer(word, createAt: statsDate(2026, 9, $0)).history }
        XCTAssertEqual(try aggregate(rows).streak, 2)
        rows.removeLast()
        XCTAssertEqual(try aggregate(rows).streak, 0)
        rows.append(makeQuizAnswer(word, createAt: now).history)
        XCTAssertEqual(try aggregate(rows).streak, 1)
    }

    func test_calendarBoundariesLeapDayAndDSTHaveSevenBuckets() throws {
        let word = makeQuizWords(1)[0]
        for zone in ["Asia/Seoul", "America/Los_Angeles"] {
            let calendar = statsCalendar(zone)
            for date in [statsDate(2024, 3, 1, calendar: calendar), statsDate(2026, 3, 9, calendar: calendar),
                         statsDate(2027, 1, 1, calendar: calendar)] {
                let start = try XCTUnwrap(StudyStatsPeriod.week.start(now: date, calendar: calendar))
                let rows = [makeQuizAnswer(word, createAt: start).history,
                            makeQuizAnswer(word, createAt: start.addingTimeInterval(-1)).history,
                            makeQuizAnswer(word, createAt: date.addingTimeInterval(1)).history]
                let stats = try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []), period: .week, now: date, calendar: calendar)
                XCTAssertEqual(stats.activity.count, 7)
                XCTAssertEqual(stats.periodAnswerCount, 1)
                XCTAssertEqual(stats.totalAnswers, 2)
            }
        }
    }

    func test_timezoneAndMonthSelectionUseQueryCalendar() throws {
        let word = makeQuizWords(1)[0]
        let boundary = statsDate(2026, 10, 1, 0)
        let rows = [makeQuizAnswer(word, createAt: boundary.addingTimeInterval(-1)).history]
        let seoul = try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []), period: .month,
                                                         now: boundary, calendar: statsCalendar())
        let la = try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []), period: .month,
                                                      now: boundary, calendar: statsCalendar("America/Los_Angeles"))
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
        let ids = try [XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
                       XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))]
        let rows = ids.reversed().map { LearningHistory(id: UUID(), vocabId: $0, isCorrect: true, createAt: now) }
        let legacy = try aggregate(rows)
        XCTAssertEqual(legacy.words.map(\.id), ids)
        XCTAssertTrue(legacy.sessions.isEmpty)
        var old = rows[0]
        old = LearningHistory(id: old.id, vocabId: old.vocabId, isCorrect: true, createAt: statsDate(2026, 7, 31))
        let monthly = try aggregate([old, rows[1]], period: .all)
        XCTAssertEqual(monthly.activity.map(\.count), [1, 0, 1])
    }

    private func aggregate(_ rows: [LearningHistory], sessions: [QuizSession] = [],
                           period: StudyStatsPeriod = .week) throws -> StudyStats {
        try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: sessions), period: period, now: now, calendar: calendar)
    }
}
