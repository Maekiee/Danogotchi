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

    func libraryDidTapMore(topic: BookTopic) {
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
    
    func myBookDetailDidTapEditVocab(_ vocab: Vocab) {
        let vm = appDIContainer.makeAddVocabViewModel(editingVocab: vocab)
        let vc = AddVocabViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }

    func floatingButtonDidTap() {
        let vm = appDIContainer.makeAddVocabViewModel()
        let vc = AddVocabViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}

extension LibraryCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.libraryCoordinatorDidFinish()
    }
}

extension LibraryCoordinator: AddVocabViewControllerDelegate {
    func addVocabDidFinishEditing() {
        navigationController.popViewController(animated: true)
        // showToast는 VC 자기 view에 붙으므로, pop으로 노출되는 화면에 띄운다.
        (navigationController.topViewController as? BaseViewController)?
            .showToast("단어가 수정 되었습니다.")
    }
}
