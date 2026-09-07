import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

func makeQuizWords(_ count: Int) -> [Vocab] {
    (0..<count).map {
        Vocab(id: UUID(), word: "word\($0)", meaning: "meaning\($0)", bookType: .myBook,
              level: nil, partOfSpeech: .noun, sourceWordId: nil, createAt: testBase.addingTimeInterval(Double($0)))
    }
}

final class RecordingExperienceUseCase: EarnExperienceUseCase {
    var failsRecord = false
    var failsCommit = false
    /// 켜면 저장 실패 대신 복구 불가능한 대상 부재를 던진다.
    var failsAsMissingEntity = false
    private var failure: Error { failsAsMissingEntity ? PersistenceError.entityNotFound : CocoaError(.fileWriteOutOfSpace) }
    var records: [(UUID, Bool)] = []
    var commits: [(Int, Int, Int)] = []

    func record(vocabId: UUID, isCorrect: Bool) throws -> Int {
        records.append((vocabId, isCorrect))
        if failsRecord { throw failure }
        return isCorrect ? 20 : 0
    }

    func commit(earned: Int, correct: Int, total: Int) throws -> ExperienceGain {
        commits.append((earned, correct, total))
        if failsCommit { throw failure }
        return ExperienceGain(earned: earned, perfectBonus: ExperiencePolicy.perfectBonus(correct: correct, total: total))
    }
}

final class RecordingReminderUseCase: StudyReminderUseCase {
    var isEnabled = true
    var refreshCount = 0
    var failsRefresh = false
    func setEnabled(_ enabled: Bool) throws { isEnabled = enabled }
    func refresh() throws {
        refreshCount += 1
        if failsRefresh { throw CocoaError(.fileReadUnknown) }
    }
}

@MainActor
private final class QuizTestScreen {
    let experience = RecordingExperienceUseCase()
    let reminder = RecordingReminderUseCase()
    let selected = PublishRelay<Int>()
    let retry = PublishRelay<Void>()
    let viewModel: QuizViewModel
    private let bag = DisposeBag()
    var choices: [String] = []
    var question = ""
    var answers: [QuizViewModel.AnswerResult] = []
    var completions: [QuizResult] = []
    var failures = 0
    var lastFailure: QuizViewModel.SaveFailure?
    var canAnswer = false

    init(questionCount: Int = 1) {
        let words = makeQuizWords(4)
        viewModel = QuizViewModel(earnExperienceUseCase: experience, studyReminderUseCase: reminder,
                                  quizData: QuizData(words: Array(words.prefix(questionCount)), allWord: words))
        let output = viewModel.transform(input: .init(choiceSelected: selected.asObservable(), retrySave: retry.asObservable()))
        output.choices.drive(onNext: { [weak self] in self?.choices = $0 }).disposed(by: bag)
        output.questionWord.drive(onNext: { [weak self] in self?.question = $0 }).disposed(by: bag)
        output.answerResult.emit(onNext: { [weak self] in self?.answers.append($0) }).disposed(by: bag)
        output.quizCompleted.emit(onNext: { [weak self] in self?.completions.append($0.result) }).disposed(by: bag)
        output.saveFailed.emit(onNext: { [weak self] in
            self?.failures += 1
            self?.lastFailure = $0
        }).disposed(by: bag)
        output.canAnswer.drive(onNext: { [weak self] in self?.canAnswer = $0 }).disposed(by: bag)
    }

    func answer(correct: Bool = true) throws {
        let meaning = question.replacingOccurrences(of: "word", with: "meaning")
        let index = try XCTUnwrap(choices.firstIndex(where: { correct ? $0 == meaning : $0 != meaning }))
        selected.accept(index)
    }
}

@MainActor
final class QuizViewModelTests: XCTestCase {
    func test_answerFailureRetainsSelectionAndRetryRecordsOnce() throws {
        let screen = QuizTestScreen()
        screen.experience.failsRecord = true
        try screen.answer()
        screen.viewModel.moveToNextQuestion()
        XCTAssertEqual(screen.failures, 1)
        XCTAssertTrue(screen.answers.isEmpty)
        XCTAssertFalse(screen.canAnswer)
        XCTAssertTrue(screen.experience.commits.isEmpty)
        let firstAttempt = try XCTUnwrap(screen.experience.records.first)
        try screen.answer(correct: false) // 저장 실패 중 다른 답을 받지 않는다.
        XCTAssertEqual(screen.experience.records.count, 1)

        screen.experience.failsRecord = false
        screen.retry.accept(())
        screen.retry.accept(())
        XCTAssertEqual(screen.experience.records.count, 2)
        XCTAssertEqual(screen.experience.records.last?.0, firstAttempt.0)
        XCTAssertEqual(screen.experience.records.last?.1, firstAttempt.1)
        XCTAssertEqual(screen.answers.count, 1)
        screen.viewModel.moveToNextQuestion()
        XCTAssertEqual(screen.completions.first?.correct, 1)
        XCTAssertEqual(screen.completions.first?.experience.earned, 20)
    }

    func test_commitRetryDoesNotRecordAnswersOrCompleteTwice() throws {
        let screen = QuizTestScreen()
        try screen.answer()
        screen.experience.failsCommit = true
        screen.viewModel.moveToNextQuestion()
        screen.viewModel.moveToNextQuestion()
        XCTAssertEqual(screen.failures, 1)
        XCTAssertTrue(screen.completions.isEmpty)
        XCTAssertEqual(screen.experience.commits.count, 1)
        XCTAssertEqual(screen.reminder.refreshCount, 0)

        screen.experience.failsCommit = false
        screen.retry.accept(())
        screen.retry.accept(())
        screen.viewModel.moveToNextQuestion()
        XCTAssertEqual(screen.experience.records.count, 1)
        XCTAssertEqual(screen.experience.commits.count, 2)
        XCTAssertEqual(screen.experience.commits.last?.0, 20)
        XCTAssertEqual(screen.completions.count, 1)
        XCTAssertEqual(screen.reminder.refreshCount, 1)
    }

    func test_missingWordReportsUnrecoverableSoRetryIsNotOffered() throws {
        let screen = QuizTestScreen()
        screen.experience.failsRecord = true
        screen.experience.failsAsMissingEntity = true
        try screen.answer()
        XCTAssertEqual(screen.failures, 1)
        XCTAssertEqual(screen.lastFailure, .unrecoverable)

        // 같은 조회를 반복할 뿐이므로 재시도해도 복구 불가 신호가 이어진다.
        screen.retry.accept(())
        XCTAssertEqual(screen.failures, 2)
        XCTAssertEqual(screen.lastFailure, .unrecoverable)
        XCTAssertTrue(screen.answers.isEmpty)
        XCTAssertFalse(screen.canAnswer)
    }

    func test_endingFailedSessionIgnoresPendingRetryAndNextQuestion() throws {
        let screen = QuizTestScreen()
        screen.experience.failsRecord = true
        try screen.answer()
        screen.viewModel.endSession()
        screen.experience.failsRecord = false
        screen.retry.accept(())
        screen.viewModel.moveToNextQuestion()
        try screen.answer()
        XCTAssertEqual(screen.experience.records.count, 1)
        XCTAssertTrue(screen.experience.commits.isEmpty)
        XCTAssertTrue(screen.completions.isEmpty)
    }

    func test_distinctChoicesGradeAnswersAndAccumulateSessionResult() throws {
        let screen = QuizTestScreen(questionCount: 2)
        XCTAssertEqual(Set(screen.choices).count, 4)
        try screen.answer()
        XCTAssertEqual(screen.answers.first?.isCorrect, true)
        screen.viewModel.moveToNextQuestion()
        XCTAssertTrue(screen.canAnswer)
        try screen.answer(correct: false)
        XCTAssertEqual(screen.answers.last?.isCorrect, false)
        screen.viewModel.moveToNextQuestion()
        let result = try XCTUnwrap(screen.completions.first)
        XCTAssertEqual(result.correct, 1)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.incorrectWords.map(\.word), ["word1"])
        XCTAssertEqual(result.experience.earned, 20)
        XCTAssertEqual(result.experience.perfectBonus, 0)
    }

    func test_reminderFailureDoesNotRetryAlreadySavedExperience() throws {
        let screen = QuizTestScreen()
        screen.reminder.failsRefresh = true
        try screen.answer()
        screen.viewModel.moveToNextQuestion()
        screen.retry.accept(())
        XCTAssertEqual(screen.experience.commits.count, 1)
        XCTAssertEqual(screen.completions.count, 1)
        XCTAssertEqual(screen.failures, 0)
    }
}
