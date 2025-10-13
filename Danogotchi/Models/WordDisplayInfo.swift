import Foundation


struct WordDisplayInfo: Hashable {
    let word: Word
    let learningCount: Int
}


extension WordDisplayInfo: CardDisplayable {
    var cardThumbnail: String? { word.thumbnail }
    var cardTitle: String { word.word }
    var cardSubtitle: String { word.meaning }
    var cardChipText: Int? { learningCount }
}
