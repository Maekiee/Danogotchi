import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class LibraryTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = LibraryTabViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()
    }
    
    override func configHierarchy() {
        
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        
    }
    
}

extension LibraryTabViewController {
    private func bind() {
        let input = LibraryTabViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
        )
        
        let ouput = viewModel.transform(input: input)
        
        
    }
}
