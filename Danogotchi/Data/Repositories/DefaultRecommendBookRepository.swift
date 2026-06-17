import Foundation
import RxSwift
import RxCocoa

final class DefaultRecommendBookRepository: RecommendBookRepository {
    
    func fetchRecommendBooks() -> RxSwift.Observable<[WordBook]> {
        let travelBook = createWordBook(
                    id: "rec_travel_001",
                    title: "Travel",
                    data: MockTravelWords.data
                )
                
                let businessBook = createWordBook(
                    id: "rec_business_002",
                    title: "Business",
                    data: MockBusinessWords.data
                )
                
                let emotionBook = createWordBook(
                    id: "rec_emotion_003",
                    title: "Emotions",
                    data: MockEmotionWords.data
                )
                
                let lifeBook = createWordBook(
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
    
    private func generateWords(from data: [(String, String)]) -> [Word] {
        return data.enumerated().map { (index, item) in
            Word(
                id: "mock_word_\(item.0)_\(index)",
                word: item.0,
                meaning: item.1,
                createAt: Date()
            )
        }
    }
    
    private func createWordBook(id: String, title: String, data: [(String, String)]) -> WordBook {
        let words = generateWords(from: data)
        return WordBook(
            id: id,
            title: title,
            wordList: words,
            createAt: Date()
        )
    }
}
