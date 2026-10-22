import Foundation


struct VocabDisplayInfo: Hashable {
    let word: Vocab
    let learningCount: Int
    let accuracy: Double
    var isSaved: Bool = false
}


extension VocabDisplayInfo {
    init(word: Vocab, stats: LearningStats?, isSaved: Bool = false) {
        self.init(
            word: word,
            learningCount: stats?.total ?? 0,
            accuracy: stats?.accuracy ?? 0,
            isSaved: isSaved
        )
    }
}
