import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VocabBookDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: VocabBookDetailViewModel
    
    init(viewModel: VocabBookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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

extension VocabBookDetailViewController {
    private func bind() {
        
    }
}
