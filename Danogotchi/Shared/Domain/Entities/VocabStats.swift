import Foundation

// 원본 단어 기준 풀이 통계(복사본 합산, 마지막 풀이 스냅샷), 카드별 수치는 LearningStats
struct VocabStats: Equatable, Sendable, Identifiable {
    let id: UUID
    var snapshot: LearningHistory
    var total: Int
    var correct: Int

    var accuracy: Double { Double(correct) / Double(total) }
}
