import Foundation
import RxSwift
import RxCocoa

final class QuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let learningHistoryRepository: VocabLearningHistoryRepository
    private let userInfo = UserInfoManager.shared
    
    private let quizDataRelay: BehaviorRelay<QuizData>
    
    private let currentIndex: BehaviorRelay<Int>
    private let nextQuestionTrigger = PublishRelay<Void>()
    private var incorrectWords: [Vocab] = []
    
    
    struct AnswerResult {
        let isCorrect: Bool
        let selectedIndex: Int
        let correctIndex: Int
    }
    
    init(
        learningHistoryRepository: VocabLearningHistoryRepository,
        quizData: QuizData
    ) {
        self.learningHistoryRepository = learningHistoryRepository
        self.quizDataRelay = BehaviorRelay(value: quizData)
        self.currentIndex = BehaviorRelay(value: userInfo.currentQuizIndex)
        
        if let incorrectWordIds = userInfo.currentIncorrectWordIds {
            self.incorrectWords = quizData.allWord.filter { incorrectWordIds.contains($0.id.uuidString) }
        }
    }

    struct Input {
        let choiceSelected: Observable<Int>
    }
    
    struct Output {
        let currentQuestion: Driver<Int>
        let totalQuestion: Driver<Int>
        let progress: Driver<Float>
        let questionWord: Driver<String>
        let choices: Driver<[String]>
        let answerResult: Signal<AnswerResult>
        let quizCompleted: Signal<(originalData: QuizData, result: QuizResult)>
    }
    
    func transform(input: Input) -> Output {
        let answerResultRelay = PublishRelay<AnswerResult>()
        let quizCompletedRelay = PublishRelay<(originalData: QuizData, result: QuizResult)>()
        var correctCount = userInfo.currentCorrectCount

        // 정답 단어 데이터, 오답 데이터, 정답 뜻 인덱스
        let currentQuizData = Observable.combineLatest(
            currentIndex,
            quizDataRelay
        ).map { [weak self] index, quizData -> (Vocab, [String], Int)? in
            guard let self else { return nil }
            guard index < quizData.words.count else { return nil }

            let word = quizData.words[index]
            let (choices, correctIndex) = self.generateChoices(
                for: word, allWords: quizData.allWord)
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
                Float(index + 1) / Float(max(1, quizData.words.count))
            }
            .asDriver(onErrorJustReturn: 0)
        
        // 단어
        let questionWord = currentQuizData
            .compactMap { $0?.0.word }
            .asDriver(onErrorJustReturn: "")
        
        // 보기
        let choices = currentQuizData
            .compactMap { $0?.1 }
            .asDriver(onErrorJustReturn: [])
        
//        var correctCount = 0
        
        input.choiceSelected
            .withLatestFrom(currentQuizData) { ($0, $1) }
            .compactMap { [weak self] selectedIndex, quizData -> AnswerResult? in
                guard let self = self,
                      let (word, _, correctIndex) = quizData else { return nil }
                
                let isCorrect = selectedIndex == correctIndex
                
                // LearningHistory 저장
                learningHistoryRepository.addHistory(vocabId: word.id, isCorrect: isCorrect)
                
                if isCorrect {
                    correctCount += 1
                } else {
                    incorrectWords.append(word)
                }
                
                userInfo.currentCorrectCount = correctCount
                userInfo.currentIncorrectWordIds = incorrectWords.map { $0.id.uuidString }
                
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
                
                owner.userInfo.currentQuizIndex = nextIndex
                
                if nextIndex >= quizData.words.count {
                    owner.userInfo.clearQuizState()
                    let result = QuizResult(
                        correct: correctCount,
                        total: quizData.words.count,
                        incorrectWords: owner.incorrectWords
                    )
                    quizCompletedRelay.accept((originalData: quizData, result: result))
                } else {
                    owner.currentIndex.accept(nextIndex)
                }
            }
            .disposed(by: disposeBag)
        
        return Output(
            currentQuestion: currentQuestionCount,
            totalQuestion: totalQuestionCount,
            progress: progress,
            questionWord: questionWord,
            choices: choices,
            answerResult: answerResultRelay.asSignal(),
            quizCompleted: quizCompletedRelay.asSignal()
        )
    }
    
    func moveToNextQuestion() {
        nextQuestionTrigger.accept(())
    }
    
    private func generateChoices(for word: Vocab, allWords: [Vocab]) -> ([String], Int) {
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
