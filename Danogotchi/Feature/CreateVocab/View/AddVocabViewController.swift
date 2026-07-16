import UIKit
import SnapKit
import RxSwift
import RxCocoa



final class AddVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    
    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "테스트 텍스트 입니다."
        label.textColor = AppColor.textPrimary
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()

    }
    
    override func configHierarchy() {
        [
            testLabel
        ].forEach {
            view.addSubview($0)
        }
    }
    
    override func configLayout() {
        testLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.background
    }
}


