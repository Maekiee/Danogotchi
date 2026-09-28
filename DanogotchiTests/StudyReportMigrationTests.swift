import CoreData
import XCTest
@testable import Danogotchi

@MainActor
final class StudyReportMigrationTests: XCTestCase {
    private let backfillVersionKey = "com.maekie.Danogotchi.studyReportBackfillVersion"

    func test_sqliteMigrationBackfillsSnapshotsAndKeepsLegacyIndicesNil() throws {
        try withStoreURL { url in
            let oldModel = try legacyModel()
            let original = try open(url, model: oldModel)
            let wordID = UUID()
            let copyID = UUID()
            let historyID = UUID()
            let date = reportDate(2026, 8, 20)
            _ = insertWord(in: original.viewContext, id: wordID, topic: "travel")
            let copy = insertWord(in: original.viewContext, id: copyID, topic: "myBook")
            copy.setValue(wordID, forKey: "sourceWordId")
            let history = NSEntityDescription.insertNewObject(forEntityName: "LearningHistoryEntity", into: original.viewContext)
            history.setValue(historyID, forKey: "id")
            history.setValue(false, forKey: "isCorrect")
            history.setValue(date, forKey: "createAt")
            history.setValue(copy, forKey: "vocab")
            try original.viewContext.save()
            try close(original)

            let currentModel = NSPersistentContainer(name: "Model").managedObjectModel
            try StudyReportMigration.preflight(storeURL: url, destinationModel: currentModel)
            let migrated = try open(url)
            try StudyReportMigration.backfillIfNeeded(context: migrated.viewContext)
            let repository = DefaultLearningHistoryRepository(context: migrated.viewContext)
            let rows = try repository.fetchAllHistory()
            let row = try XCTUnwrap(rows.first)
            XCTAssertEqual(rows.count, 1)
            XCTAssertEqual(row.id, historyID)
            XCTAssertEqual(row.vocabId, copyID)
            XCTAssertEqual(row.sourceWordIdSnapshot, wordID)
            XCTAssertEqual(row.wordSnapshot, "journey")
            XCTAssertEqual(row.meaningSnapshot, "여행")
            XCTAssertEqual(row.topicSnapshot, "travel")
            XCTAssertEqual(row.partOfSpeechSnapshot, "noun")
            XCTAssertEqual(row.createAt, date)
            XCTAssertFalse(row.isCorrect)
            XCTAssertNil(row.sessionId)
            XCTAssertNil(row.questionIndex)
            XCTAssertEqual(try DefaultVocabRepository(context: migrated.viewContext).readVocab(id: copyID)?.originalTopic, "travel")

            try DefaultVocabRepository(context: migrated.viewContext).updateVocab(id: copyID, word: "changed", meaning: "새 뜻", partOfSpeech: .verb)
            try StudyReportMigration.backfill(context: migrated.viewContext)
            XCTAssertEqual(try repository.fetchAllHistory(), rows)
            try DefaultVocabRepository(context: migrated.viewContext).deleteVocab(id: copyID)
            try close(migrated)

            let reopened = try open(url)
            defer { try? close(reopened) }
            XCTAssertEqual(try backfillVersion(in: reopened.viewContext), 1)
            reopened.viewContext.retainsRegisteredObjects = true
            try StudyReportMigration.backfillIfNeeded(context: reopened.viewContext)
            XCTAssertTrue(reopened.viewContext.registeredObjects.isEmpty)
            XCTAssertEqual(try DefaultLearningHistoryRepository(context: reopened.viewContext).fetchAllHistory(), rows)
        }
    }

    func test_emptyStorePersistsBackfillCompletion() throws {
        try withStoreURL { url in
            let container = try open(url)
            XCTAssertFalse(container.viewContext.hasChanges)
            try StudyReportMigration.backfillIfNeeded(context: container.viewContext)
            try close(container)

            let reopened = try open(url)
            defer { try? close(reopened) }
            XCTAssertEqual(try backfillVersion(in: reopened.viewContext), 1)
        }
    }

    func test_failedBackfillDoesNotMarkCompleteAndCanRetry() throws {
        try withStoreURL { url in
            let container = try open(url)
            defer { try? close(container) }
            let context = FailingSaveContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = container.persistentStoreCoordinator
            defer { context.reset() }
            let history = try insertUnbackfilledHistory(in: context)

            context.failsSave = true
            XCTAssertThrowsError(try StudyReportMigration.backfillIfNeeded(context: context))
            XCTAssertNil(try backfillVersion(in: context))
            XCTAssertNil(history.vocabId)
            XCTAssertFalse(context.hasChanges)

            context.failsSave = false
            try StudyReportMigration.backfillIfNeeded(context: context)
            XCTAssertEqual(history.wordSnapshot, "journey")
            XCTAssertNotNil(history.vocabId)
            XCTAssertEqual(try backfillVersion(in: context), 1)
        }
    }

    func test_failedCompletionSaveRestoresMetadataAndCanRetry() throws {
        try withStoreURL { url in
            let container = try open(url)
            let coordinator = container.persistentStoreCoordinator
            let store = try XCTUnwrap(coordinator.persistentStores.first)
            let context = FailingSaveContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            var metadata = coordinator.metadata(for: store)
            metadata[backfillVersionKey] = 0
            metadata["testMetadata"] = "preserved"
            coordinator.setMetadata(metadata, for: store)
            try context.save()

            context.failsSave = true
            XCTAssertThrowsError(try StudyReportMigration.backfillIfNeeded(context: context))
            XCTAssertEqual(try backfillVersion(in: context), 0)
            let persisted = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url)
            XCTAssertEqual(persisted[backfillVersionKey] as? Int, 0)

            context.failsSave = false
            try StudyReportMigration.backfillIfNeeded(context: context)
            XCTAssertEqual(try backfillVersion(in: context), 1)
            context.reset()
            try close(container)

            let reopened = try open(url)
            defer { try? close(reopened) }
            XCTAssertEqual(try backfillVersion(in: reopened.viewContext), 1)
            let reopenedStore = try XCTUnwrap(reopened.persistentStoreCoordinator.persistentStores.first)
            XCTAssertEqual(reopened.persistentStoreCoordinator.metadata(for: reopenedStore)["testMetadata"] as? String, "preserved")
        }
    }

    func test_backfilledStoreWithoutCompletionKeepsSnapshotsAfterReopen() throws {
        try withStoreURL { url in
            let container = try open(url)
            let history = try insertUnbackfilledHistory(in: container.viewContext)
            try StudyReportMigration.backfill(context: container.viewContext)
            let original = try history.toDomain()
            XCTAssertNil(try backfillVersion(in: container.viewContext))
            history.vocab?.word = "changed"
            history.vocab?.meaning = "새 뜻"
            try container.viewContext.save()
            try close(container)

            let reopened = try open(url)
            defer { try? close(reopened) }
            try StudyReportMigration.backfillIfNeeded(context: reopened.viewContext)
            XCTAssertEqual(try DefaultLearningHistoryRepository(context: reopened.viewContext).fetchAllHistory(), [original])
            XCTAssertEqual(try backfillVersion(in: reopened.viewContext), 1)
        }
    }

    func test_duplicateLegacyIDsStopBeforeSQLiteMigrationWithoutDeletingRows() throws {
        try withStoreURL { url in
            let sourceModel = try legacyModel()
            let old = try open(url, model: sourceModel)
            let word = insertWord(in: old.viewContext, id: UUID(), topic: "life")
            let duplicateID = UUID()
            for _ in 0..<2 {
                let history = NSEntityDescription.insertNewObject(forEntityName: "LearningHistoryEntity", into: old.viewContext)
                history.setValue(duplicateID, forKey: "id")
                history.setValue(Date(), forKey: "createAt")
                history.setValue(true, forKey: "isCorrect")
                history.setValue(word, forKey: "vocab")
            }
            try old.viewContext.save()
            try close(old)
            XCTAssertThrowsError(try StudyReportMigration.preflight(
                storeURL: url, destinationModel: NSPersistentContainer(name: "Model").managedObjectModel
            )) { XCTAssertEqual($0 as? StudyReportDataError, .invalidIdentifiers) }
            let reopened = try open(url, model: sourceModel)
            defer { try? close(reopened) }
            XCTAssertEqual(try reopened.viewContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "LearningHistoryEntity")), 2)
        }
    }

    func test_nilIdentifierAndMissingSnapshotSourceFailWithoutPartialBackfill() throws {
        let context = makeInMemoryContext()
        let history = LearningHistoryEntity(context: context)
        history.createAt = Date()
        history.isCorrect = true
        XCTAssertThrowsError(try StudyReportMigration.validateIdentifiers(entityName: "LearningHistoryEntity", context: context)) {
            XCTAssertEqual($0 as? StudyReportDataError, .invalidIdentifiers)
        }
        history.id = UUID()
        try context.save()
        XCTAssertThrowsError(try StudyReportMigration.backfill(context: context))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.count(for: LearningHistoryEntity.fetchRequest()), 1)
        XCTAssertNil(try context.fetch(LearningHistoryEntity.fetchRequest()).first?.vocabId)
    }

    func test_sqliteConstraintsRejectDuplicateAnswerAndSessionAndAllowRetryAfterRollback() throws {
        try withStoreURL { url in
            let container = try open(url)
            defer { try? close(container) }
            let context = container.viewContext
            context.mergePolicy = NSErrorMergePolicy
            let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
            let repository = DefaultLearningHistoryRepository(context: context)
            let answer = makeQuizAnswer(word)
            try repository.addHistory(answer)
            let duplicateAnswer = LearningHistoryEntity(context: context)
            duplicateAnswer.id = answer.history.id
            duplicateAnswer.createAt = Date()
            duplicateAnswer.isCorrect = false
            XCTAssertThrowsError(try context.saveOrRollback())
            XCTAssertFalse(context.hasChanges)
            XCTAssertEqual(try repository.fetchAllHistory(), [answer.history])

            let duplicateSession = QuizSessionEntity(context: context)
            duplicateSession.id = answer.session.id
            duplicateSession.startedAt = answer.session.startedAt
            duplicateSession.questionCount = 1
            XCTAssertThrowsError(try context.saveOrRollback())
            XCTAssertFalse(context.hasChanges)
            try repository.addHistory(answer)
            XCTAssertEqual(try context.count(for: QuizSessionEntity.fetchRequest()), 1)
            XCTAssertEqual(try repository.fetchAllHistory(), [answer.history])
        }
    }

    func test_backgroundReadReturnsIndependentValuesAfterDeletedWordAndSession() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let container = try open(directory.appendingPathComponent("report.sqlite"))
        defer { try? close(container) }
        let context = container.viewContext
        let word = try DefaultVocabRepository(context: context).createVocab(vocab: "apple", meaning: "사과")
        let repository = DefaultLearningHistoryRepository(context: context, reportContext: container.newBackgroundContext())
        try repository.addHistory(makeQuizAnswer(word))
        let first = try await repository.fetchReportRecords()
        XCTAssertEqual(first.histories.count, 1)
        XCTAssertEqual(first.sessions.count, 1)
        try DefaultVocabRepository(context: context).deleteVocab(id: word.id)
        context.delete(try XCTUnwrap(context.fetch(QuizSessionEntity.fetchRequest()).first))
        try context.saveOrRollback()
        let second = try await repository.fetchReportRecords()
        XCTAssertEqual(second.histories.first?.wordSnapshot, "apple")
        XCTAssertNil(second.histories.first?.sessionId)
        XCTAssertTrue(second.sessions.isEmpty)
        XCTAssertNotNil(first.histories.first?.sessionId)
    }

    private func legacyModel() throws -> NSManagedObjectModel {
        let bundle = Bundle(for: LearningHistoryEntity.self)
        let directory = try XCTUnwrap(bundle.url(forResource: "Model", withExtension: "momd"))
        return try XCTUnwrap(NSManagedObjectModel(contentsOf: directory.appendingPathComponent("Model.mom")))
    }

    private func backfillVersion(in context: NSManagedObjectContext) throws -> Int? {
        let coordinator = try XCTUnwrap(context.persistentStoreCoordinator)
        let store = try XCTUnwrap(coordinator.persistentStores.first)
        return coordinator.metadata(for: store)[backfillVersionKey] as? Int
    }

    private func insertUnbackfilledHistory(in context: NSManagedObjectContext) throws -> LearningHistoryEntity {
        let word = insertWord(in: context, id: UUID(), topic: "travel")
        let history = LearningHistoryEntity(context: context)
        history.id = UUID()
        history.createAt = reportDate()
        history.isCorrect = true
        history.setValue(word, forKey: "vocab")
        try context.save()
        return history
    }

    private func insertWord(in context: NSManagedObjectContext, id: UUID, topic: String) -> NSManagedObject {
        let word = NSEntityDescription.insertNewObject(forEntityName: "VocabEntity", into: context)
        word.setValue(id, forKey: "id")
        word.setValue("journey", forKey: "word")
        word.setValue("여행", forKey: "meaning")
        word.setValue(topic, forKey: "bookType")
        word.setValue("noun", forKey: "partOfSpeech")
        word.setValue(Date(), forKey: "createAt")
        return word
    }

    private func open(_ url: URL, model: NSManagedObjectModel? = nil) throws -> NSPersistentContainer {
        let container = model.map { NSPersistentContainer(name: "Model", managedObjectModel: $0) }
            ?? NSPersistentContainer(name: "Model")
        let description = NSPersistentStoreDescription(url: url)
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }

    private func close(_ container: NSPersistentContainer) throws {
        container.viewContext.reset()
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    private func withStoreURL(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory.appendingPathComponent("report.sqlite"))
    }
}
