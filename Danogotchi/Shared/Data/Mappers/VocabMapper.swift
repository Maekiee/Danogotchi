import Foundation

extension VocabEntity {
    func toDomain() -> Vocab {
        guard let id = id,
              let word = word,
              let meaning = meaning,
              let bookTypeRawValue = bookType,
              let bookType = BookTopic(rawValue: bookTypeRawValue),
              let createAt = createAt else { preconditionFailure("VocabEntity required property is nil") }
        return Vocab(
            id: id,
            word: word,
            meaning: meaning,
            bookType: bookType,
            level: level.flatMap(VocabLevel.init(rawValue:)),
            partOfSpeech: partOfSpeech.flatMap(PartOfSpeech.init(rawValue:)),
            createAt: createAt
        )
    }
}
