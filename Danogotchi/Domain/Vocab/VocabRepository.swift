import Foundation

protocol VocabRepository {
    func createVocab(vocab: String, meaning: String) throws -> Vocab
    func readAllVocab() throws -> [Vocab]
    func readVocab(id: UUID) throws -> Vocab?
    func updateVocab(id: UUID, word: String?, meaning: String?, partOfSpeech: PartOfSpeech?) throws
    func deleteVocab(id: UUID) throws
}
