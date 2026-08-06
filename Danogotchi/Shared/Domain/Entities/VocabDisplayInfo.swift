import Foundation


struct VocabDisplayInfo: Hashable {
    let word: Vocab
    let learningCount: Int
    let accuracy: Double
    var isSaved: Bool = false /// DB 필드가 아니라 조회 시점에 나의 단어장 멤버십으로 계산되는 표시용 값
}


extension VocabDisplayInfo {
    /// 집계된 학습 이력으로 표시용 정보를 조립한다. 이력이 없으면 0으로 채운다.
    init(word: Vocab, stats: LearningStats?, isSaved: Bool = false) {
        self.init(
            word: word,
            learningCount: stats?.total ?? 0,
            accuracy: stats?.accuracy ?? 0,
            isSaved: isSaved
        )
    }
}


extension VocabDisplayInfo: CardDisplayable {
    var cardTitle: String { word.word }
    var cardSubtitle: String { word.meaning }
    var cardChipText: Int? { learningCount }
    var cardAccuracy: Double? { accuracy }
    var cardPartOfSpeech: String? { word.partOfSpeech?.title }
}
