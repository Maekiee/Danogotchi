import Foundation

protocol VocabBookRepository {
    /// 학습중 단어장이 바뀌었다는 신호. 값 캐시가 아니므로 신호를 받으면 readActiveBooks()로 다시 읽는다.
    var activeBookChanged: AsyncStream<Void> { get }
    func readActiveBooks() throws -> [VocabBook]
    /// 단어장마다 독립적으로 켜고 끈다. 끄더라도 단어는 남는다
    func setActive(id: UUID, isActive: Bool) throws
    /// 서버 단어장을 단어 id 그대로 저장한다. 저장 한 번이라 실패하면 단어장·단어 모두 남지 않는다
    func importBook(key: VocabBookKey, vocabs: [Vocab], isActive: Bool) throws -> VocabBook
    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) throws -> VocabBook
    /// 단어를 읽지 않는 단어장 목록. createAt 순
    func readBookSummaries() throws -> [VocabBookSummary]
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

extension VocabBookRepository {
    /// 주제·레벨이 같으면 같은 단어장 — 서버 ID 이전에 받은 기존 단어장도 받은 것으로 본다
    func readBookSummary(key: VocabBookKey) throws -> VocabBookSummary? {
        return try readBookSummaries().first { $0.key == key }
    }
}
