import Foundation


/// vocabId별 학습 이력 집계 값 — 표시(카드/상세)와 출제 선정(StartQuiz)이 공유한다
struct LearningStats {
    let correct: Int
    let total: Int

    var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }
}


extension Array where Element == LearningHistory {
    /// vocabId 기준으로 (정답 수, 학습 횟수)를 집계한다
    func statsByVocab() -> [UUID: LearningStats] {
        Dictionary(grouping: self, by: { $0.vocabId })
            .mapValues { histories in
                LearningStats(
                    correct: histories.filter { $0.isCorrect }.count,
                    total: histories.count
                )
            }
    }
}
