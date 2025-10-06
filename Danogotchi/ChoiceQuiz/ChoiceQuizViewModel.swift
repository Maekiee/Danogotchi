import Foundation
import RxSwift
import RxCocoa

final class ChoiceQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let learningHistory: LearningHistoryRepositoryProtocol
    private let quizWords: [WordModel]
    private let allWords: [WordModel]
    
    init(
        learningHistoryRepo: LearningHistoryRepositoryProtocol = LearningHistoryRepository(),
        quizWords: [WordModel],
        allWords: [WordModel]
    ) {
        self.learningHistory = learningHistoryRepo
        self.quizWords = quizWords
        self.allWords = allWords
    }
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    func transform(input: Input) -> Output {
        
        
        return Output()
    }
}
