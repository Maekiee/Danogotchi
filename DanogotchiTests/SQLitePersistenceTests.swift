import CoreData
import XCTest
@testable import Danogotchi

@MainActor
final class SQLitePersistenceTests: XCTestCase {
    func test_booksWordsHistoryAndPetSurviveStoreReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite")
        let first = try openStore(url: url)
        let context = first.viewContext
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let word = try books.addVocab(bookId: book.id, word: "apple", meaning: "사과",
                                      bookType: .myBook, level: nil, partOfSpeech: .noun)
        try books.setActiveBook(id: book.id)
        try DefaultVocabRepository(context: context).updateVocab(id: word.id, word: "pear", meaning: "배", partOfSpeech: nil)
        try DefaultLearningHistoryRepository(context: context).addHistory(vocabId: word.id, isCorrect: true)
        let pets = DefaultPetRepository(context: context)
        let pet = try XCTUnwrap(pets.createPet(makePet(name: "saved", experience: 10)))
        _ = try pets.addExperience(25)
        try closeStore(first)

        let reopened = try openStore(url: url)
        defer { try? closeStore(reopened) }
        let reopenedBooks = DefaultVocabBookRepository(context: reopened.viewContext)
        XCTAssertEqual(try reopenedBooks.readActiveBook()?.id, book.id)
        let persistedWord = try XCTUnwrap(reopenedBooks.fetchVocabs(inBookId: book.id).first)
        XCTAssertEqual(persistedWord.id, word.id)
        XCTAssertEqual(persistedWord.word, "pear")
        XCTAssertEqual(persistedWord.meaning, "배")
        let history = try DefaultLearningHistoryRepository(context: reopened.viewContext).fetchHistory(vocabId: word.id)
        XCTAssertEqual(history.count, 1)
        XCTAssertTrue(try XCTUnwrap(history.first).isCorrect)
        let persistedPet = try XCTUnwrap(DefaultPetRepository(context: reopened.viewContext).readPet())
        XCTAssertEqual(persistedPet.id, pet.id)
        XCTAssertEqual(persistedPet.name, "saved")
        XCTAssertEqual(persistedPet.experience, 35)
    }

    func test_wordDeletionAndHistoryCascadeSurviveStoreReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite")
        let first = try openStore(url: url)
        let words = DefaultVocabRepository(context: first.viewContext)
        let word = try words.createVocab(vocab: "apple", meaning: "사과")
        try DefaultLearningHistoryRepository(context: first.viewContext).addHistory(vocabId: word.id, isCorrect: true)
        try words.deleteVocab(id: word.id)
        try closeStore(first)

        let reopened = try openStore(url: url)
        defer { try? closeStore(reopened) }
        XCTAssertNil(try DefaultVocabRepository(context: reopened.viewContext).readVocab(id: word.id))
        XCTAssertTrue(try DefaultLearningHistoryRepository(context: reopened.viewContext).fetchAllHistory().isEmpty)
    }

    private func openStore(url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Model")
        let description = NSPersistentStoreDescription(url: url)
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }

    private func closeStore(_ container: NSPersistentContainer) throws {
        container.viewContext.reset()
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }
}
