import ComposableArchitecture
import SwiftUI
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
    
    // 학습 리포트
    func exploreVocabDidTapStudyReport() {
        let nav = UINavigationController()
        let feature = container.makeStudyReportFeature(
            onClose: { [weak nav] in nav?.presentingViewController?.dismiss(animated: true) },
            onNavigate: { [weak self, weak nav] destination in
                guard let nav else { return }
                self?.showStudyReport(destination, in: nav)
            }
        )
        let store = Store(initialState: StudyReportFeature.State()) { feature }
        let vc = UIHostingController(rootView: StudyReportView(store: store))
        nav.setViewControllers([vc], animated: false)
        nav.modalPresentationStyle = .fullScreen
        navigationController.present(nav, animated: true)
    }

    private func showStudyReport(_ destination: StudyReportDestination, in nav: UINavigationController) {
        switch destination {
        case let .words(list):
            let view = StudyReportWordListView(
                list: list,
                onSelect: { [weak self, weak nav] word in
                    guard let nav else { return }
                    self?.showStudyReport(.word(word, list), in: nav)
                },
                onClose: { [weak nav] in nav?.presentingViewController?.dismiss(animated: true) }
            )
            nav.pushViewController(UIHostingController(rootView: view), animated: true)
        case let .word(word, _):
            let view = StudyReportWordDetailView(word: word)
            let controller = UIHostingController(rootView: view)
            controller.modalPresentationStyle = .pageSheet
            controller.sheetPresentationController?.detents = [.medium(), .large()]
            controller.sheetPresentationController?.prefersGrabberVisible = true
            nav.present(controller, animated: true)
        }
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
        let vm = container.makeCharacterViewModel()
        let vc = CharacterViewController(viewModel: vm)
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
