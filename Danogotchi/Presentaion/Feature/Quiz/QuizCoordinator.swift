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
        let vm = container.makeChoiceQuizViewModel(quizData: quizData)
        let vc = ChoiceQuizViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
    }
}

extension QuizCoordinator: ChoiceQuizViewControllerDelegate {
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
        navigationController.dismiss(animated: true) { [weak self] in
            self?.delegate?.quizCoordinatorDidFinish()
        }
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
                self?.passNewQuizData(newQuizData)
            }
            
        case .retryIncorrect(let words):
            let newQuizData = QuizData(words: words, allWord: originalQuizData.allWord)
            navigationController.dismiss(animated: true) { [weak self] in
                self?.passNewQuizData(newQuizData)
            }
            
        case .finish:
            navigationController.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.navigationController.presentingViewController?.dismiss(animated: true) {
                    self.delegate?.quizCoordinatorDidFinish()
                }
            }
            
        case .dismiss:
            navigationController.dismiss(animated: true)
        }
    }
    
    private func passNewQuizData(_ quizData: QuizData) {
        guard let choiceVC = navigationController.viewControllers.first as? ChoiceQuizViewController else { return }
        choiceVC.updateQuizData(quizData)
    }
}


