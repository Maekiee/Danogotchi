import Foundation

struct StudyStatsRecords: Sendable {
    let histories: [LearningHistory]
    let sessions: [QuizSession]
}
