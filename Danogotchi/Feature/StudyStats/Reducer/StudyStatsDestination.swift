import Foundation

enum StudyStatsDestination: Equatable, Sendable {
    case stats
    case words(StudyStatsWordList)
    case word(VocabStats, isDaily: Bool)
}
