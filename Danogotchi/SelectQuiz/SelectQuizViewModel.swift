import Foundation
import RealmSwift
import RxSwift
import RxCocoa

final class SelectQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let bookRepo: WordBookRepositoryProtocol
    
    init(bookRepo: WordBookRepositoryProtocol = WordBookRepository()) {
        self.bookRepo = bookRepo
    }
    
    struct Input {
        let toggleIsOn: Observable<Bool>
        let decreaseButtonTap: Observable<Void>
        let increaseButtonTap: Observable<Void>
        let startLearningTap: Observable<Void>
    }
    
    struct Output {
        let isSection: Driver<Bool>
        let sectionCount: Driver<Int>
        let startQuiz: Signal<QuizData>
    }
    
    func transform(input: Input) -> Output {
        let isSection = BehaviorRelay<Bool>(value: false)
        let sectionCount = BehaviorRelay<Int>(value: 10)
        let startQuizTrigger = PublishRelay<QuizData>()
        
        // 구간 설정
        input.toggleIsOn
            .bind(to: isSection)
            .disposed(by: disposeBag)
        
        // 구간 단어 증가
        input.decreaseButtonTap
            .withLatestFrom(sectionCount.asObservable())
            .map { max(10, $0 - 10) }
            .bind(to: sectionCount)
            .disposed(by: disposeBag)
        
        // 구간설정 단어 감소
        input.increaseButtonTap
            .withLatestFrom(sectionCount.asObservable())
            .map { min(50, $0 + 10) }
            .bind(to: sectionCount)
            .disposed(by: disposeBag)
        
        // 학습할 데이터 가져오기
        
        
        
        // 학습 시작하기 & 학습할 데이터 가져오기
        input.startLearningTap
            .withLatestFrom(Observable.combineLatest(
                isSection.asObservable(),
                sectionCount.asObservable()
            )).compactMap { [weak self] isEnabled, selectedCount -> QuizData? in
                guard let self = self,
                      let bookId = userInfo.selectedBookId,
                      let objectId = try? ObjectId(string: bookId) else {
                    return nil
                }
                
                let allWord = bookRepo.fetchWordsInWordBook(id: objectId)
                
                guard !allWord.isEmpty else {
                    ToastManager.shared.show("학습할 단어가 없습니다.")
                    return nil
                }
                
                guard allWord.count >= 4 else {
                    ToastManager.shared.show("최소 4개 이상의 단어가 필요합니다.")
                    return nil
                }
                
                let quizWords: [WordModel]
                if isEnabled {
                    let quizCount = min(selectedCount, allWord.count)
                    quizWords = Array(allWord.prefix(quizCount))
                } else {
                    quizWords = allWord
                }
                
                return QuizData(words: quizWords, allWord: allWord)
            }.bind(to: startQuizTrigger)
            .disposed(by: disposeBag)
        
        return Output(
            isSection: isSection.asDriver(),
            sectionCount: sectionCount.asDriver(),
            startQuiz: startQuizTrigger.asSignal()
        )
    }
}

