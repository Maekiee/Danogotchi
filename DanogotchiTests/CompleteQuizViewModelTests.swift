import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class CompleteQuizViewModelTests: XCTestCase {
    func test_perfectResultShowsBonusSummaryAndOffersOnlyFinish() {
        let gain = ExperienceGain(earned: 80, perfectBonus: 20)
        let screen = CompleteQuizTestScreen(correct: 4, total: 4, incorrect: [], experience: gain)

        XCTAssertEqual(screen.score, "4 / 4")
        XCTAssertEqual(screen.summary, String(localized: "\(4)개 전부 정답! 보너스 +\(20)"))
        XCTAssertEqual(screen.correctCount, String(localized: "\(4)개"))
        XCTAssertEqual(screen.incorrectCount, String(localized: "\(0)개"))
        XCTAssertEqual(screen.experience, "+\(gain.total) EXP")
        XCTAssertEqual(screen.primaryTitle, String(localized: "계속 학습하기"))
        XCTAssertEqual(screen.secondaryTitle, String(localized: "학습 끝내기"))
        XCTAssertEqual(screen.isEndLearningHidden, true)

        screen.secondaryTap.accept(())
        guard case .finish? = screen.secondaryActions.last else {
            return XCTFail("오답이 없으면 보조 버튼은 학습 끝내기다: \(String(describing: screen.secondaryActions.last))")
        }
    }

    func test_imperfectResultOffersRetryOfIncorrectWordsAndShowsEndLearning() {
        let words = makeQuizWords(4)
        let incorrect = [words[1], words[3]]
        let screen = CompleteQuizTestScreen(correct: 2, total: 4, incorrect: incorrect,
                                            experience: ExperienceGain(earned: 40, perfectBonus: 0))

        XCTAssertEqual(screen.summary, String(localized: "\(4)개를 학습했어요"))
        XCTAssertEqual(screen.correctCount, String(localized: "\(2)개"))
        XCTAssertEqual(screen.incorrectCount, String(localized: "\(2)개"))
        XCTAssertEqual(screen.secondaryTitle, String(localized: "틀린 문제 다시 풀기"))
        XCTAssertEqual(screen.isEndLearningHidden, false)

        screen.secondaryTap.accept(())
        guard case .retryIncorrect(let retried)? = screen.secondaryActions.last else {
            return XCTFail("오답이 있으면 보조 버튼은 재풀이다: \(String(describing: screen.secondaryActions.last))")
        }
        XCTAssertEqual(retried, incorrect)
    }

    func test_primaryAndEndLearningButtonsMapToFixedActions() {
        let screen = CompleteQuizTestScreen(correct: 1, total: 4, incorrect: makeQuizWords(3),
                                            experience: ExperienceGain(earned: 20, perfectBonus: 0))

        screen.primaryTap.accept(())
        screen.primaryTap.accept(())
        screen.endLearningTap.accept(())

        XCTAssertEqual(screen.primaryActions.count, 2)
        for action in screen.primaryActions {
            guard case .nextQuiz = action else { return XCTFail("주 버튼은 항상 다음 퀴즈다: \(action)") }
        }
        guard case .finish? = screen.endLearningActions.last else {
            return XCTFail("학습 끝내기는 finish다: \(String(describing: screen.endLearningActions.last))")
        }
    }
}

@MainActor
private final class CompleteQuizTestScreen {
    let primaryTap = PublishRelay<Void>()
    let secondaryTap = PublishRelay<Void>()
    let endLearningTap = PublishRelay<Void>()
    private(set) var score = ""
    private(set) var summary = ""
    private(set) var correctCount = ""
    private(set) var incorrectCount = ""
    private(set) var experience = ""
    private(set) var primaryTitle = ""
    private(set) var secondaryTitle = ""
    private(set) var isEndLearningHidden: Bool?
    private(set) var primaryActions: [CompleteQuizViewModel.ActionType] = []
    private(set) var secondaryActions: [CompleteQuizViewModel.ActionType] = []
    private(set) var endLearningActions: [CompleteQuizViewModel.ActionType] = []
    private let viewModel: CompleteQuizViewModel
    private let bag = DisposeBag()

    init(correct: Int, total: Int, incorrect: [Vocab], experience: ExperienceGain) {
        viewModel = CompleteQuizViewModel(result: QuizResult(
            correct: correct, total: total, incorrectWords: incorrect, experience: experience
        ))
        let output = viewModel.transform(input: .init(
            primaryButtonTap: primaryTap.asObservable(),
            secondaryButtonTap: secondaryTap.asObservable(),
            endLearningButtonTap: endLearningTap.asObservable()
        ))
        output.scoreText.drive(onNext: { [weak self] in self?.score = $0 }).disposed(by: bag)
        output.summaryText.drive(onNext: { [weak self] in self?.summary = $0 }).disposed(by: bag)
        output.correctCountText.drive(onNext: { [weak self] in self?.correctCount = $0 }).disposed(by: bag)
        output.incorrectCountText.drive(onNext: { [weak self] in self?.incorrectCount = $0 }).disposed(by: bag)
        output.experienceText.drive(onNext: { [weak self] in self?.experience = $0 }).disposed(by: bag)
        output.primaryButtonTitle.drive(onNext: { [weak self] in self?.primaryTitle = $0 }).disposed(by: bag)
        output.secondaryButtonTitle.drive(onNext: { [weak self] in self?.secondaryTitle = $0 }).disposed(by: bag)
        output.isEndLearningButtonHidden.drive(onNext: { [weak self] in self?.isEndLearningHidden = $0 }).disposed(by: bag)
        output.primaryAction.emit(onNext: { [weak self] in self?.primaryActions.append($0) }).disposed(by: bag)
        output.secondaryAction.emit(onNext: { [weak self] in self?.secondaryActions.append($0) }).disposed(by: bag)
        output.endLearningAction.emit(onNext: { [weak self] in self?.endLearningActions.append($0) }).disposed(by: bag)
    }
}
