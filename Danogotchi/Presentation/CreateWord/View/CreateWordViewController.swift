import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher


protocol CreateWordViewControllerDelegate: AnyObject {
    func createWordDidTapBack()
}

final class CreateWordViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: CreateWordViewModel
    private let entryPoint: EntryPoint
    weak var delegate: CreateWordViewControllerDelegate?
    
    init(viewModel: CreateWordViewModel, entryPoint: EntryPoint) {
        self.viewModel = viewModel
        self.entryPoint = entryPoint
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI Property
    private let backButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.backward")
        config.title = "Back"
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.textPrimary
        button.configuration = config
        return button
    }()
    private let wordBookTitleTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "단어장 세트 이름"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    private let wordTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "단어"
        tf.placeholder = "단어를 입력해 주세요"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    private let meanTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "뜻"
        tf.placeholder = "단어의 뜻을 입력해 주세요"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    private lazy var addWordButton = PrimaryFillButton(title: self.entryPoint == .add ? "저장" : "수정")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            backButton,
            wordTextField,
            meanTextField,
            addWordButton,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(8)
        }
        
        wordTextField.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        meanTextField.snp.makeConstraints { make in
            make.top.equalTo(wordTextField.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        [
            wordTextField,
            meanTextField
        ].forEach { underlineTextField in
            underlineTextField.tf.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
        }
        
        addWordButton.snp.makeConstraints { make in
            make.top.equalTo(meanTextField.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
        
    }
}

extension CreateWordViewController {
    private func bind() {
        let selectedImage = PublishRelay<String>()
        var currentImageUrl = ""
        
        let input = CreateWordViewModel.Input(
            wordBookTitleTextField: wordBookTitleTextField.tf.rx.text.orEmpty.asObservable(),
            wordTextField: wordTextField.tf.rx.text.orEmpty.asObservable(),
            meanTextField: meanTextField.tf.rx.text.orEmpty.asObservable(),
            selectedImage: selectedImage.asObservable(),
            savedButtonTapped: addWordButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        backButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.createWordDidTapBack()
            }.disposed(by: disposeBag)
        
        // 레거시 코드 정리 예정
        output.wordImageUrl
            .drive(with: self) { owner, url in
                currentImageUrl = url
            }.disposed(by: disposeBag)
        
        output.bookTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        
        output.wordTextFieldText
            .drive(with: self) { owner, text in
                if owner.wordTextField.text?.isEmpty == true {
                    owner.wordTextField.text = text
                }
            }.disposed(by: disposeBag)
        
        output.meanText
            .drive(with: self) { owner, text in
                if owner.meanTextField.text?.isEmpty == true {
                    owner.meanTextField.text = text
                }
            }.disposed(by: disposeBag)
        
        
        output.translateWord
            .map { valueText in
                return valueText.isEmpty ? "단어의 뜻을 입력해 주세요" : valueText
            }
            .drive(meanTextField.rx.placeholder)
            .disposed(by: disposeBag)
        
        output.isValidSave
            .drive(addWordButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.resetTrigger
            .emit(with: self) { owner, _  in
//                guard let self = self else { return }
                // 단어장 제목을 제외한 나머지 필드를 초기화
                owner.wordTextField.text = ""
                owner.meanTextField.text = ""
                currentImageUrl = ""
                
                let message = owner.entryPoint == .add ? "단어가 추가 되었습니다." : "단어가 수정 되었습니다."
                owner.showToast(message, duration: .short)
            }.disposed(by: disposeBag)
    }
}
