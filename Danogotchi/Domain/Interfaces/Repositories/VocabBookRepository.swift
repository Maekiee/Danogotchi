import Foundation

protocol VocabBookRepository {
    func createBook(title: String, type: VocabBookType, originBookId: String?) -> VocabBook
    func readAllBooks() -> [VocabBook]
    func readAllBooks(type: VocabBookType) -> [VocabBook]
    func readBook(id: UUID) -> VocabBook?
    func updateBook(id: UUID, title: String)
    func deleteBook(id: UUID)
    func addVocab(bookId: UUID, word: String, meaning: String, originWordId: String?) -> Vocab?
    func fetchVocabs(inBookId id: UUID) -> [Vocab]
}
