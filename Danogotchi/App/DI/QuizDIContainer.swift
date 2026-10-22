import Foundation

/// quizData는 재시작마다 바뀌므로 컨테이너 스코프가 아니라 팩토리 인자로 받는다
final class QuizDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func makeQuizViewModel(quizData: QuizData) -> QuizViewModel {
        return QuizViewModel(
            earnExperienceUseCase: DefaultEarnExperienceUseCase(
                learningHistoryRepository: dependencies.makeLearningHistoryRepository(),
                petRepository: dependencies.petRepository
            ),
            studyReminderUseCase: dependencies.makeStudyReminderUseCase(),
            quizData: quizData
        )
    }

    func makeCompleteQuizViewModel(result: QuizResult) -> CompleteQuizViewModel {
        return CompleteQuizViewModel(result: result)
    }

    func makeStartQuizUseCase() -> StartQuizUseCase {
        return dependencies.makeStartQuizUseCase()
    }
}
