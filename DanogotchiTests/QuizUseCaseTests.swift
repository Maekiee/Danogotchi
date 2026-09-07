import XCTest
@testable import Danogotchi

final class QuizUseCaseTests: XCTestCase {
    func test_startRequiresActiveBookAndAtLeastFourWords() throws {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let useCase = DefaultStartQuizUseCase(vocabBookRepository: books,
                                               learningHistoryRepository: DefaultLearningHistoryRepository(context: context))
        guard case .noWords = try useCase.execute() else { return XCTFail("No active book") }
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        try books.setActiveBook(id: book.id)
        guard case .noWords = try useCase.execute() else { return XCTFail("Empty book") }
        for word in makeQuizWords(3) {
            _ = try books.addVocab(bookId: book.id, from: word)
        }
        guard case .notEnoughWords = try useCase.execute() else { return XCTFail("Three words cannot start") }
        _ = try books.addVocab(bookId: book.id, from: makeQuizWords(4)[3])
        guard case .success(let quiz) = try useCase.execute() else { return XCTFail("Four words must start") }
        XCTAssertEqual(quiz.words.count, 4)
        XCTAssertEqual(Set(quiz.words.map(\.id)).count, 4)
    }

    func test_startCapsAtTwentyWithoutRepeatingWordsAndRetainsDistractorPool() throws {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        for word in makeQuizWords(30) { _ = try books.addVocab(bookId: book.id, from: word) }
        try books.setActiveBook(id: book.id)
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
        XCTAssertEqual(try useCase.record(vocabId: word.id, isCorrect: false), 0)
        XCTAssertEqual(try useCase.record(vocabId: word.id, isCorrect: true), 38)
        XCTAssertEqual(try history.fetchHistory(vocabId: word.id).count, 2)
        XCTAssertEqual(try useCase.record(vocabId: word.id, isCorrect: true), 26)
    }

    func test_perfectBonusRequiresNonEmptyPerfectSession() {
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 20, total: 20), 100)
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 19, total: 20), 0)
        XCTAssertEqual(ExperiencePolicy.perfectBonus(correct: 0, total: 0), 0)
    }
}
