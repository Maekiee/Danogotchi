import Foundation
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let result: QuizResult
    
    // MARK: - ActionType 재정의
    enum ActionType {
        case restart
        case retryIncorrect(words: [Word])
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
        let scoreText = Driver.just("""
               \(result.total)개를 학습했어요!
               정답 \(result.correct)개
               오답 \(incorrectCount)개
               """)
        
        let (primaryTitle, secondaryTitle, primaryAction, secondaryAction) = determineButtons()
        
        let isEndLearningButtonHidden = Driver.just(
            result.incorrectWords.isEmpty
          )
        
        input.primaryButtonTap
            .map { primaryAction }
            .bind(to: primaryActionRelay)
            .disposed(by: disposeBag)
        
        input.secondaryButtonTap
            .map { secondaryAction }
            .bind(to: secondaryActionRelay)
            .disposed(by: disposeBag)
        
        input.endLearningButtonTap
            .map { ActionType.finish }
            .bind(to: endLearningActionRelay)
            .disposed(by: disposeBag)
        
        return Output(
            scoreText: scoreText,
            primaryButtonTitle: Driver.just(primaryTitle),
            secondaryButtonTitle: Driver.just(secondaryTitle),
            primaryAction: primaryActionRelay.asSignal(),
            secondaryAction: secondaryActionRelay.asSignal(),
            endLearningAction: endLearningActionRelay.asSignal(),
            isEndLearningButtonHidden: isEndLearningButtonHidden
        )
    }
    
    private func determineButtons() -> (String, String, ActionType, ActionType) {
        if result.incorrectWords.isEmpty {
            return (
                "처음부터 다시 학습하기",
                "학습 끝내기",
                .restart,
                .finish
            )
        } else {
            return (
                "처음부터 다시 학습하기",
                "틀린 문제 학습하기",
                .restart,
                .retryIncorrect(words: result.incorrectWords)
            )
        }
    }
}
