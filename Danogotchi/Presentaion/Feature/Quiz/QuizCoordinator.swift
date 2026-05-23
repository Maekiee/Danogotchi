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
        navigationController.setViewControllers([vc], animated: false)
    }
}

