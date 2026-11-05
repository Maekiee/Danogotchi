import Foundation

// 원본 단어 기준 풀이 통계(복사본 합산, 마지막 풀이 스냅샷), 카드별 수치는 LearningStats
struct VocabStats: Equatable, Sendable, Identifiable {
    let id: UUID
    var snapshot: LearningHistory
    var total: Int
    var correct: Int

    var accuracy: Double { Double(correct) / Double(total) }
}

extension Array where Element == LearningHistory {
    // 원본 단어별로 묶어 정답 횟수순 정렬, 카드별 수치는 statsByVocab()
    func vocabStats() -> [VocabStats] {
        let grouped = Dictionary(grouping: self, by: \.statsWordId)
        let words = grouped.compactMap { id, answers -> VocabStats? in
            guard let latest = answers.max(by: {
                $0.createAt == $1.createAt ? $0.id.uuidString < $1.id.uuidString : $0.createAt < $1.createAt
            }) else { return nil }
            return VocabStats(id: id, snapshot: latest, total: answers.count,
                              correct: answers.filter(\.isCorrect).count)
        }
        return words.sorted {
            if $0.correct != $1.correct { return $0.correct > $1.correct }
            if $0.accuracy != $1.accuracy { return $0.accuracy > $1.accuracy }
            if $0.snapshot.createAt != $1.snapshot.createAt { return $0.snapshot.createAt > $1.snapshot.createAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
