import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher


final class SelectQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SelectQuizViewModel()
    
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

extension SelectQuizViewController {
    private func bind() {
        
    }
}

