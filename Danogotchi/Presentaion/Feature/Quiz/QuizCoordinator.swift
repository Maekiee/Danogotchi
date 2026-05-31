import UIKit

protocol QuizCoordinatorDelegate: AnyObject {
    func quizCoordinatorDidFinish()
}

final class QuizCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: QuizCoordinatorDelegate?
    
    private let container: DIContainer
    private let quizData: QuizData
    
    init(
        container: DIContainer,
        navigationController: UINavigationController,
        quizData: QuizData
    ) {
        self.container = container
        self.navigationController = navigationController
        self.quizData = quizData
    }

    func start() {
        let vc = makeQuizViewController(quizData: quizData)
        navigationController.setViewControllers([vc], animated: false)
    }
    
    private func makeQuizViewController(quizData: QuizData) -> QuizViewController {
        let vm = container.makeQuizViewModel(quizData: quizData)
        let vc = QuizViewController(viewModel: vm)
        vc.delegate = self
        return vc
    }
}

extension QuizCoordinator: QuizViewControllerDelegate {
    func quizDidComplete(originalData: QuizData, result: QuizResult) {
        let vm = container.makeCompleteQuizViewModel(result: result)
        let vc = CompleteQuizViewController(
            viewModel: vm,
            originalQuizData: originalData,
            result: result
        )
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        navigationController.present(vc, animated: true)
        
    }
    
    func quizDidTapClose() {
        showInterruptAlert()
    }
}

extension QuizCoordinator: CompleteQuizViewControllerDelegate {
    func completeQuizDidSelectAction(
        _ action: CompleteQuizViewModel.ActionType,
        originalQuizData: QuizData,
        result: QuizResult
    ) {
        switch action {
        case .restart:
            let newQuizData = QuizData(
                words: originalQuizData.allWord,
                allWord: originalQuizData.allWord
            )
            navigationController.dismiss(animated: true) { [weak self] in
                self?.restartQuiz(with: newQuizData)
            }
            
        case .retryIncorrect(let words):
            let newQuizData = QuizData(words: words, allWord: originalQuizData.allWord)
            navigationController.dismiss(animated: true) { [weak self] in
                self?.restartQuiz(with: newQuizData)
            }
            
        case .finish, .dismiss:
            finish()
        }
    }
    
    private func restartQuiz(with quizData: QuizData) {
        let vc = makeQuizViewController(quizData: quizData)
        navigationController.setViewControllers([vc], animated: false)
    }
    
    private func showInterruptAlert() {
        AlertUtils.showAlert(
            on: navigationController,
            title: "학습 중단",
            message: "정말로 학습을 중단하시겠습니까?",
            confirmAction: { [weak self] in
                DispatchQueue.main.async {
                    // dismiss 이후 화면 닫힘
                    self?.finish()
                }
            }
        )
    }

    private func finish() {
        navigationController.presentingViewController?.dismiss(animated: true)
        delegate?.quizCoordinatorDidFinish()   // dismiss 타이밍과 무관하게 즉시 부모에서 제거
    }
}

