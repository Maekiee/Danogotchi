import Foundation

protocol VocabRepository {
    func createVocab(vocab: String, meaning: String) throws -> Vocab
    func readAllVocab() throws -> [Vocab]
    /// 받은 단어장·나의 단어장을 합친 저장된 전체 단어 수
    func countAllVocabs() throws -> Int
    func readVocab(id: UUID) throws -> Vocab?
    func updateVocab(id: UUID, word: String?, meaning: String?, partOfSpeech: PartOfSpeech?) throws
    func deleteVocab(id: UUID) throws
}
