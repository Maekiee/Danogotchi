import Foundation

protocol VocabRepository {
    func createVocab(vocab: String, meaning: String, originWordId: String?) -> Vocab
    func readAllVocab() -> [Vocab]
    func readVocab(id: UUID) -> Vocab?
    func updateVocab(id: UUID, word: String?, meaning: String?)
    func deleteVocab(id: UUID)
}
