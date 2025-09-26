import UIKit
import RxSwift
import RxCocoa
import SnapKit


final class SetUserNameViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SetUsernameViewModel()
    
//    private let usernameTextField = PrimaryTextField(placeholderText: "닉네임을 입력해주세요")
    private let usernameTextField: PrimaryTextField = {
        let tf = PrimaryTextField()
        tf.placeholder = "닉네임을 입력해주세요"
        return tf
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
            usernameTextField,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
    }
    
    override func configView() {
        
    }

}


// MARK: - RX 로직
extension SetUserNameViewController {
    private func bind() {
    }
}
