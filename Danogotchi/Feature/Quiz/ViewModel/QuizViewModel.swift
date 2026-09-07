import Foundation
import OSLog
import RxSwift
import RxCocoa

final class QuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let earnExperienceUseCase: EarnExperienceUseCase
    private let studyReminderUseCase: StudyReminderUseCase

    private let quizDataRelay: BehaviorRelay<QuizData>
    
    private let currentIndex: BehaviorRelay<Int>
    private let nextQuestionTrigger = PublishRelay<Void>()
    private let endSessionTrigger = PublishRelay<Void>()

    /// 재시도로 넘길 수 있는 실패인지 구분한다 — 대상이 사라진 경우는 몇 번을 눌러도 같은 결과다.
    enum SaveFailure {
        case retryable
        case unrecoverable
    }

    private enum Phase {
        case acceptingAnswer
        case answerFailed(Vocab, AnswerResult)
        case answered
        case commitFailed
        case completed
        case ended
    }
    
    
    struct AnswerResult {
        let isCorrect: Bool
        let selectedIndex: Int
        let correctIndex: Int
    }
    
    init(
        earnExperienceUseCase: EarnExperienceUseCase,
        studyReminderUseCase: StudyReminderUseCase,
        quizData: QuizData
    ) {
        self.earnExperienceUseCase = earnExperienceUseCase
        self.studyReminderUseCase = studyReminderUseCase
        self.quizDataRelay = BehaviorRelay(value: quizData)
        self.currentIndex = BehaviorRelay(value: 0)
    }

    struct Input {
        let choiceSelected: Observable<Int>
        let retrySave: Observable<Void>
    }
    
    struct Output {
        let currentQuestion: Driver<Int>
        let totalQuestion: Driver<Int>
        let progress: Driver<Float>
        let questionWord: Driver<String>
        let choices: Driver<[String]>
        let answerResult: Signal<AnswerResult>
        let saveFailed: Signal<SaveFailure>
        let canAnswer: Driver<Bool>
        let quizCompleted: Signal<(originalData: QuizData, result: QuizResult)>
    }
    
    func transform(input: Input) -> Output {
        let answerResultRelay = PublishRelay<AnswerResult>()
        let quizCompletedRelay = PublishRelay<(originalData: QuizData, result: QuizResult)>()
        var correctCount = 0
        var earnedExperience = 0
        var incorrectWords: [Vocab] = []
        var phase = Phase.acceptingAnswer
        let saveFailed = PublishRelay<SaveFailure>()
        // PersistenceError는 조회 대상 자체가 없다는 뜻이라 재시도가 성립하지 않는다.
        func failure(for error: Error) -> SaveFailure { error is PersistenceError ? .unrecoverable : .retryable }
        let canAnswer = BehaviorRelay(value: true)

        func saveAnswer(owner: QuizViewModel, word: Vocab, result: AnswerResult) {
            phase = .answerFailed(word, result)
            canAnswer.accept(false)
            do {
                let earned = try owner.earnExperienceUseCase.record(vocabId: word.id, isCorrect: result.isCorrect)
                earnedExperience += earned
                if result.isCorrect {
                    correctCount += 1
                } else {
                    incorrectWords.append(word)
                }
                phase = .answered
                answerResultRelay.accept(result)
            } catch {
                saveFailed.accept(failure(for: error))
            }
        }

        func commit(owner: QuizViewModel) {
            phase = .commitFailed
            do {
                let experience = try owner.earnExperienceUseCase.commit(
                    earned: earnedExperience,
                    correct: correctCount,
                    total: owner.quizDataRelay.value.words.count
                )
                phase = .completed
                // 알림 재예약 실패는 이미 적립된 경험치를 재시도하게 만들지 않는다.
                do {
                    try owner.studyReminderUseCase.refresh()
                } catch {
                    AppLogger.database.error("학습 알림 갱신 실패: \(String(describing: error), privacy: .public)")
                }
                let result = QuizResult(
                    correct: correctCount,
                    total: owner.quizDataRelay.value.words.count,
                    incorrectWords: incorrectWords,
                    experience: experience
                )
                quizCompletedRelay.accept((originalData: owner.quizDataRelay.value, result: result))
            } catch {
                saveFailed.accept(failure(for: error))
            }
        }

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
        
        input.choiceSelected
            .withLatestFrom(currentQuizData) { ($0, $1) }
            .bind(with: self) { owner, selection in
                guard case .acceptingAnswer = phase,
                      let (word, choices, correctIndex) = selection.1,
                      choices.indices.contains(selection.0) else { return }
                saveAnswer(owner: owner, word: word, result: AnswerResult(
                    isCorrect: selection.0 == correctIndex,
                    selectedIndex: selection.0,
                    correctIndex: correctIndex
                ))
            }.disposed(by: disposeBag)

        nextQuestionTrigger
            .bind(with: self) { owner, _ in
                guard case .answered = phase else { return }
                let nextIndex = owner.currentIndex.value + 1
                if nextIndex >= owner.quizDataRelay.value.words.count {
                    commit(owner: owner)
                } else {
                    phase = .acceptingAnswer
                    owner.currentIndex.accept(nextIndex)
                    canAnswer.accept(true)
                }
            }.disposed(by: disposeBag)

        input.retrySave
            .bind(with: self) { owner, _ in
                switch phase {
                case .answerFailed(let word, let result):
                    saveAnswer(owner: owner, word: word, result: result)
                case .commitFailed:
                    commit(owner: owner)
                default:
                    break
                }
            }.disposed(by: disposeBag)

        endSessionTrigger
            .bind(onNext: {
                phase = .ended
                canAnswer.accept(false)
            }).disposed(by: disposeBag)

        return Output(
            currentQuestion: currentQuestionCount,
            totalQuestion: totalQuestionCount,
            progress: progress,
            questionWord: questionWord,
            choices: choices,
            answerResult: answerResultRelay.asSignal(),
            saveFailed: saveFailed.asSignal(),
            canAnswer: canAnswer.asDriver(),
            quizCompleted: quizCompletedRelay.asSignal()
        )
    }
    
    func moveToNextQuestion() {
        nextQuestionTrigger.accept(())
    }
    
    func endSession() {
        endSessionTrigger.accept(())
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
