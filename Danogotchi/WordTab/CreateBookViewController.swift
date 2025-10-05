import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CreateBookViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = CreateBookViewModel()
    
    
    //MARK: - UI 프로퍼티
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "새로운 단어장"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 17)
        return label
    }()
    private let bookTitleTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.font = .systemFont(ofSize: 18, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    
    private let createButton = PrimaryFillButton(title: "확인")
    private let cancelButton = PrimaryFillButton(title: "취소")
    
    private let buttonStackView: UIStackView = {
           let stack = UIStackView()
           stack.axis = .horizontal
           stack.spacing = 12
           stack.distribution = .fillEqually
           return stack
       }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        view.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(bookTitleTextField)
        containerView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(createButton)
    }
    
    override func configLayout() {
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        bookTitleTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(bookTitleTextField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(48)
        }
    }
    override func configView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
}


extension CreateBookViewController {
    private func bind() {
        let input = CreateBookViewModel.Input(
            textFieldValue: bookTitleTextField.tf.rx.text.orEmpty.asObservable(),
            createButtonTapped: createButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.createBookDoneTrigger
            .emit(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
    }
}
