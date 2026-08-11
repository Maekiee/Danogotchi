import Foundation
import RxSwift
import RxCocoa

final class QuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let earnExperienceUseCase: EarnExperienceUseCase

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
        earnExperienceUseCase: EarnExperienceUseCase,
        quizData: QuizData
    ) {
        self.earnExperienceUseCase = earnExperienceUseCase
        self.quizDataRelay = BehaviorRelay(value: quizData)
        self.currentIndex = BehaviorRelay(value: 0)
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
        var correctCount = 0
        var earnedExperience = 0

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

                // 이력 저장과 경험치 산정을 한 번에 (오답은 0)
                earnedExperience += earnExperienceUseCase.record(vocabId: word.id, isCorrect: isCorrect)

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
                    // 세션이 끝나는 시점에만 적립한다 (중도 이탈은 경험치 없음)
                    let experience = owner.earnExperienceUseCase.commit(
                        earned: earnedExperience,
                        correct: correctCount,
                        total: quizData.words.count
                    )
                    let result = QuizResult(
                        correct: correctCount,
                        total: quizData.words.count,
                        incorrectWords: owner.incorrectWords,
                        experience: experience
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
