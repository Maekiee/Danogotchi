import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol CharacterViewControllerDelegate: AnyObject {
    func characterDidTapClose()
}

final class CharacterViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    weak var delegate: CharacterViewControllerDelegate?

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "테스트 레이블"
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
            testLabel,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        testLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configView() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil
        )
    }
}

extension CharacterViewController {
    private func bind() {
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.characterDidTapClose()
            }.disposed(by: disposeBag)
    }
}
