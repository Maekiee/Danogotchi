import UIKit


protocol MainCoordinatorDelegate {
    
}

final class MainCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let container: DIContainer
    
    init(
        container: DIContainer,
        navigationController: UINavigationController
    ) {
        self.container = container
        self.navigationController = navigationController
    }
    
    func start() {
        let wordTabVm = container.makeWordTabViewModel()
        let wordTabVc = WordTabViewController(viewModel: wordTabVm)
        wordTabVc.delegate = self
        navigationController.setViewControllers([wordTabVc], animated: false)
    }
}

extension MainCoordinator: WordTabViewControllerDelegate {
    func wordTabDidTapBookList() {
        // TODO: A-4에서 LibraryCoordinator 생성/push 처리
    }
    
    func wordTabDidTapCreateBook() {
        // TODO: A-4에서 LibraryCoordinator 경로
    }
    
    func wordTabDidTapSetting() {
        // TODO: A-5에서 SettingCoordinator 생성 후 present
    }
    
    func wordTabDidTapStartQuiz(quizData: QuizData) {
        // TODO: A-6에서 QuizCoordinator 생성/present
    }
    
    func wordTabDidTapEditWord(wordItem: CreateWord) {
        // TODO: A-4 또는 직접 present (AddWord는 단일 화면)
    }
}

