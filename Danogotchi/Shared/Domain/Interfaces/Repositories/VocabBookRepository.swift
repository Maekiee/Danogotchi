import Foundation
import RxSwift

protocol VocabBookRepository {
    var activeBookId: Observable<UUID?> { get }
    func readActiveBook() -> VocabBook?
    func setActiveBook(id: UUID)
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) -> VocabBook
    func readAllBooks() -> [VocabBook]
    func readAllBooks(bookType: BookTopic) -> [VocabBook]
    func readBook(id: UUID) -> VocabBook?
    func updateBook(id: UUID, title: String)
    func deleteBook(id: UUID)
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?, partOfSpeech: PartOfSpeech?) -> Vocab?
    func addVocab(bookId: UUID, from vocab: Vocab) -> Vocab?
    func fetchVocabs(inBookId id: UUID) -> [Vocab]
    func findVocab(inBookId id: UUID, sourceWordId: UUID) -> Vocab? 
}
