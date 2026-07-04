import Foundation


struct VocabDisplayInfo: Hashable {
    let word: Vocab
    let learningCount: Int
    let accuracy: Double
}


extension VocabDisplayInfo: CardDisplayable {
    var cardTitle: String { word.word }
    var cardSubtitle: String { word.meaning }
    var cardChipText: Int? { learningCount }
    var cardAccuracy: Double? { accuracy }
}
