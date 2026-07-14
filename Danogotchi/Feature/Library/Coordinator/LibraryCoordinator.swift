import UIKit

protocol LibraryCoordinatorDelegate: AnyObject {
    func libraryCoordinatorDidFinish()
}

final class LibraryCoordinator:NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let appDIContainer: AppDIContainer
    weak var delegate: LibraryCoordinatorDelegate?
    
    init(container: AppDIContainer, navigationController: UINavigationController) {
        self.appDIContainer = container
        self.navigationController = navigationController
        super.init()
    }
}

extension LibraryCoordinator {
    func start() {
        let vm = appDIContainer.makeLibraryViewModel()
        let vc = LibraryViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
        navigationController.presentationController?.delegate = self
    }
}


extension LibraryCoordinator: LibraryViewControllerDelegate {
    func libraryDidTapClose() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.delegate?.libraryCoordinatorDidFinish()
        }
    }

    func libraryDidSelectActiveBook() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.delegate?.libraryCoordinatorDidFinish()
        }
    }

    func libraryDidTapMore(topic: BookTopic) {
//        let vm = appDIContainer.makeMyBookDetailViewModel()
//        let vc = MyBookDetailViewController(viewModel: vm)
        let vm = appDIContainer.makeVocabDetailViewModel(topic: topic)
        let vc = VocabBookDetailViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}


extension LibraryCoordinator: VocabBookDetailViewControllerDelegate {
    func myBookDetailDidTapBack() {
        navigationController.popViewController(animated: true)
    }
    
    func myBookDetailDidTapCreateWord(with createVocabModel: CreateVocab) {
        let vm = appDIContainer.makeCreateWordViewModel(vocabItem: createVocabModel)
        let vc = CreateVocabViewController(viewModel: vm, entryPoint: .add)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }

    func myBookDetailDidTapEditWord(with createVocabModel: CreateVocab) {
        let vm = appDIContainer.makeCreateWordViewModel(vocabItem: createVocabModel)
        let vc = CreateVocabViewController(viewModel: vm, entryPoint: .edit)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}

extension LibraryCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.libraryCoordinatorDidFinish()
    }
}

extension LibraryCoordinator: CreateVocabViewControllerDelegate {
    func createWordDidTapBack() {
        navigationController.popViewController(animated: true)
    }
}
