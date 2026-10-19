import Foundation
import RxSwift
import RxCocoa


final class CompleteQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let result: QuizResult
    
    // MARK: - ActionType 재정의
    enum ActionType {
        case nextQuiz
        case retryIncorrect(words: [Vocab])
        case finish
        case dismiss
    }
    
    init(result: QuizResult) {
        self.result = result
    }
    
    struct Input {
        let primaryButtonTap: Observable<Void>
        let secondaryButtonTap: Observable<Void>
        let endLearningButtonTap: Observable<Void>///////
    }
    /////
    struct Output {
        let scoreText: Driver<String>
        let summaryText: Driver<String>
        let correctCountText: Driver<String>
        let incorrectCountText: Driver<String>
        let experienceText: Driver<String>
        let primaryButtonTitle: Driver<String>
        let secondaryButtonTitle: Driver<String>
        let primaryAction: Signal<ActionType>
        let secondaryAction: Signal<ActionType>
        let endLearningAction: Signal<ActionType>
        let isEndLearningButtonHidden: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        
        let primaryActionRelay = PublishRelay<ActionType>()
        let secondaryActionRelay = PublishRelay<ActionType>()
        let endLearningActionRelay = PublishRelay<ActionType>()
        
        let incorrectCount = result.total - result.correct
        let experience = result.experience
        let scoreText = Driver.just("\(result.correct) / \(result.total)")
        // 만점 보너스는 따로 줄을 만들지 않고 요약 문구로 알린다
        let summaryText = Driver.just(
            experience.perfectBonus > 0
            ? "\(result.total)개 전부 정답! 보너스 +\(experience.perfectBonus)"
            : "\(result.total)개를 학습했어요"
        )
        let correctCountText = Driver.just("\(result.correct)개")
        let incorrectCountText = Driver.just("\(incorrectCount)개")
        let experienceText = Driver.just("+\(experience.total) EXP")
        
        let secondaryButton = determineSecondaryButton()

        let isEndLearningButtonHidden = Driver.just(
            result.incorrectWords.isEmpty
          )
        
        input.primaryButtonTap
            .map { ActionType.nextQuiz }
            .bind(to: primaryActionRelay)
            .disposed(by: disposeBag)

        input.secondaryButtonTap
            .map { secondaryButton.action }
            .bind(to: secondaryActionRelay)
            .disposed(by: disposeBag)
        
        input.endLearningButtonTap
            .map { ActionType.finish }
            .bind(to: endLearningActionRelay)
            .disposed(by: disposeBag)
        
        return Output(
            scoreText: scoreText,
            summaryText: summaryText,
            correctCountText: correctCountText,
            incorrectCountText: incorrectCountText,
            experienceText: experienceText,
            primaryButtonTitle: Driver.just("계속 학습하기"),
            secondaryButtonTitle: Driver.just(secondaryButton.title),
            primaryAction: primaryActionRelay.asSignal(),
            secondaryAction: secondaryActionRelay.asSignal(),
            endLearningAction: endLearningActionRelay.asSignal(),
            isEndLearningButtonHidden: isEndLearningButtonHidden
        )
    }
    
    // 주 버튼은 항상 계속 학습하기, 보조 버튼만 오답 유무에 따라 변경
    private func determineSecondaryButton() -> (title: String, action: ActionType) {
        if result.incorrectWords.isEmpty {
            return (title: "학습 끝내기", action: .finish)
        } else {
            return (title: "틀린 문제 다시 풀기", action: .retryIncorrect(words: result.incorrectWords))
        }
    }
}
