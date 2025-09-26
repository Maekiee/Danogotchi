import UIKit
import RxSwift
import RxCocoa
import SnapKit


final class SetUserNameViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SetUsernameViewModel()
    
    // MARK: - UI 선언
    private let usernameTextField = UnderlineTextField(placeholder: "닉네임")
    private let confirmButton = PrimaryFillButton(title: "확인")
    private let validText: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        setupKeyboardObserver()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            usernameTextField,
            confirmButton,
            validText
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
        
        validText.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(4)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
    }
    
    override func configView() {
        
    }
    
    // 키보드 업다운
    private func setupKeyboardObserver() {
        // 버튼 업
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .bind(with: self) { owner, keyboardFrame in
                owner.confirmButton.snp.updateConstraints { make in
                    make.bottom.equalTo(owner.view.safeAreaLayoutGuide).offset(-keyboardFrame.height + 20)
                }
                UIView.animate(withDuration: 0.3) {
                    owner.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
        
        // 버튼 다운
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .bind(with: self) { owner, _ in
                owner.confirmButton.snp.updateConstraints { make in
                    make.bottom.equalTo(owner.view.safeAreaLayoutGuide).offset(-20)
                }
                UIView.animate(withDuration: 0.3) {
                    owner.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
    }
}


// MARK: - Rx 로직
extension SetUserNameViewController {
    private func bind() {
        let input = SetUsernameViewModel.Input(
            usernameTextField: usernameTextField.tf.rx.text.orEmpty.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.usernameValidText
            .drive(validText.rx.text)
            .disposed(by: disposeBag)
        
    }
}
