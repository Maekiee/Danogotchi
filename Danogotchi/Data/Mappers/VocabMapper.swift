import Foundation

extension VocabEntity {
    func toDomain() -> Vocab {
        guard let id = id,
              let word = word,
              let meaning = meaning,
              let createAt = createAt else { preconditionFailure("VocabEntity required property is nil") }
        return Vocab(id: id, word: word, meaning: meaning, createAt: createAt)
    }
}
