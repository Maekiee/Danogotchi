import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CharacterViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    
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
    
    override func configView() { }
}

extension CharacterViewController {
    private func bind() {
        
    }
}
