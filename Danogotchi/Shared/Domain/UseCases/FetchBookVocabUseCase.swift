import Foundation
import RxSwift

protocol FetchVocabsUseCase {
    /// 활성 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 executeActive()로 다시 읽는다.
    var activeBookChanged: Observable<Void> { get }
    func execute(topic: BookTopic) -> Observable<[VocabDisplayInfo]>
    func executeActive() -> Observable<(bookType: BookTopic, items: [VocabDisplayInfo])>
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

    var activeBookChanged: Observable<Void> {
        return vocabBookRepository.activeBookId.map { _ in () }
    }
    
    func execute(topic: BookTopic) -> Observable<[VocabDisplayInfo]> {
        fetchVocabs(topic: topic)
            .map { [weak self] vocabs -> [VocabDisplayInfo] in
                guard let self else { return [] }
                return self.joinWithHistory(vocabs, savedSourceIDs: self.savedSourceIDs(topic: topic))
            }
    }

    func executeActive() -> Observable<(bookType: BookTopic, items: [VocabDisplayInfo])> {
        guard let book = vocabBookRepository.readActiveBook() else { return .empty() }
        let items = joinWithHistory(
            book.vocabList,
            savedSourceIDs: savedSourceIDs(topic: book.bookType)
        )
        return .just((bookType: book.bookType, items: items))
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
        let stats = learningHistoryRepository.fetchAllHistory().statsByVocab()
        return vocabs.map { vocab in
            VocabDisplayInfo(
                word: vocab,
                stats: stats[vocab.id],
                isSaved: savedSourceIDs.contains(vocab.id)
            )
        }
    }
}
