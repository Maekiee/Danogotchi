import Foundation
import RxSwift

protocol FetchBookVocabsUseCase {
    func execute(topic: BookTopic) -> Observable<[VocabDisplayInfo]>
}


final class DefaultFetchBookVocabsUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let recommendBookRepository: RecommendBookRepository
    private let learningHistoryRepository: LearningHistoryRepository
    
    init(
        vocabBookRepository: VocabBookRepository,
        recommendBookRepository: RecommendBookRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.recommendBookRepository = recommendBookRepository
        self.learningHistoryRepository = learningHistoryRepository
    }
    
    private func fetchVocabs(topic: BookTopic) -> Observable<[Vocab]> {
        switch topic {
        case .myBook:
            let vocabs = vocabBookRepository.readAllBooks(type: .mine).first
                .map { vocabBookRepository.fetchVocabs(inBookId: $0.id).reversed() } ?? []
            return .just(Array(vocabs))
        default:
            return recommendBookRepository.fetchRecommendBooks()
                .map { books in
                    books.first { $0.originBookId == topic.recommendBookId }?.vocabList ?? []
                }
        }
    }
    
    // MyBookDetailViewModel의 정답률 집계 로직 이관
    private func joinWithHistory(_ vocabs: [Vocab]) -> [VocabDisplayInfo] {
        let histories = learningHistoryRepository.fetchAllHistory()
        let stats = Dictionary(grouping: histories, by: { $0.vocabId })
            .mapValues { list -> (correct: Int, total: Int) in
                (list.filter { $0.isCorrect }.count, list.count)
            }
        return vocabs.map { vocab in
            guard let s = stats[vocab.id], s.total > 0 else {
                return VocabDisplayInfo(word: vocab, learningCount: 0, accuracy: 0)
            }
            return VocabDisplayInfo(
                word: vocab,
                learningCount: s.total,
                accuracy: Double(s.correct) / Double(s.total)
            )
        }
    }
}

extension DefaultFetchBookVocabsUseCase: FetchBookVocabsUseCase {
    func execute(topic: BookTopic) -> RxSwift.Observable<[VocabDisplayInfo]> {
        fetchVocabs(topic: topic)
            .map { [weak self] vocabs in
                self?.joinWithHistory(vocabs) ?? []
            }
    }
    
    
}
