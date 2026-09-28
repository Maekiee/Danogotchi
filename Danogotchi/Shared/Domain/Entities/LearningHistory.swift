import Foundation

struct LearningHistory: Hashable, Sendable {
    let id: UUID
    let vocabId: UUID
    let isCorrect: Bool
    let createAt: Date
    var sourceWordIdSnapshot: UUID?
    var wordSnapshot: String = ""
    var meaningSnapshot: String = ""
    var topicSnapshot: String?
    var partOfSpeechSnapshot: String?
    var sessionId: UUID?
    var questionIndex: Int?

    var reportWordId: UUID { sourceWordIdSnapshot ?? vocabId }
}
