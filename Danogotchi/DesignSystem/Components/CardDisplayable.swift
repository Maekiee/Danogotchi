import Foundation

protocol CardDisplayable {
    var cardTitle: String { get }
    var cardSubtitle: String { get }
    var cardChipText: Int? { get }
    var cardAccuracy: Double? { get }
    var cardPartOfSpeech: String? { get }
}

// Domain 타입의 카드 표시 채택은 표현 계층에 둔다 — Domain이 DesignSystem을 알지 않도록
extension VocabDisplayInfo: CardDisplayable {
    var cardTitle: String { word.word }
    var cardSubtitle: String { word.meaning }
    var cardChipText: Int? { learningCount }
    var cardAccuracy: Double? { accuracy }
    var cardPartOfSpeech: String? { word.partOfSpeech?.title }
}
