import Foundation
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let result: QuizResult
    private let allIncorrectWords: [WordModel]
    
    enum ActionType {
        case continueNextSection(startIndex: Int)
        case showRetryActionSheet
        case retryCurrentSection
        case retryWrongWords(words: [WordModel])
        case restartFromBeginning
    }
    
    init(result: QuizResult, allIncorrectWords: [WordModel] = []) {
        self.result = result
        self.allIncorrectWords = allIncorrectWords.isEmpty ? result.incorrectWords : allIncorrectWords
    }
    
    struct Input {
        let primaryButtonTap: Observable<Void>
        let secondaryButtonTap: Observable<Void>
    }
    
    struct Output {
        let scoreText: Driver<String>
        let primaryButtonTitle: Driver<String>
        let secondaryButtonTitle: Driver<String>
        let primaryAction: Signal<ActionType>
        let secondaryAction: Signal<ActionType>
    }

    func transform(input: Input) -> Output {
        
        let primaryActionRelay = PublishRelay<ActionType>()
        let secondaryActionRelay = PublishRelay<ActionType>()
        
        let scoreText = Driver.just("\(result.total)개 중 \(result.correct)개 정답")
        
        let (primaryTitle, secondaryTitle, primaryAction, secondaryAction) = determineButtons()
        
        input.primaryButtonTap
            .map { primaryAction }
            .bind(to: primaryActionRelay)
            .disposed(by: disposeBag)
        
        input.secondaryButtonTap
            .map { secondaryAction }
            .bind(to: secondaryActionRelay)
            .disposed(by: disposeBag)
        
        return Output(
            scoreText: scoreText,
            primaryButtonTitle: Driver.just(primaryTitle),
            secondaryButtonTitle: Driver.just(secondaryTitle),
            primaryAction: primaryActionRelay.asSignal(),
            secondaryAction: secondaryActionRelay.asSignal()
        )
    }
    
    private func determineButtons() -> (String, String, ActionType, ActionType) {
        switch result.mode {
        case .section:
            if result.hasNextSection {
                // 구간 학습 중간
                return (
                    "이어학습하기",
                    "다시 학습하기",
                    .continueNextSection(startIndex: result.nextStartIndex),
                    .showRetryActionSheet
                )
            } else {
                // 구간 학습 완료
                return (
                    "틀린 단어 학습하기",
                    "처음부터 다시 학습하기",
                    .retryWrongWords(words: allIncorrectWords),
                    .restartFromBeginning
                )
            }
        case .full:
            // 전체 학습
            return (
                "처음부터 다시 학습하기",
                "틀린 단어만 학습하기",
                .restartFromBeginning,
                .retryWrongWords(words: result.incorrectWords)
            )
        }
    }
}
