import Foundation
import OSLog

enum ExperiencePolicy {
    
    static let base = 10
    static let noveltyMax = 10
    static let difficultyMax = 20

    static func experience(for stats: LearningStats?) -> Int {
        guard let stats, stats.total > 0 else {
            return base + noveltyMax
        }
        let novelty = max(0, noveltyMax - stats.total * 2)
        let difficulty = Int((Double(difficultyMax) * (1 - stats.accuracy)).rounded())
        return base + novelty + difficulty
    }

    static func perfectBonus(correct: Int, total: Int) -> Int {
        guard total > 0, correct == total else { return 0 }
        return total * total / 4
    }
}


protocol EarnExperienceUseCase {
    func record(vocabId: UUID, isCorrect: Bool) -> Int
    func commit(earned: Int, correct: Int, total: Int) -> ExperienceGain
}

final class DefaultEarnExperienceUseCase: EarnExperienceUseCase {
    private let learningHistoryRepository: LearningHistoryRepository
    private let petRepository: PetRepository

    init(
        learningHistoryRepository: LearningHistoryRepository,
        petRepository: PetRepository
    ) {
        self.learningHistoryRepository = learningHistoryRepository
        self.petRepository = petRepository
    }

    func record(vocabId: UUID, isCorrect: Bool) -> Int {
        let stats = learningHistoryRepository.fetchHistory(vocabId: vocabId)
            .statsByVocab()[vocabId]
        learningHistoryRepository.addHistory(vocabId: vocabId, isCorrect: isCorrect)
        return isCorrect ? ExperiencePolicy.experience(for: stats) : 0
    }

    func commit(earned: Int, correct: Int, total: Int) -> ExperienceGain {
        let bonus = ExperiencePolicy.perfectBonus(correct: correct, total: total)
        if petRepository.addExperience(earned + bonus) == nil {
            AppLogger.database.error("펫이 없어 경험치를 적립하지 못했다")
            CrashReporter.log("펫이 없어 경험치를 적립하지 못했다")
        }
        return ExperienceGain(earned: earned, perfectBonus: bonus)
    }
}
