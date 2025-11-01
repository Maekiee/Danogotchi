import Foundation
import RxSwift
import RxCocoa

protocol RecommendBookRepoProtocol {
    func fetchRecommendBooks() -> Observable<[WordBook]>
}

final class RecommendBookRepository: RecommendBookRepoProtocol {
    
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
    
    
    // 5. [(String, String)] 배열을 [Word] 배열로 변환하는 헬퍼 함수
    private func generateWords(from data: [(String, String)]) -> [Word] {
        return data.enumerated().map { (index, item) in
            Word(
                id: "mock_word_\(item.0)_\(index)", // 고유 ID 생성
                thumbnail: "", // 썸네일은 일단 비워둠
                word: item.0,
                meaning: item.1,
                createAt: Date()
            )
        }
    }
    
    // 6. [Word] 배열을 WordBook 구조체로 변환하는 헬퍼 함수
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
