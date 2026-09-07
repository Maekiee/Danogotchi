import Foundation
import RxSwift

protocol VocabBookRepository {
    /// 활성 단어장이 바뀌었다는 신호. 값 캐시가 아니므로 신호를 받으면 readActiveBook()으로 다시 읽는다.
    var activeBookChanged: Observable<Void> { get }
    func readActiveBook() throws -> VocabBook?
    func setActiveBook(id: UUID) throws
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) throws -> VocabBook
    func readAllBooks() throws -> [VocabBook]
    func readAllBooks(bookType: BookTopic) throws -> [VocabBook]
    func readBook(id: UUID) throws -> VocabBook?
    func updateBook(id: UUID, title: String) throws
    func deleteBook(id: UUID) throws
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?, partOfSpeech: PartOfSpeech?) throws -> Vocab
    /// 이미 담긴 단어면 기존 단어를 그대로 돌려준다 (멱등).
    func addVocab(bookId: UUID, from vocab: Vocab) throws -> Vocab
    func fetchVocabs(inBookId id: UUID) throws -> [Vocab]
    func findVocab(inBookId id: UUID, sourceWordId: UUID) throws -> Vocab?
}
