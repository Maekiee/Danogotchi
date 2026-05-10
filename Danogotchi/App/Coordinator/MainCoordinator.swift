import UIKit

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
        let nav = UINavigationController()
        let libraryCoordinator = LibraryCoordinator(
            container: container,
            navigationController: nav
        )
        libraryCoordinator.delegate = self
        addChild(libraryCoordinator)
        libraryCoordinator.start()
        navigationController.present(nav, animated: true)
    }
    
    func wordTabDidTapCreateBook() {
//        let vm = container.makeCreateBookViewModel()
//        let vc = CreateBookViewController(viewModel: vm)
        // TODO: A-4에서 LibraryCoordinator 경로
    }
    
    func wordTabDidTapSetting() {
        let nav = UINavigationController()
        let settingCoordinator = SettingCoordinator(
            container: container,
            navigationController: nav
        )
        settingCoordinator.delegate = self
        addChild(settingCoordinator)
        settingCoordinator.start()
        navigationController.present(nav, animated: true)
    }
    
    func wordTabDidTapStartQuiz(quizData: QuizData) {
        // TODO: A-6에서 QuizCoordinator 생성/present
    }
    
    func wordTabDidTapEditWord(wordItem: CreateWord) {
        // TODO: A-4 또는 직접 present (AddWord는 단일 화면)
    }
}

extension MainCoordinator: LibraryCoordinatorDelegate {
    func libraryCoordinatorDidFinish() {
        childCoordinators.removeAll { $0 is LibraryCoordinator }
    }
}

extension MainCoordinator: SettingCoordinatorDelegate {
    func settingCoordinatorDidFinish() {
        childCoordinators.removeAll { $0 is SettingCoordinator }
    }
    
}
