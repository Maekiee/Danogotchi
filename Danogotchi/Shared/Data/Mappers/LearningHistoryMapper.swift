import Foundation

extension LearningHistoryEntity {
    func toDomain() -> LearningHistory {
        guard let id = id,
              let vocabId = vocab?.id,
              let createAt = createAt else {
            preconditionFailure("LearningHistoryEntity required property is nil")
        }
        
        return LearningHistory(
            id: id,
            vocabId: vocabId,
            isCorrect: isCorrect,
            createAt: createAt
        )
    }
}
