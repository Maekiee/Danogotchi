import Foundation
import RxSwift
import RxCocoa

final class DefaultRecommendBookRepository: RecommendBookRepository {
    
    func fetchRecommendBooks() -> RxSwift.Observable<[VocabBook]> {
        let travelBook = createVocabBook(
            id: "rec_travel_001",
            title: "Travel",
            data: MockTravelWords.data
        )
        let businessBook = createVocabBook(
            id: "rec_business_002",
            title: "Business",
            data: MockBusinessWords.data
        )
        let emotionBook = createVocabBook(
            id: "rec_emotion_003",
            title: "Emotions",
            data: MockEmotionWords.data
        )
        let lifeBook = createVocabBook(
            id: "rec_life_004",
            title: "Life",
            data: MockLifeWords.data
        )
        let recommendBooks = [
            travelBook,
            businessBook,
            emotionBook,
            lifeBook
        ]
        return .just(recommendBooks)
    }
    
    private func generateVocabs(from data: [(String, String)]) -> [Vocab] {
        return data.map {
            Vocab(
                id: UUID(),
                word: $0.0,
                meaning: $0.1,
                createAt: Date()
            )
        }
    }
    
    private func createVocabBook(id: String, title: String, data: [(String, String)]) -> VocabBook {
        let vocabs = generateVocabs(from: data)
        return VocabBook(
            id: UUID(),
            title: title,
            type: .recommended,
            originBookId: id,
            vocabList: vocabs,
            createAt: Date()
        )
    }
}
