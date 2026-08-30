import Foundation


struct LearningStats {
    let correct: Int
    let total: Int

    var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }
}


extension Array where Element == LearningHistory {
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
