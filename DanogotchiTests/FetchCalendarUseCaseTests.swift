import XCTest
@testable import Danogotchi

final class FetchCalendarUseCaseTests: XCTestCase {
    private let calendar = statsCalendar()
    private let now = statsDate()

    func test_levelBoundariesUseUniqueWordCount() throws {
        let word = try XCTUnwrap([makeQuizAnswer(makeQuizWords(1)[0], createAt: now).history].vocabStats().first)
        let levels = [0, 1, 4, 5, 14, 15].map { count in
            StudyCalendar.Day(date: now, words: Array(repeating: word, count: count),
                              answerCount: count, correctCount: count, quizCount: 1).level
        }
        XCTAssertEqual(levels, [0, 1, 1, 2, 2, 3])
    }

    func test_sameWordOnSameDayCountsOnceAndSumsAnswers() throws {
        let words = makeQuizWords(2)
        let first = QuizSession(id: UUID(), startedAt: now, questionCount: 3)
        let second = QuizSession(id: UUID(), startedAt: now, questionCount: 1)
        var rows = [
            makeQuizAnswer(words[0], createAt: now, session: first).history,
            makeQuizAnswer(words[0], createAt: now, session: first).history,
            makeQuizAnswer(words[0], isCorrect: false, createAt: now, session: first).history,
            makeQuizAnswer(words[1], createAt: now, session: second).history
        ]
        rows.append(LearningHistory(id: UUID(), vocabId: words[1].id, isCorrect: false, createAt: now))
        let day = try XCTUnwrap(aggregate(rows).days[calendar.startOfDay(for: now)])
        XCTAssertEqual(day.words.count, 2)
        XCTAssertEqual(day.answerCount, 5)
        XCTAssertEqual(day.correctCount, 3)
        XCTAssertEqual(day.quizCount, 2)
        XCTAssertEqual(day.words.first?.id, words[0].id)
        XCTAssertEqual(day.words.first?.total, 3)
        XCTAssertEqual(day.level, 1)
    }

    func test_midnightSplitsDaysInCalendarTimeZone() throws {
        let word = makeQuizWords(1)[0]
        let beforeMidnight = statsDate(2026, 9, 25, 23).addingTimeInterval(3599)
        let afterMidnight = statsDate(2026, 9, 26, 0)
        let rows = [beforeMidnight, afterMidnight].map { makeQuizAnswer(word, createAt: $0).history }
        let seoul = try aggregate(rows)
        XCTAssertEqual(Set(seoul.days.keys), [statsDate(2026, 9, 25, 0), statsDate(2026, 9, 26, 0)])
        // 서울 자정 전후가 UTC로는 같은 날
        let utc = try DefaultFetchCalendarUseCase.aggregate(rows, now: now, calendar: statsCalendar("UTC"))
        XCTAssertEqual(utc.days.count, 1)
        XCTAssertEqual(utc.days.values.first?.answerCount, 2)
    }

    // 기록 유무와 상관없이 현재 연도 포함 최근 5개 연도의 1월
    func test_oldestMonthIsJanuaryOfFourYearsBack() throws {
        let word = makeQuizWords(1)[0]
        let stats = try aggregate([makeQuizAnswer(word, createAt: statsDate(2026, 5, 11)).history])
        XCTAssertEqual(stats.oldestMonth, statsDate(2022, 1, 1, 0))
        XCTAssertEqual(stats.currentMonth, statsDate(2026, 9, 1, 0))

        let empty = try aggregate([])
        XCTAssertEqual(empty.oldestMonth, statsDate(2022, 1, 1, 0))
        XCTAssertTrue(empty.days.isEmpty)
        XCTAssertEqual(empty.streak, 0)
        XCTAssertEqual(empty.studiedDayCount, 0)
    }

    func test_futureRecordsAreExcluded() throws {
        let word = makeQuizWords(1)[0]
        let stats = try aggregate([makeQuizAnswer(word, createAt: now).history,
                                   makeQuizAnswer(word, createAt: now.addingTimeInterval(1)).history,
                                   makeQuizAnswer(word, createAt: statsDate(2026, 10, 1)).history])
        XCTAssertEqual(stats.studiedDayCount, 1)
        XCTAssertEqual(stats.days[calendar.startOfDay(for: now)]?.answerCount, 1)
    }

    // FetchStudyStatsUseCase 연속일 테스트를 옮겨 옴
    func test_streakAllowsUnstudiedTodayAndResetsAfterMissingYesterday() throws {
        let word = makeQuizWords(1)[0]
        var rows = [24, 25].map { makeQuizAnswer(word, createAt: statsDate(2026, 9, $0)).history }
        XCTAssertEqual(try aggregate(rows).streak, 2)
        rows.removeLast()
        XCTAssertEqual(try aggregate(rows).streak, 0)
        rows.append(makeQuizAnswer(word, createAt: now).history)
        XCTAssertEqual(try aggregate(rows).streak, 1)
    }

    private func aggregate(_ rows: [LearningHistory]) throws -> StudyCalendar {
        try DefaultFetchCalendarUseCase.aggregate(rows, now: now, calendar: calendar)
    }
}
