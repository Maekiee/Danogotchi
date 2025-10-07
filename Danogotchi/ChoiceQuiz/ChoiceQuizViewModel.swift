import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class ChoiceQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let learningHistory: LearningHistoryRepositoryProtocol
    
    let quizDataRelay: BehaviorRelay<QuizData>
    
    
    private let currentIndex = BehaviorRelay<Int>(value: 0)
    private let nextQuestionTrigger = PublishRelay<Void>()
    private var incorrectWords: [WordModel] = []
    
    struct AnswerResult {
        let isCorrect: Bool
        let selectedIndex: Int
        let correctIndex: Int
    }
    
    init(
        learningHistoryRepo: LearningHistoryRepositoryProtocol = LearningHistoryRepository(),
        quizData: QuizData
    ) {
        self.learningHistory = learningHistoryRepo
        self.quizDataRelay = BehaviorRelay(value: quizData)
    }
    
    struct Input {
        let choiceSelected: Observable<Int>
        let restartWithNewData: Observable<QuizData>
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
        
        // 새로운 퀴즈 데이터가 들어오면 quizDataRelay를 업데이트하고 상태 초기화
        input.restartWithNewData
            .bind(with: self) { owner, newQuizData in
                owner.incorrectWords = [] // 오답 목록 초기화
                owner.currentIndex.accept(0) // 현재 인덱스 초기화
                owner.quizDataRelay.accept(newQuizData) // 퀴즈 데이터 교체
            }
            .disposed(by: disposeBag)
        
        // 정답 단어 데이터, 오답 데이터, 정답 뜻 인덱스
        let currentQuizData = Observable.combineLatest(
            currentIndex,
            quizDataRelay
        ).map { index, quizData -> (WordModel, [String], Int)? in
            guard index < quizData.words.count else { return nil }
            let word = quizData.words[index]
            let (choices, correctIndex) = self.generateChoices(for: word, allWords: quizData.allWord)
            return (word, choices, correctIndex)
        }.share(replay: 1, scope: .whileConnected)
        
        
        // 현제 문제 카운트
        let currentQuestionCount = currentIndex
            .map { $0 + 1 }
            .asDriver(onErrorJustReturn: 1)
        
        let totalQuestionCount = quizDataRelay.asDriver()
            .map { $0.words.count }
        
        
        let progress = Observable.combineLatest(currentIndex, quizDataRelay)
            .map { index, quizData in
                Float(index) / Float(max(1, quizData.words.count))
            }
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
                } else {
                    incorrectWords.append(word)
                }
                
                return AnswerResult(
                    isCorrect: isCorrect,
                    selectedIndex: selectedIndex,
                    correctIndex: correctIndex
                )
            }.bind(to: answerResultRelay)
            .disposed(by: disposeBag)
        
        nextQuestionTrigger
            .withLatestFrom(Observable.combineLatest(currentIndex, quizDataRelay))
            .bind(with: self) { owner, result in
                let (index, quizData) = result
                let nextIndex = index + 1
                
                if nextIndex >= quizData.words.count {
                    let nextStartIndex: Int
                    let hasNextSection: Bool
                    
                    if quizData.isRestart {
                        nextStartIndex = quizData.startIndex // 재시작인 경우, 원래 시작 인덱스 유지
                    } else {
                        nextStartIndex = quizData.startIndex + quizData.words.count
                    }
                    
                    switch quizData.mode {
                    case .section(_):
                        hasNextSection = nextStartIndex < quizData.allWord.count
                    case .full:
                        hasNextSection = false
                    }
                    
                    quizCompletedRelay.accept(
                        QuizResult(
                            correct: correctCount,
                            total: quizData.words.count,
                            incorrectWords: owner.incorrectWords,
                            mode: quizData.mode,
                            nextStartIndex: nextStartIndex,
                            hasNextSection: hasNextSection
                        )
                    )
                } else {
                    owner.currentIndex.accept(nextIndex)
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
    
    private func generateChoices(for word: WordModel, allWords: [WordModel]) -> ([String], Int) {
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
