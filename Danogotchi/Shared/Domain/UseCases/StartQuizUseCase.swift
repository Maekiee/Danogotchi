import Foundation


enum StartQuizResult {
    case success(QuizData)
    /// 활성 단어장이 없거나 단어가 0개
    case noWords
    /// 4지선다 보기 구성을 위해 최소 4개 필요
    case notEnoughWords
}

protocol StartQuizUseCase {
    /// 활성 단어장에서 출제 세트를 선정
    func execute() -> StartQuizResult
}

final class DefaultStartQuizUseCase: StartQuizUseCase {
    static let maxQuizWordCount = 20
    static let minimumWordCount = 4
    private let vocabBookRepository: VocabBookRepository
    private let learningHistoryRepository: LearningHistoryRepository

    init(
        vocabBookRepository: VocabBookRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learningHistoryRepository = learningHistoryRepository
    }

    func execute() -> StartQuizResult {
        guard let activeBook = vocabBookRepository.readActiveBook(),
              !activeBook.vocabList.isEmpty else {
            return .noWords
        }
        let allWords = activeBook.vocabList

        guard allWords.count >= Self.minimumWordCount else {
            return .notEnoughWords
        }

        // allWord는 4지선다 오답 보기 풀이므로 세트 크기와 무관하게 항상 전체를 넘긴다
        if allWords.count <= Self.maxQuizWordCount {
            return .success(QuizData(words: allWords.shuffled(), allWord: allWords))
        }

        let stats = learningHistoryRepository.fetchAllHistory().statsByVocab()
        var generator = SystemRandomNumberGenerator()
        let selected = Self.selectByTournament(
            from: allWords,
            stats: stats,
            limit: Self.maxQuizWordCount,
            using: &generator
        )
        return .success(QuizData(words: selected, allWord: allWords))
    }

    /// 토너먼트 선택: 랜덤 후보 2개 중 학습횟수(total)가 낮은 단어를 채택한다. 동률이면 랜덤.
    /// 채택된 단어는 후보에서 제외되고, 탈락한 단어는 후보에 남는다. `vocabs.count > limit` 전제로 호출한다.
    static func selectByTournament<G: RandomNumberGenerator>(
        from vocabs: [Vocab],
        stats: [UUID: LearningStats],
        limit: Int,
        using generator: inout G
    ) -> [Vocab] {
        var candidates = vocabs
        var selected: [Vocab] = []
        selected.reserveCapacity(limit)

        while selected.count < limit, candidates.count >= 2 {
            // 서로 다른 두 후보 인덱스를 뽑는다
            let firstIndex = Int.random(in: 0..<candidates.count, using: &generator)
            var secondIndex = Int.random(in: 0..<(candidates.count - 1), using: &generator)
            if secondIndex >= firstIndex { secondIndex += 1 }

            // 이력 없는 신규 단어는 학습횟수 0으로 취급되어 항상 우선 채택된다
            let firstTotal = stats[candidates[firstIndex].id]?.total ?? 0
            let secondTotal = stats[candidates[secondIndex].id]?.total ?? 0

            let winnerIndex: Int
            if firstTotal != secondTotal {
                winnerIndex = firstTotal < secondTotal ? firstIndex : secondIndex
            } else {
                winnerIndex = Bool.random(using: &generator) ? firstIndex : secondIndex
            }
            selected.append(candidates.remove(at: winnerIndex))
        }

        // 학습횟수가 낮은 단어가 앞쪽에 몰리는 채택 순서 편향을 제거한다
        return selected.shuffled(using: &generator)
    }
}
