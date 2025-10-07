import Foundation

struct QuizResult {
    let correct: Int
    let total: Int
    let incorrectWords: [WordModel]
    let mode: QuizMode
    let nextStartIndex: Int
    let hasNextSection: Bool
}
