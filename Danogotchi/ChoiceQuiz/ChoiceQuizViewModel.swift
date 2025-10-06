import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class ChoiceQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let learningHistory: LearningHistoryRepositoryProtocol
    private let quizWords: [WordModel]
    private let allWords: [WordModel]
    
    
    private let currentIndex = BehaviorRelay<Int>(value: 0)
    private let nextQuestionTrigger = PublishRelay<Void>()
    
    struct AnswerResult {
        let isCorrect: Bool
        let selectedIndex: Int
        let correctIndex: Int
    }
    
    struct QuizResult {
        let correct: Int
        let total: Int
    }
    
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
        let choiceSelected: Observable<Int>
    }
    
    struct Output {
        let currentQuestion: Driver<Int>
        let totalQuestion: Driver<Int>
        let progress: Driver<Float>
        let wordImage: Driver<String>
        let questionWord: Driver<String>
        let choices: Driver<[String]>
        let answerResult: Signal<AnswerResult>
        let quizCompleted: Signal<QuizResult>
    }
    
    func transform(input: Input) -> Output {
        let answerResultRelay = PublishRelay<AnswerResult>()
        let quizCompletedRelay = PublishRelay<QuizResult>()
        
        // 정답 단어 데이터, 오답 데이터, 정답 뜻 인덱스
        let currentQuizData = currentIndex
            .map {[weak self] index -> (WordModel, [String], Int)? in
                guard let self = self,
                      index < quizWords.count else { return nil }
                let word = self.quizWords[index] // 현제 문제 단어
                let (choices, correctIndex) = generateChoices(for: word)
                return (word, choices, correctIndex)
            }.share(replay: 1, scope: .whileConnected)
        
        // 현제 문제 카운트
        let currentQuestionCount = currentIndex
            .map { $0 + 1 }
            .asDriver(onErrorJustReturn: 1)
        
        let totalQuestionCount = Driver.just(quizWords.count)
        
        let progress = currentIndex
            .map { Float($0) / Float(max(1, self.quizWords.count)) }
            .asDriver(onErrorJustReturn: 0)
        
        // 이미지
        let wordImage = currentQuizData
            .compactMap { $0?.0.thumbnail }
            .asDriver(onErrorJustReturn: "")
        
        // 단어
        let questionWord = currentQuizData
            .compactMap { $0?.0.word }
            .asDriver(onErrorJustReturn: "")
        
        // 보기
        let choices = currentQuizData
            .compactMap { $0?.1 }
            .asDriver(onErrorJustReturn: [])
        
        var correctCount = 0
        
        input.choiceSelected
            .withLatestFrom(currentQuizData) { ($0, $1) }
            .compactMap { [weak self] selectedIndex, quizData -> AnswerResult? in
                guard let self = self,
                      let (word, _, correctIndex) = quizData else { return nil }
                
                let isCorrect = selectedIndex == correctIndex
                
                // LearningHistory 저장
                if let wordObjectId = try? ObjectId(string: word.id) {
                    learningHistory.addHistory(wordObjectId: wordObjectId, isCorrect: isCorrect)
                }
                
                if isCorrect {
                    correctCount += 1
                }
                
                return AnswerResult(
                    isCorrect: isCorrect,
                    selectedIndex: selectedIndex,
                    correctIndex: correctIndex
                )
            }.bind(to: answerResultRelay)
            .disposed(by: disposeBag)
        
        nextQuestionTrigger
            .withLatestFrom(currentIndex.asObservable())
            .bind(with: self) { owner, index in
                let nextIndex = index + 1
                
                if nextIndex >= self.quizWords.count {
                    quizCompletedRelay.accept(
                        QuizResult(correct: correctCount, total: self.quizWords.count)
                    )
                } else {
                    self.currentIndex.accept(nextIndex)
                }
            }
            .disposed(by: disposeBag)
        
        return Output(
            currentQuestion: currentQuestionCount,
            totalQuestion: totalQuestionCount,
            progress: progress,
            wordImage: wordImage,
            questionWord: questionWord,
            choices: choices,
            answerResult: answerResultRelay.asSignal(),
            quizCompleted: quizCompletedRelay.asSignal()
        )
    }
    
    func moveToNextQuestion() {
        nextQuestionTrigger.accept(())
    }
    
    private func generateChoices(for word: WordModel) -> ([String], Int) {
        // 오답 3개 만들기
        var wrongChoices = allWords
            .filter { $0.id != word.id } // 정답 제외
            .shuffled()
            .prefix(3)
            .map { $0.meaning }
        
        // 정답 단어 넣기
        wrongChoices.append(word.meaning)
        
        // 셔플
        let shuffledChoices = wrongChoices.shuffled()
        let correctIndex = shuffledChoices.firstIndex(of: word.meaning) ?? 0
        
        return (shuffledChoices, correctIndex)
    }
}
