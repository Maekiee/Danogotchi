import Foundation

struct StudyStats: Equatable, Sendable {
    struct Category: Equatable, Sendable, Identifiable {
        let id: String
        let total: Int
    }

    let now: Date
    let calendar: Calendar
    let start: Date
    let totalAnswers: Int
    let totalCorrect: Int
    let words: [VocabStats]
    let mistakeWords: [VocabStats]
    let topics: [Category]
    let parts: [Category]
}
