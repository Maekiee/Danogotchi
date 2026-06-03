import UIKit

protocol LibraryCoordinatorDelegate: AnyObject {
    func libraryCoordinatorDidFinish()
}

final class LibraryCoordinator:NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let DIContainer: DIContainer
    weak var delegate: LibraryCoordinatorDelegate?
    
    init(container: DIContainer, navigationController: UINavigationController) {
        self.DIContainer = container
        self.navigationController = navigationController
        super.init()
    }
}

extension LibraryCoordinator {
    func start() {
        let vm = DIContainer.makeBookListViewModel()
        let vc = BookListViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
        navigationController.presentationController?.delegate = self
    }
}


extension LibraryCoordinator: BookListViewControllerDelegate {
    func bookListDidTapClose() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.delegate?.libraryCoordinatorDidFinish()
        }
    }

    func bookListDidSelectActiveBook() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.delegate?.libraryCoordinatorDidFinish()
        }
    }

    func bookListDidTapMore() {
        let vm = DIContainer.makeMyBookDetailViewModel()
        let vc = MyBookDetailViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}


extension LibraryCoordinator: MyBookDetailViewControllerDelegate {
    func myBookDetailDidTapBack() {
        navigationController.popViewController(animated: true)
    }
    
    func myBookDetailDidTapAddWord(with createWordModel: CreateWord) {
        let vm = DIContainer.makeAddWordViewModel(wordItem: createWordModel)
        let vc = AddWordViewController(viewModel: vm, entryPoint: .add)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func myBookDetailDidTapEditWord(with createWordModel: CreateWord) {
        let vm = DIContainer.makeAddWordViewModel(wordItem: createWordModel)
        let vc = AddWordViewController(viewModel: vm, entryPoint: .edit)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}

extension LibraryCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.libraryCoordinatorDidFinish()
    }
}

extension LibraryCoordinator: AddWordViewControllerDelegate {
    func addWordDidTapBack() {
        navigationController.popViewController(animated: true)
    }
}
