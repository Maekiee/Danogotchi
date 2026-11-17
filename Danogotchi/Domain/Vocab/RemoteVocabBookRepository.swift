import Foundation

protocol RemoteVocabBookRepository {
    func fetchBooks() async throws -> [RemoteVocabBook]
    /// 단어 id는 서버 UUID 그대로 — 저장 단어·학습 기록이 다시 받아도 이어진다
    func fetchVocabs(key: VocabBookKey) async throws -> [Vocab]
}
