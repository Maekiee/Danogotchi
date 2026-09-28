import CoreData
import XCTest
@testable import Danogotchi

@MainActor
final class StudyReportPersistenceTests: XCTestCase {
    func test_invalidQuestionIndexAndEmptySessionDoNotInsertRows() throws {
        let context = makeInMemoryContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context)
        let date = Date()
        for (count, index) in [(0, 0), (2, -1), (2, 2)] {
            let session = QuizSession(id: UUID(), startedAt: date, questionCount: count)
            XCTAssertThrowsError(try repository.addHistory(makeQuizAnswer(word, createAt: date, session: session, questionIndex: index)))
        }
        XCTAssertTrue(try repository.fetchAllHistory().isEmpty)
        XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 0)
    }

    func test_identicalRetryKeepsOneAnswerAndSameReward() throws {
        let context = makeInMemoryContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context)
        let useCase = DefaultEarnExperienceUseCase(learningHistoryRepository: repository, petRepository: DefaultPetRepository(context: context))
        let answer = makeQuizAnswer(word)
        XCTAssertEqual(try useCase.record(answer), 20)
        XCTAssertEqual(try useCase.record(answer), 20)
        XCTAssertEqual(try repository.fetchAllHistory(), [answer.history])
        XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 1)
    }

    func test_conflictingQuestionAnswerAndSessionDoNotOverwriteSavedData() throws {
        let context = makeInMemoryContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context)
        let answer = makeQuizAnswer(word)
        try repository.addHistory(answer)
        let sameQuestion = makeQuizAnswer(word, createAt: answer.history.createAt, session: answer.session)
        let changedAnswer = makeQuizAnswer(word, isCorrect: false, id: answer.history.id,
                                          createAt: answer.history.createAt, session: answer.session)
        let changedSession = QuizSession(id: answer.session.id, startedAt: answer.session.startedAt, questionCount: 2)
        for conflict in [sameQuestion, changedAnswer, makeQuizAnswer(word, createAt: answer.history.createAt, session: changedSession)] {
            XCTAssertThrowsError(try repository.addHistory(conflict))
            XCTAssertFalse(context.hasChanges)
            XCTAssertEqual(try repository.fetchAllHistory(), [answer.history])
        }
        try repository.addHistory(answer)
        XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 1)
    }

    func test_failedFirstSaveRollsBackBothSessionAndAnswer() throws {
        let context = makeFailingSaveContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context)
        let answer = makeQuizAnswer(word)
        context.failsSave = true
        XCTAssertThrowsError(try repository.addHistory(answer))
        XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 0)
        XCTAssertTrue(try repository.fetchAllHistory().isEmpty)
        context.failsSave = false
        try repository.addHistory(answer)
        XCTAssertEqual(try repository.fetchAllHistory(), [answer.history])
    }

    func test_bookDeletionAndUnsavePreserveSnapshotAndOriginalTopic() throws {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let originalBook = try books.createBook(title: "Travel", bookType: .travel, level: nil)
        let personalBook = try books.createBook(title: "My", bookType: .myBook, level: nil)
        let original = try books.addVocab(bookId: originalBook.id, word: "journey", meaning: "여행",
                                          bookType: .travel, level: nil, partOfSpeech: .noun)
        let copy = try books.addVocab(bookId: personalBook.id, from: original)
        XCTAssertEqual(copy.originalTopic, "travel")
        let histories = DefaultLearningHistoryRepository(context: context)
        let originalAnswer = makeQuizAnswer(original)
        let copyAnswer = makeQuizAnswer(copy)
        try histories.addHistory(originalAnswer)
        try histories.addHistory(copyAnswer)
        try books.deleteBook(id: originalBook.id)
        try DefaultVocabRepository(context: context).deleteVocab(id: copy.id)
        XCTAssertEqual(try histories.fetchAllHistory().count, 2)
        XCTAssertEqual(try histories.fetchHistory(vocabId: copy.id), [copyAnswer.history])
        XCTAssertEqual(try histories.fetchHistory(vocabId: original.id), [originalAnswer.history])
    }

    func test_sessionDeletionKeepsAnswersAndAnswerDeletionKeepsSession() throws {
        let context = makeInMemoryContext()
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context)
        let session = QuizSession(id: UUID(), startedAt: Date(), questionCount: 2)
        let first = makeQuizAnswer(word, session: session, questionIndex: 0)
        let second = makeQuizAnswer(word, session: session, questionIndex: 1)
        try repository.addHistory(first)
        try repository.addHistory(second)
        context.delete(try XCTUnwrap(context.fetch(QuizSessionEntity.fetchRequest()).first))
        try context.saveOrRollback()
        let rows = try repository.fetchAllHistory()
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.allSatisfy { $0.sessionId == nil })
        XCTAssertEqual(Set(rows.compactMap(\.questionIndex)), [0, 1])
        XCTAssertEqual(rows.first?.wordSnapshot, "apple")

        let third = makeQuizAnswer(word)
        try repository.addHistory(third)
        let request = LearningHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", third.history.id as CVarArg)
        context.delete(try XCTUnwrap(context.fetch(request).first))
        try context.saveOrRollback()
        XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 1)
        XCTAssertEqual(try repository.fetchAllHistory().count, 2)
    }

    func test_commitFailureDoesNotRemoveCompletedSession() async throws {
        let context = makeFailingSaveContext()
        let pets = DefaultPetRepository(context: context)
        _ = try pets.createPet(makePet())
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let history = DefaultLearningHistoryRepository(context: context)
        let useCase = DefaultEarnExperienceUseCase(learningHistoryRepository: history, petRepository: pets)
        let earned = try useCase.record(makeQuizAnswer(word))
        context.failsSave = true
        XCTAssertThrowsError(try useCase.commit(earned: earned, correct: 1, total: 1))
        let records = try await history.fetchReportRecords()
        let report = try DefaultFetchStudyReportUseCase.aggregate(records, period: .all, now: Date(), calendar: reportCalendar())
        XCTAssertEqual(report.sessions.count, 1)
        context.failsSave = false
        _ = try useCase.commit(earned: earned, correct: 1, total: 1)
        XCTAssertEqual(try history.fetchAllHistory().count, 1)
    }
}
