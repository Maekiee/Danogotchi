import Foundation

protocol VocabBookRepository {
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) -> VocabBook
    func readAllBooks() -> [VocabBook]
    func readAllBooks(bookType: BookTopic) -> [VocabBook]
    func readBook(id: UUID) -> VocabBook?
    func updateBook(id: UUID, title: String)
    func deleteBook(id: UUID)
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?) -> Vocab?
    func addVocab(bookId: UUID, from vocab: Vocab) -> Vocab? /// 추천 단어를 대상 단어장에 복사한다. 이미 저장돼 있으면 nil.
    func fetchVocabs(inBookId id: UUID) -> [Vocab]
    func findVocab(inBookId id: UUID, sourceWordId: UUID) -> Vocab? /// 대상 단어장에서 sourceWordId가 일치하는 복사본을 찾는다.
}
