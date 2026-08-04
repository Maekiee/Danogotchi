import Foundation

extension VocabBookEntity {
    func toDomain() -> VocabBook {
        guard let id = id,
              let title = title,
              let bookTypeRawValue = bookType,
              let bookType = BookTopic(rawValue: bookTypeRawValue),
              let createAt = createAt else { preconditionFailure("VocabBookEntity required property is nil") }

        let vocabList = (vocabs?.allObjects as? [VocabEntity] ?? [])
            .map { $0.toDomain() }
            .sorted { $0.createAt < $1.createAt }

        return VocabBook(
            id: id,
            title: title,
            bookType: bookType,
            level: level.flatMap(VocabLevel.init(rawValue:)),
            vocabList: vocabList,
            isActive: isActive,
            createAt: createAt
        )
    }
}
