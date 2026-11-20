import Foundation

extension VocabEntity {
    func toDomain() -> Vocab {
        guard let id,
              let word,
              let meaning,
              let bookTypeRawValue = bookType,
              let bookType = BookTopic(rawValue: bookTypeRawValue),
              let createAt else { preconditionFailure("VocabEntity required property is nil") }
        return Vocab(
            id: id,
            word: word,
            meaning: meaning,
            bookType: bookType,
            level: level.flatMap(VocabLevel.init(rawValue:)),
            partOfSpeech: partOfSpeech.flatMap(PartOfSpeech.init(rawValue:)),
            sourceWordId: sourceWordId,
            createAt: createAt,
            originalTopic: originalTopic
        )
    }
}
