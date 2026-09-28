import Foundation

extension LearningHistoryEntity {
    func toDomain() throws -> LearningHistory {
        guard let id = id,
              let vocabId = vocabId,
              let createAt = createAt,
              let wordSnapshot, let meaningSnapshot else {
            throw StudyReportDataError.invalidRecord
        }
        
        return LearningHistory(
            id: id,
            vocabId: vocabId,
            isCorrect: isCorrect,
            createAt: createAt,
            sourceWordIdSnapshot: sourceWordIdSnapshot,
            wordSnapshot: wordSnapshot, meaningSnapshot: meaningSnapshot,
            topicSnapshot: topicSnapshot, partOfSpeechSnapshot: partOfSpeechSnapshot,
            sessionId: session?.id, questionIndex: questionIndex?.intValue
        )
    }
}
