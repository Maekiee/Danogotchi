import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class WordImageListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: WordImageListViewModel
    
    init(viewModel: WordImageListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIProperty
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.title = viewModel.wordText
    }
}

extension WordImageListViewController {
    private func bind() {
        navigationItem.leftBarButtonItem!.rx.tap
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
    }
}
