import UIKit

final class MainCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let container: AppDIContainer
    
    init(
        container: AppDIContainer,
        navigationController: UINavigationController
    ) {
        self.container = container
        self.navigationController = navigationController
    }
    
    func start() {
        let exploreVocabVm = container.makeExploreVocabViewModel()
        let exploreVocabVc = ExploreVocabViewController(viewModel: exploreVocabVm)
        exploreVocabVc.delegate = self
        navigationController.setViewControllers([exploreVocabVc], animated: false)
    }
}

extension MainCoordinator: ExploreVocabViewControllerDelegate {
    func exploreVocabDidTapLibrary() {
        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen
        let libraryCoordinator = LibraryCoordinator(
            container: container,
            navigationController: nav
        )
        libraryCoordinator.delegate = self
        addChild(libraryCoordinator)
        libraryCoordinator.start()
        navigationController.present(nav, animated: true)
    }
    
    func exploreVocabDidTapSetting() {
        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen
        let settingCoordinator = SettingCoordinator(
            container: container,
            navigationController: nav
        )
        settingCoordinator.delegate = self
        addChild(settingCoordinator)
        settingCoordinator.start()
        navigationController.present(nav, animated: true)
    }
    
    // 학습하기
    func exploreVocabDidTapStartQuiz(quizData: QuizData) {
        let nav = UINavigationController()
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        let quizCoordinator = QuizCoordinator(
            container: container,
            navigationController: nav,
            quizData: quizData
        )
        quizCoordinator.delegate = self
        addChild(quizCoordinator)
        quizCoordinator.start()
        navigationController.present(nav, animated: true)
        
    }
    
    // 캐릭터탭
    func didTapCharacter() {
        let vc = CharacterViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        navigationController.present(nav, animated: true)
    }
}

extension MainCoordinator: CharacterViewControllerDelegate {
    func characterDidTapClose() {
        navigationController.dismiss(animated: true)
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

extension MainCoordinator: QuizCoordinatorDelegate {
    func quizCoordinatorDidFinish() {
        childCoordinators.removeAll { $0 is QuizCoordinator }
    }
}
