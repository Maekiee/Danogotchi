import XCTest
@testable import Danogotchi

final class StudyStatsAggregationTests: XCTestCase {
    private let calendar = statsCalendar()
    private let now = statsDate()

    // 기준값 없는 measure는 느려져도 실패하지 않아 한 번만 집계
    func test_largeSyntheticHistoryAggregatesEveryAnswerAndWord() {
        let words = makeQuizWords(500)
        let rows = (0..<30_000).map { index in
            LearningHistory(id: UUID(), vocabId: words[index % words.count].id,
                            isCorrect: index % 3 != 0, createAt: now.addingTimeInterval(-Double(index)))
        }
        let stats = aggregate(rows)
        XCTAssertEqual(stats.totalAnswers, 30_000)
        XCTAssertEqual(stats.words.count, 500)
    }

    func test_uniqueWordsWeightedAccuracyAndPartDistribution() {
        let words = makeQuizWords(3)
        var rows = [
            makeQuizAnswer(words[0], createAt: now).history,
            makeQuizAnswer(words[0], createAt: now).history,
            makeQuizAnswer(words[0], isCorrect: false, createAt: now).history,
            makeQuizAnswer(words[1], createAt: now).history,
            makeQuizAnswer(words[2], isCorrect: false, createAt: now).history
        ]
        rows[4].partOfSpeechSnapshot = "verb"
        let stats = aggregate(rows)
        XCTAssertEqual(stats.words.count, 3)
        XCTAssertEqual(stats.totalAnswers, 5)
        XCTAssertEqual(stats.accuracy, 0.6)
        XCTAssertEqual(stats.parts.first { $0.id == "noun" }?.total, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(stats.parts.reduce(0) { $0 + $1.total }, stats.words.count)
    }

    func test_originalAndCopyShareIdentityButLatestSnapshotRepresentsWord() {
        let word = makeQuizWords(1)[0]
        let original = makeQuizAnswer(word, createAt: statsDate(2026, 9, 25)).history
        var copy = LearningHistory(id: UUID(), vocabId: UUID(), isCorrect: false, createAt: now)
        copy.sourceWordIdSnapshot = word.id
        copy.wordSnapshot = "changed"
        copy.meaningSnapshot = "수정한 뜻"
        copy.partOfSpeechSnapshot = "verb"
        let stats = aggregate([copy, original])
        XCTAssertEqual(stats.words.count, 1)
        XCTAssertEqual(stats.words.first?.snapshot.meaningSnapshot, "수정한 뜻")
        XCTAssertEqual(stats.words.first?.total, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "verb" }?.total, 1)
        XCTAssertEqual(stats.start, calendar.startOfDay(for: original.createAt))
        XCTAssertEqual([copy, original].statsByVocab().count, 2)
    }

    func test_latestSnapshotDecidesPartAndUnknownsRemainIncluded() {
        let word = makeQuizWords(1)[0]
        var old = makeQuizAnswer(word, createAt: statsDate(2025, 8, 20)).history
        old.partOfSpeechSnapshot = "noun"
        var latest = makeQuizAnswer(word, createAt: now).history
        latest.partOfSpeechSnapshot = "new-part"
        latest.topicSnapshot = "myBook"
        let stats = aggregate([latest, old])
        XCTAssertEqual(stats.words.count, 1)
        XCTAssertEqual(stats.words.first?.total, 2)
        XCTAssertEqual(stats.totalAnswers, 2)
        XCTAssertEqual(stats.parts.first { $0.id == "unknown" }?.total, 1)
        XCTAssertEqual(stats.parts.first { $0.id == "noun" }?.total, 0)
        XCTAssertEqual(stats.topics.first { $0.id == "unknown" }?.total, 2)
    }

    func test_futureAnswersAreExcluded() {
        let future = answers(UUID(), correct: 1, total: 1, at: now.addingTimeInterval(1))
        let stats = aggregate(future + answers(UUID(), correct: 0, total: 1))
        XCTAssertEqual(stats.totalAnswers, 1)
        XCTAssertEqual(stats.words.count, 1)
    }

    func test_emptyHistoryHasNoAccuracyAndStartsToday() {
        let empty = aggregate([])
        XCTAssertNil(empty.accuracy)
        XCTAssertTrue(empty.words.isEmpty)
        XCTAssertTrue(empty.mistakeWords.isEmpty)
        XCTAssertEqual(empty.start, calendar.startOfDay(for: now))
    }

    func test_topicsCountAnswersAndPartsCountUniqueWordsOverAllPeriod() {
        let travel = answers(UUID(), correct: 2, total: 3, at: statsDate(2025, 1, 1), topic: "travel", part: "noun")
        let business = answers(UUID(), correct: 0, total: 1, topic: "business", part: "verb")
        let stats = aggregate(travel + business)
        XCTAssertEqual(stats.topics.map(\.id), ["travel", "business", "emotion", "life", "unknown"])
        XCTAssertEqual(stats.topics.map(\.total), [3, 1, 0, 0, 0])
        XCTAssertEqual(stats.parts.map(\.id), ["noun", "verb", "adj", "adv", "unknown"])
        XCTAssertEqual(stats.parts.map(\.total), [1, 1, 0, 0, 0])
        XCTAssertEqual(stats.start, calendar.startOfDay(for: statsDate(2025, 1, 1)))
    }

    func test_mistakeWordsUseDisplayedRoundedAccuracy() {
        let ids = (0..<4).map { _ in UUID() }
        let rows = answers(ids[0], correct: 352, total: 500)   // 70.4% → "70%"
            + answers(ids[1], correct: 141, total: 200)        // 70.5% → "71%"
            + answers(ids[2], correct: 0, total: 1)            // 0%
            + answers(ids[3], correct: 3, total: 3)            // 100%
        let stats = aggregate(rows)
        XCTAssertEqual(stats.words.count, 4)
        XCTAssertEqual(Set(stats.mistakeWords.map(\.id)), [ids[0], ids[2]])
    }

    func test_fortyAndTwentyThresholdsFilterMistakeWordsKeepingOrder() {
        let ids = (0..<6).map { _ in UUID() }
        let rows = answers(ids[0], correct: 1, total: 2)       // 50%, 오답 1
            + answers(ids[1], correct: 202, total: 500)        // 40.4% → 40, 오답 298
            + answers(ids[2], correct: 81, total: 200)         // 40.5% → 41, 오답 119
            + answers(ids[3], correct: 102, total: 500)        // 20.4% → 20, 오답 398
            + answers(ids[4], correct: 41, total: 200)         // 20.5% → 21, 오답 159
            + answers(ids[5], correct: 0, total: 1)            // 0%, 오답 1
        let mistakes = aggregate(rows).mistakeWords
        XCTAssertEqual(mistakes.map(\.id), [ids[3], ids[1], ids[4], ids[2], ids[5], ids[0]])
        XCTAssertEqual(mistakes.filter(StudyStatsMistakeThreshold.forty.contains).map(\.id), [ids[3], ids[1], ids[4], ids[5]])
        XCTAssertEqual(mistakes.filter(StudyStatsMistakeThreshold.twenty.contains).map(\.id), [ids[3], ids[5]])
    }

    func test_mistakeWordsSortByWrongCountThenAccuracyThenRecencyThenId() throws {
        let ids = try (1...6).map { try XCTUnwrap(UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", $0))) }
        let rows = answers(ids[5], correct: 1, total: 4)                                // 오답 3
            + answers(ids[4], correct: 0, total: 2)                                     // 오답 2, 0%
            + answers(ids[3], correct: 1, total: 3)                                     // 오답 2, 33%
            + answers(ids[2], correct: 1, total: 2, at: now.addingTimeInterval(-60))    // 오답 1, 50%, 이전 풀이
            + answers(ids[1], correct: 1, total: 2)                                     // 오답 1, 50%, 최근 풀이
            + answers(ids[0], correct: 1, total: 2)                                     // 같은 조건이면 id순
        XCTAssertEqual(aggregate(rows).mistakeWords.map(\.id), [ids[5], ids[4], ids[3], ids[0], ids[1], ids[2]])
    }

    func test_stableRankingByIdForLegacyRows() throws {
        let ids = try [XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
                       XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))]
        let rows = ids.reversed().map { LearningHistory(id: UUID(), vocabId: $0, isCorrect: true, createAt: now) }
        XCTAssertEqual(aggregate(rows).words.map(\.id), ids)
    }

    private func aggregate(_ rows: [LearningHistory]) -> StudyStats {
        DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []), now: now, calendar: calendar)
    }

    // 한 단어의 풀이 total회 중 앞 correct회 정답
    private func answers(_ id: UUID, correct: Int, total: Int, at date: Date? = nil,
                         topic: String? = nil, part: String? = nil) -> [LearningHistory] {
        (0..<total).map {
            LearningHistory(id: UUID(), vocabId: id, isCorrect: $0 < correct, createAt: date ?? now,
                            topicSnapshot: topic, partOfSpeechSnapshot: part)
        }
    }
}
