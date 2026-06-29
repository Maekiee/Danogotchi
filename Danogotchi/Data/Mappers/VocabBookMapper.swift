import Foundation

extension VocabBookEntity {
    func toDomain() -> VocabBook {
        guard let id = id,
              let title = title,
              let typeRawValue = type,
              let type = VocabBookType(rawValue: typeRawValue),
              let createAt = createAt else { preconditionFailure("VocabBookEntity required property is nil") }
        
        let vocabList = (vocabs?.allObjects as? [VocabEntity] ?? [])
            .map { $0.toDomain() }
            .sorted { $0.createAt < $1.createAt }
        
        return VocabBook(
            id: id,
            title: title,
            type: type,
            originBookId: originBookId,
            vocabList: vocabList,
            createAt: createAt
        )
    }
}
