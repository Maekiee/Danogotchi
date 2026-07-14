import Foundation

protocol VocabBookRepository {
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) -> VocabBook
    func readAllBooks() -> [VocabBook]
    func readAllBooks(bookType: BookTopic) -> [VocabBook]
    func readBook(id: UUID) -> VocabBook?
    func updateBook(id: UUID, title: String)
    func deleteBook(id: UUID)
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?) -> Vocab?
    func fetchVocabs(inBookId id: UUID) -> [Vocab]
}
