import Foundation


struct WordDisplayInfo: Hashable {
    let word: Word
    let learningCount: Int
    let accuracy: Double
}


extension WordDisplayInfo: CardDisplayable {
   
    
    var cardTitle: String { word.word }
    var cardSubtitle: String { word.meaning }
    var cardChipText: Int? { learningCount }
    var cardAccuracy: Double? { accuracy }
}
