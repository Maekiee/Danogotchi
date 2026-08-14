import Foundation
import OSLog


/// 경험치 산정 규칙 — 학습횟수가 적고 정답률이 낮은 단어를 맞힐수록 많이 준다.
enum ExperiencePolicy {
    
    static let base = 10
    static let noveltyMax = 10
    static let difficultyMax = 20

    /// 정답 1개의 경험치.
    /// `stats`는 이번 정답을 이력에 반영하기 **전** 값이어야 한다 — 반영 후 값을 쓰면 방금 맞힌 정답이
    /// 정답률을 끌어올려 보상이 깎인다.
    static func experience(for stats: LearningStats?) -> Int {
        guard let stats, stats.total > 0 else {
            // 처음 맞힌 단어는 정답률을 알 수 없으므로 난이도 가산 없이 학습횟수 가산만 준다
            return base + noveltyMax
        }
        let novelty = max(0, noveltyMax - stats.total * 2)
        let difficulty = Int((Double(difficultyMax) * (1 - stats.accuracy)).rounded())
        return base + novelty + difficulty
    }

    /// 출제된 문제를 하나도 틀리지 않았을 때만 붙는 보너스.
    /// 세트가 작을수록 만점이 쉬우므로(4문제 66% vs 20문제 12%) 문제 수의 제곱에 비례시켜
    /// 작은 단어장 반복이 더 이득이 되는 역전을 막는다. 20문제 만점 = +100.
    static func perfectBonus(correct: Int, total: Int) -> Int {
        guard total > 0, correct == total else { return 0 }
        return total * total / 4
    }
}


protocol EarnExperienceUseCase {
    /// 학습 이력을 기록하고 이번 정답으로 얻은 경험치를 돌려준다 (오답은 0).
    func record(vocabId: UUID, isCorrect: Bool) -> Int
    /// 세션에서 모은 경험치에 만점 보너스를 더해 적립하고 내역을 돌려준다.
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
        // 산정이 먼저 — addHistory 뒤의 정답률로 계산하면 방금 맞힌 정답이 스스로 보상을 깎는다
        let stats = learningHistoryRepository.fetchHistory(vocabId: vocabId)
            .statsByVocab()[vocabId]
        learningHistoryRepository.addHistory(vocabId: vocabId, isCorrect: isCorrect)
        return isCorrect ? ExperiencePolicy.experience(for: stats) : 0
    }

    /// 적립은 `totalExperience`만 올린다 — `stateUpdatedAt`·HP를 건드리면 미정산 경과시간이 유실된다.
    func commit(earned: Int, correct: Int, total: Int) -> ExperienceGain {
        let bonus = ExperiencePolicy.perfectBonus(correct: correct, total: total)
        guard let totalPoint = petRepository.addExperience(earned + bonus) else {
            // 온보딩이 펫 생성을 강제하므로 정상 경로에서는 발생하지 않는다
            AppLogger.database.error("펫이 없어 경험치를 적립하지 못했다")
            return ExperienceGain(earned: earned, perfectBonus: bonus, totalPoint: 0)
        }
        return ExperienceGain(earned: earned, perfectBonus: bonus, totalPoint: totalPoint)
    }
}
