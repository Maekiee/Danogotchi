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
    
    func exploreVocabDidTapEditWord(wordItem: CreateWord) {
        let vm = container.makeCreateWordViewModel(wordItem: wordItem)
        let vc = CreateWordViewController(viewModel: vm, entryPoint: .edit)
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        navigationController.present(vc, animated: true)
    }
}

extension MainCoordinator: CreateWordViewControllerDelegate {
    func createWordDidTapBack() {
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
