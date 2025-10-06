import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: CompleteQuizViewModel
    
    init(viewModel: CompleteQuizViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
    }
    
    override func configHierarchy() {
        
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        
    }
}

extension CompleteQuizViewController {
    private func bind() {
        let input = CompleteQuizViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
