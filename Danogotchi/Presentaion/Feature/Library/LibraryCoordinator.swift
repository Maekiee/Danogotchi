import UIKit

protocol LibraryCoordinatorDelegate: AnyObject {
    func libraryCoordinatorDidFinish()
}

final class LibraryCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let container: DIContainer
    weak var delegate: LibraryCoordinatorDelegate?
    
    init(container: DIContainer, navigationController: UINavigationController) {
        self.container = container
        self.navigationController = navigationController
    }
}

extension LibraryCoordinator {
    func start() {
        let vm = container.makeBookListViewModel()
        let vc = BookListViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
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
        // TODO: A-4-D에서 MyBookDetailVC push
    }
}
