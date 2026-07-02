import Foundation

struct LearningHistory: Hashable {
    let id: UUID
    let vocabId: UUID
    let isCorrect: Bool
    let createAt: Date
}
