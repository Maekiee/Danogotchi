import Foundation

struct StudyStatsWordList: Equatable, Sendable {
    let start: Date
    let end: Date
    let calendar: Calendar
    let words: [VocabStats]
}
