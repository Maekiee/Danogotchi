import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol VocabBookDetailViewControllerDelegate: AnyObject {
    func myBookDetailDidTapBack()
    func myBookDetailDidTapCreateWord(with createVocabModel: CreateVocab)
    func myBookDetailDidTapEditWord(with createVocabModel: CreateVocab)
}

final class VocabBookDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: VocabBookDetailViewModel
    weak var delegate: VocabBookDetailViewControllerDelegate?
    
    init(viewModel: VocabBookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI 프로퍼티
    private let test: UILabel = {
        let label = UILabel()
        label.text = "vocab book deatil View"
        label.font = AppFont.display
        label.textColor = AppColor.textPrimary
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()
    }
    
    override func configHierarchy() {
        [
            test
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        test.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    override func configView() {
        navigationItem.title = viewModel.navigationBarTitle
    }
}

extension VocabBookDetailViewController {
    private func bind() {
        let input = VocabBookDetailViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        output.vocabList
            .drive(with: self) { owner, list in
                print("뷰컨에서 단어장 리스트: \(list)")
            }.disposed(by: disposeBag)
        
    }
}
