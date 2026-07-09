import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class LibraryViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: LibraryViewModel
    weak var delegate: LibraryViewControllerDelegate?
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: UI 프로퍼티
    private let textView: UILabel = {
        let label = UILabel()
        label.text = "테스트 text 입니다"
        label.textColor = .black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
    }
    
    override func configHierarchy() {
        [textView].forEach {
            view.addSubview($0)
        }
    }
    
    override func configLayout() {
        textView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    
    override func configView() {
    }
}
