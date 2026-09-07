import CoreData
import RxSwift
import XCTest
@testable import Danogotchi

final class FailingSaveContext: NSManagedObjectContext, @unchecked Sendable {
    var failsSave = false

    override func save() throws {
        if failsSave { throw CocoaError(.fileWriteOutOfSpace) }
        try super.save()
    }
}

func makeFailingSaveContext() -> FailingSaveContext {
    let context = FailingSaveContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = makeInMemoryContext().persistentStoreCoordinator
    return context
}

final class PersistenceFailureTests: XCTestCase {
    func test_failedUpdateRollsBackAndCanRetry() throws {
        let context = makeFailingSaveContext()
        let repository = DefaultVocabRepository(context: context)
        let word = try repository.createVocab(vocab: "apple", meaning: "사과")
        context.failsSave = true

        XCTAssertThrowsError(try repository.updateVocab(id: word.id, word: "pear", meaning: nil, partOfSpeech: nil))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try repository.readVocab(id: word.id)?.word, "apple")

        context.failsSave = false
        try repository.updateVocab(id: word.id, word: "pear", meaning: nil, partOfSpeech: nil)
        XCTAssertEqual(try repository.readVocab(id: word.id)?.word, "pear")
    }

    func test_failedActivationDoesNotPublishOrChangeActiveBook() throws {
        let context = makeFailingSaveContext()
        let repository = DefaultVocabBookRepository(context: context)
        let first = try repository.createBook(title: "first", bookType: .travel, level: nil)
        let second = try repository.createBook(title: "second", bookType: .life, level: nil)
        try repository.setActiveBook(id: first.id)
        var changes = 0
        let subscription = repository.activeBookChanged.subscribe(onNext: { _ in changes += 1 })
        defer { subscription.dispose() }
        context.failsSave = true

        XCTAssertThrowsError(try repository.setActiveBook(id: second.id))
        XCTAssertEqual(changes, 0)
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try repository.readActiveBook()?.id, first.id)

        context.failsSave = false
        try repository.setActiveBook(id: second.id)
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(try repository.readActiveBook()?.id, second.id)
    }

    func test_failedExperienceSaveDoesNotAccumulateOnRetry() throws {
        let context = makeFailingSaveContext()
        let repository = DefaultPetRepository(context: context)
        _ = try repository.createPet(makePet(experience: 10))
        context.failsSave = true

        XCTAssertThrowsError(try repository.addExperience(20))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try repository.readPet()?.experience, 10)

        context.failsSave = false
        XCTAssertEqual(try repository.addExperience(20), 30)
    }
}

extension PersistenceFailureTests {
    func test_failedCreationLeavesNoOrphanAndRetryCreatesOneWord() throws {
        let context = makeFailingSaveContext()
        let repository = DefaultVocabRepository(context: context)
        context.failsSave = true
        XCTAssertThrowsError(try repository.createVocab(vocab: "apple", meaning: "사과"))
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try repository.readAllVocab().isEmpty)
        context.failsSave = false
        _ = try repository.createVocab(vocab: "apple", meaning: "사과")
        XCTAssertEqual(try repository.readAllVocab().count, 1)
    }

    func test_failedDeletionRestoresWordAndRetryDeletesIt() throws {
        let context = makeFailingSaveContext()
        let repository = DefaultVocabRepository(context: context)
        let word = try repository.createVocab(vocab: "apple", meaning: "사과")
        context.failsSave = true
        XCTAssertThrowsError(try repository.deleteVocab(id: word.id))
        XCTAssertFalse(context.hasChanges)
        XCTAssertNotNil(try repository.readVocab(id: word.id))
        context.failsSave = false
        try repository.deleteVocab(id: word.id)
        XCTAssertNil(try repository.readVocab(id: word.id))
    }

    func test_failedHistoryRecordCanRetryWithoutChangingRewardOrDuplicatingHistory() throws {
        let context = makeFailingSaveContext()
        let words = DefaultVocabRepository(context: context)
        let word = try words.createVocab(vocab: "apple", meaning: "사과")
        let history = DefaultLearningHistoryRepository(context: context)
        let useCase = DefaultEarnExperienceUseCase(learningHistoryRepository: history,
                                                    petRepository: DefaultPetRepository(context: context))
        context.failsSave = true
        XCTAssertThrowsError(try useCase.record(vocabId: word.id, isCorrect: true))
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try history.fetchAllHistory().isEmpty)
        context.failsSave = false
        XCTAssertEqual(try useCase.record(vocabId: word.id, isCorrect: true), 20)
        XCTAssertEqual(try history.fetchHistory(vocabId: word.id).count, 1)
    }

    func test_failedSeedRollsBackAndRetryCreatesExactlyOneSetOfBooks() throws {
        let context = makeFailingSaveContext()
        context.failsSave = true
        XCTAssertThrowsError(try DatabaseSeeder.seedIfNeeded(context: context))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.count(for: VocabBookEntity.fetchRequest()), 0)
        context.failsSave = false
        try DatabaseSeeder.seedIfNeeded(context: context)
        try DatabaseSeeder.seedIfNeeded(context: context)
        XCTAssertEqual(try context.count(for: VocabBookEntity.fetchRequest()), 5)
        XCTAssertEqual(try context.count(for: VocabEntity.fetchRequest()), 1457)
    }

    func test_missingWriteTargetsThrowInsteadOfReportingSuccess() throws {
        let context = makeFailingSaveContext()
        let words = DefaultVocabRepository(context: context)
        XCTAssertThrowsError(try words.updateVocab(id: UUID(), word: "missing", meaning: nil, partOfSpeech: nil))
        XCTAssertThrowsError(try words.deleteVocab(id: UUID()))
        XCTAssertThrowsError(try DefaultVocabBookRepository(context: context).setActiveBook(id: UUID()))
        XCTAssertThrowsError(try DefaultLearningHistoryRepository(context: context).addHistory(vocabId: UUID(), isCorrect: true))
        XCTAssertThrowsError(try DefaultPetRepository(context: context).addExperience(10))
        let books = DefaultVocabBookRepository(context: context)
        XCTAssertThrowsError(try books.addVocab(bookId: UUID(), word: "missing", meaning: "없음",
                                                bookType: .myBook, level: nil, partOfSpeech: .noun))
        XCTAssertThrowsError(try books.addVocab(bookId: UUID(), from: makeQuizWords(1)[0]))
    }
}
