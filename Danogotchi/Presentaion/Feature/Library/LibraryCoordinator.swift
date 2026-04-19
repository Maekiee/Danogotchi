import UIKit

protocol LibraryCoordinatorDelegate: AnyObject {
    func libraryCoordinatorDidFinish()
}

final class LibraryCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
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
        // TODO: A-4-C에서 BookListViewModel 주입 + BookListVC 생성 + delegate 연결
        // 지금은 비워둠
    }
}
