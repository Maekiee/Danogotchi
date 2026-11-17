import Foundation

struct QuizSession: Equatable, Sendable, Identifiable {
    let id: UUID
    let startedAt: Date
    let questionCount: Int
}
