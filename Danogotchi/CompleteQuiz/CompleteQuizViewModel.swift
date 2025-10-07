import Foundation
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let result: QuizResult
    private let allIncorrectWords: [WordModel]
    
    // MARK: - ActionType 재정의
    enum ActionType {
        case continueNextSection(startIndex: Int) // 이어 학습하기
        case showRetryActionSheet // 다시 학습하기 (액션시트)
        case retryCurrentSection // 현재 구간 전체 재학습
        case retryWrongWords(words: [WordModel]) // 틀린 단어만 학습
        case restartFromBeginning // 처음부터 다시 학습
        case dismiss // 화면 닫기
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
    
    // MARK: - 기획서에 따른 버튼 로직 수정
    private func determineButtons() -> (String, String, ActionType, ActionType) {
        switch result.mode {
        case .section:
            if result.hasNextSection {
                // [구간 학습] 중간 단계
                return (
                    "이어 학습하기", // 다음 구간
                    "다시 학습하기", // 현재 구간 액션시트
                    .continueNextSection(startIndex: result.nextStartIndex),
                    .showRetryActionSheet
                )
            } else {
                // [구간 학습] 모든 구간 완료
                return (
                    "틀린 단어 학습하기", // 전체에서 틀린 단어
                    "처음부터 다시 학습하기", // 구간 설정 그대로 처음부터
                    .retryWrongWords(words: allIncorrectWords),
                    .restartFromBeginning
                )
            }
        case .full:
            // [전체 학습] 완료
            return (
                "처음부터 다시 학습하기",
                "틀린 단어만 학습하기",
                .restartFromBeginning,
                .retryWrongWords(words: result.incorrectWords)
            )
        }
    }
}
