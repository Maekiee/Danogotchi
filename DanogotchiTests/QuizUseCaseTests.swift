import XCTest
@testable import Danogotchi

final class QuizUseCaseTests: XCTestCase {
    func test_startWithoutActiveBookHasNoWords() throws {
        guard case .noWords = try startQuiz(wordCount: nil) else { return XCTFail("No active book") }
    }

    func test_startWithEmptyActiveBookHasNoWords() throws {
        guard case .noWords = try startQuiz(wordCount: 0) else { return XCTFail("Empty book") }
    }

    func test_startWithThreeWordsIsNotEnough() throws {
        guard case .notEnoughWords = try startQuiz(wordCount: 3) else { return XCTFail("Three words cannot start") }
    }

    func test_startWithFourWordsBuildsQuizOfDistinctWords() throws {
        guard case .success(let quiz) = try startQuiz(wordCount: 4) else { return XCTFail("Four words must start") }
        XCTAssertEqual(quiz.words.count, 4)
        XCTAssertEqual(Set(quiz.words.map(\.id)).count, 4)
    }

    // wordCount가 nil이면 활성 단어장 없이 시작
    private func startQuiz(wordCount: Int?) throws -> StartQuizResult {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        if let wordCount {
            let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
            try books.setActive(id: book.id, isActive: true)
            for word in makeQuizWords(wordCount) { _ = try books.addVocab(bookId: book.id, from: word) }
        }
        return try DefaultStartQuizUseCase(vocabBookRepository: books,
                                           learningHistoryRepository: DefaultLearningHistoryRepository(context: context)).execute()
    }

    func test_startCombinesEveryLearningBookAndCountsWithoutSavedCopies() throws {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let travel = try books.createBook(title: "travel", bookType: .travel, level: .a1)
        let myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        _ = try books.createBook(title: "life", bookType: .life, level: .a1)
        let travelWords = try (0..<2).map {
            try books.addVocab(bookId: travel.id, word: "travel\($0)", meaning: "여행\($0)",
                               bookType: .travel, level: .a1, partOfSpeech: .noun)
        }
        _ = try books.addVocab(bookId: myBook.id, from: travelWords[0])
        let ownWord = try books.addVocab(bookId: myBook.id, word: "own", meaning: "내 단어",
                                         bookType: .myBook, level: nil, partOfSpeech: .noun)
        try books.setActive(id: travel.id, isActive: true)
        try books.setActive(id: myBook.id, isActive: true)
        let useCase = DefaultStartQuizUseCase(vocabBookRepository: books,
                                               learningHistoryRepository: DefaultLearningHistoryRepository(context: context))

        // 저장 복사본은 원본과 같은 단어라 세지 않는다 — 3개
        guard case .notEnoughWords = try useCase.execute() else { return XCTFail("Copies must not count") }

        _ = try books.addVocab(bookId: myBook.id, word: "more", meaning: "더", bookType: .myBook, level: nil, partOfSpeech: .noun)
        guard case .success(let quiz) = try useCase.execute() else { return XCTFail("Four combined words must start") }
        XCTAssertEqual(quiz.words.count, 4)
        XCTAssertTrue(Set(quiz.words.map(\.id)).isSuperset(of: Set(travelWords.map(\.id) + [ownWord.id])))
    }

    func test_startCapsAtTwentyWithoutRepeatingWordsAndRetainsDistractorPool() throws {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        for word in makeQuizWords(30) { _ = try books.addVocab(bookId: book.id, from: word) }
        try books.setActive(id: book.id, isActive: true)
        let useCase = DefaultStartQuizUseCase(vocabBookRepository: books,
                                               learningHistoryRepository: DefaultLearningHistoryRepository(context: context))
        guard case .success(let quiz) = try useCase.execute() else { return XCTFail("Expected quiz") }
        XCTAssertEqual(quiz.words.count, 20)
        XCTAssertEqual(Set(quiz.words.map(\.id)).count, 20)
        XCTAssertEqual(quiz.allWord.count, 30)
        XCTAssertTrue(Set(quiz.words.map(\.id)).isSubset(of: Set(quiz.allWord.map(\.id))))
    }

    func test_tournamentChoosesLessStudiedOfTwoCandidates() {
        let words = makeQuizWords(2)
        let stats = [words[0].id: LearningStats(correct: 8, total: 10)]
        var generator = SystemRandomNumberGenerator()
        let result = DefaultStartQuizUseCase.selectByTournament(from: words, stats: stats, limit: 1, using: &generator)
        XCTAssertEqual(result.map(\.id), [words[1].id])
    }

    func test_rewardUsesHistoryBeforeCurrentAnswerAndWrongAnswerEarnsNothing() throws {
        let context = makeInMemoryContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let history = DefaultLearningHistoryRepository(context: context)
        let useCase = DefaultEarnExperienceUseCase(learningHistoryRepository: history,
                                                    petRepository: DefaultPetRepository(context: context))
        XCTAssertEqual(try useCase.record(makeQuizAnswer(word, isCorrect: false)), 0)
        XCTAssertEqual(try useCase.record(makeQuizAnswer(word)), 38)
        XCTAssertEqual(try history.fetchHistory(vocabId: word.id).count, 2)
        XCTAssertEqual(try useCase.record(makeQuizAnswer(word)), 26)
    }

    func test_perfectBonusRequiresNonEmptyPerfectSession() {
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 20, total: 20), 100)
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 19, total: 20), 0)
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 0, total: 0), 0)
    }
}
