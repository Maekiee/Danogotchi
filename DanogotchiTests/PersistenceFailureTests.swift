import CoreData
import XCTest
@testable import Danogotchi

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

    @MainActor
    func test_failedActivationDoesNotPublishOrChangeActiveBooks() async throws {
        let context = makeFailingSaveContext()
        let repository = DefaultVocabBookRepository(context: context)
        let first = try repository.createBook(title: "first", bookType: .travel, level: nil)
        let second = try repository.createBook(title: "second", bookType: .life, level: nil)
        try repository.setActive(id: first.id, isActive: true)
        // 실패 전에 구독을 등록해야 신호가 없었음을 확인할 수 있다
        let changes = repository.activeBookChanged
        let unexpected = expectation(description: "failed activation must not publish")
        unexpected.isInverted = true
        let observation = Task { for await _ in changes { unexpected.fulfill() } }
        context.failsSave = true

        XCTAssertThrowsError(try repository.setActive(id: second.id, isActive: true))
        await fulfillment(of: [unexpected], timeout: 0.1)
        observation.cancel()
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try repository.readActiveBooks().map(\.id), [first.id])

        var retryChanges = repository.activeBookChanged.makeAsyncIterator()
        context.failsSave = false
        try repository.setActive(id: second.id, isActive: true)
        let received: Void? = await retryChanges.next()
        XCTAssertNotNil(received)
        // 학습중은 여러 권 — 기존 단어장도 그대로 학습중이다
        XCTAssertEqual(try repository.readActiveBooks().map(\.id), [first.id, second.id])
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
        let answer = makeQuizAnswer(word)
        context.failsSave = true
        XCTAssertThrowsError(try useCase.record(answer))
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try history.fetchAllHistory().isEmpty)
        context.failsSave = false
        XCTAssertEqual(try useCase.record(answer), 20)
        XCTAssertEqual(try history.fetchHistory(vocabId: word.id).count, 1)
    }

    func test_failedSeedRollsBackAndRetryCreatesExactlyOneMyBook() throws {
        let context = makeFailingSaveContext()
        context.failsSave = true
        XCTAssertThrowsError(try DatabaseSeeder.seedIfNeeded(context: context))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.count(for: VocabBookEntity.fetchRequest()), 0)
        context.failsSave = false
        try DatabaseSeeder.seedIfNeeded(context: context)
        try DatabaseSeeder.seedIfNeeded(context: context)
        XCTAssertEqual(try context.count(for: VocabBookEntity.fetchRequest()), 1)
    }

    @MainActor
    func test_failedImportLeavesNoBookOrWordsAndRetryImportsOnce() async throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        let remote = ControlledRemoteVocabBookRepository()
        let serverWords = makeServerVocabs(travelA1, words: ["airport", "depart"])
        remote.vocabs[travelA1] = serverWords
        let useCase = DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote)
        context.failsSave = true

        do {
            try await useCase.execute(key: travelA1, isActive: true, loaded: [])
            XCTFail("저장 실패를 전달해야 한다")
        } catch {}
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.count(for: VocabBookEntity.fetchRequest()), 0)
        XCTAssertEqual(try context.count(for: VocabEntity.fetchRequest()), 0)

        context.failsSave = false
        try await useCase.execute(key: travelA1, isActive: true, loaded: [])
        XCTAssertEqual(try books.readActiveBooks().map(\.key), [travelA1])
        XCTAssertEqual(try context.count(for: VocabEntity.fetchRequest()), 2)
    }

    func test_missingWriteTargetsThrowInsteadOfReportingSuccess() throws {
        let context = makeFailingSaveContext()
        let words = DefaultVocabRepository(context: context)
        XCTAssertThrowsError(try words.updateVocab(id: UUID(), word: "missing", meaning: nil, partOfSpeech: nil))
        XCTAssertThrowsError(try words.deleteVocab(id: UUID()))
        XCTAssertThrowsError(try DefaultVocabBookRepository(context: context).setActive(id: UUID(), isActive: true))
        XCTAssertThrowsError(try DefaultLearningHistoryRepository(context: context).addHistory(makeQuizAnswer(makeQuizWords(1)[0])))
        XCTAssertThrowsError(try DefaultPetRepository(context: context).addExperience(10))
        let books = DefaultVocabBookRepository(context: context)
        XCTAssertThrowsError(try books.addVocab(bookId: UUID(), word: "missing", meaning: "없음",
                                                bookType: .myBook, level: nil, partOfSpeech: .noun))
        XCTAssertThrowsError(try books.addVocab(bookId: UUID(), from: makeQuizWords(1)[0]))
    }
}
