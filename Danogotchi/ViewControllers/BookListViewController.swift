import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class BookListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = BookListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func configHierarchy() {
        
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
}


extension BookListViewController {
    private func bind() {
        
    }
}
