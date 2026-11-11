import Foundation

struct QuizResult {
    let correct: Int
    let total: Int
    let incorrectWords: [Vocab]
    let experience: ExperienceGain
}
