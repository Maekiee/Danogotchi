import Foundation
import RxSwift

protocol FetchVocabsUseCase {
    func execute(topic: BookTopic) -> Observable<[VocabDisplayInfo]>
}

final class DefaultFetchVocabsUseCase: FetchVocabsUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let learningHistoryRepository: LearningHistoryRepository

    init(
        vocabBookRepository: VocabBookRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learningHistoryRepository = learningHistoryRepository
    }
    
    func execute(topic: BookTopic) -> Observable<[VocabDisplayInfo]> {
        fetchVocabs(topic: topic)
            .map { [weak self] vocabs -> [VocabDisplayInfo] in
                guard let self else { return [] }
                return self.joinWithHistory(vocabs, savedSourceIDs: self.savedSourceIDs(topic: topic))
            }
    }

    private func fetchVocabs(topic: BookTopic) -> Observable<[Vocab]> {
        switch topic {
        case .myBook:
            let vocabs = vocabBookRepository.readAllBooks(bookType: .myBook).first
                .map { vocabBookRepository.fetchVocabs(inBookId: $0.id).reversed() } ?? []
            return .just(Array(vocabs))
        default:
            return .just(vocabBookRepository.readAllBooks(bookType: topic).first?.vocabList ?? [])
        }
    }
    
    /// 추천 단어장 화면에서만 필요 — 나의 단어장에 복사된 단어들의 원본 id 집합
    private func savedSourceIDs(topic: BookTopic) -> Set<UUID> {
        guard topic != .myBook,
              let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first else { return [] }
        return Set(vocabBookRepository.fetchVocabs(inBookId: myBook.id).compactMap { $0.sourceWordId })
    }

    // MyBookDetailViewModel의 정답률 집계 로직 이관
    private func joinWithHistory(_ vocabs: [Vocab], savedSourceIDs: Set<UUID>) -> [VocabDisplayInfo] {
        let histories = learningHistoryRepository.fetchAllHistory()
        let stats = Dictionary(grouping: histories, by: { $0.vocabId })
            .mapValues { list -> (correct: Int, total: Int) in
                (list.filter { $0.isCorrect }.count, list.count)
            }
        return vocabs.map { vocab in
            let isSaved = savedSourceIDs.contains(vocab.id)
            guard let s = stats[vocab.id], s.total > 0 else {
                return VocabDisplayInfo(word: vocab, learningCount: 0, accuracy: 0, isSaved: isSaved)
            }
            return VocabDisplayInfo(
                word: vocab,
                learningCount: s.total,
                accuracy: Double(s.correct) / Double(s.total),
                isSaved: isSaved
            )
        }
    }
}
