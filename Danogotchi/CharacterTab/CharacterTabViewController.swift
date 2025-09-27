import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CharacterTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    
    private let testLabel = UILabel()
    
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
        testLabel.text = "캐릭터 탭"
        testLabel.textColor = .black
        
        view.addSubview(testLabel)
        testLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

// MARK: - Rx로직
extension CharacterTabViewController {
    private func bind() {
        
    }
}


