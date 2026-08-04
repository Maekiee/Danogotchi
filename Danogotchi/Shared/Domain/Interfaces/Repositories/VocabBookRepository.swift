import Foundation
import RxSwift

protocol VocabBookRepository {
    var activeBookId: Observable<UUID?> { get } /// 활성 단어장 변경 신호. 값 캐시가 아니므로 내용은 `readActiveBook()`으로 다시 읽는다.
    func readActiveBook() -> VocabBook? /// 현재 활성 단어장. 없으면 nil.
    func setActiveBook(id: UUID) /// 활성 단어장으로 지정한다. 기존 활성 단어장은 같은 트랜잭션에서 해제된다.
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) -> VocabBook
    func readAllBooks() -> [VocabBook]
    func readAllBooks(bookType: BookTopic) -> [VocabBook]
    func readBook(id: UUID) -> VocabBook?
    func updateBook(id: UUID, title: String)
    func deleteBook(id: UUID)
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?, partOfSpeech: PartOfSpeech?) -> Vocab?
    func addVocab(bookId: UUID, from vocab: Vocab) -> Vocab? /// 추천 단어를 대상 단어장에 복사한다. 이미 저장돼 있으면 nil.
    func fetchVocabs(inBookId id: UUID) -> [Vocab]
    func findVocab(inBookId id: UUID, sourceWordId: UUID) -> Vocab? /// 대상 단어장에서 sourceWordId가 일치하는 복사본을 찾는다.
}
