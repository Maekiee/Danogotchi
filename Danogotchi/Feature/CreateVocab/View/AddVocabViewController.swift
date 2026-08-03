import UIKit
import SnapKit
import RxSwift
import RxCocoa


protocol AddVocabViewControllerDelegate: AnyObject {
    func addVocabDidFinishEditing()
}

final class AddVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: AddVocabViewModel
    weak var delegate: AddVocabViewControllerDelegate?

    init(viewModel: AddVocabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 프로퍼티
    private let wordTextField = AddVocabViewController.makeTextField(placeholder: "단어")
    private let meaningTextField = AddVocabViewController.makeTextField(placeholder: "뜻")
    private let partOfSpeechSegmentedControl = AddVocabViewController.makePartOfSpeechSegmentedControl()
    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = viewModel.isEditing ? "수정" : "저장"
        config.baseBackgroundColor = AppColor.black
        config.baseForegroundColor = AppColor.white
        config.background.cornerRadius = AppRadius.radius20
        let button = UIButton(configuration: config)
        button.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = AppFont.title3
                return outgoing
            }
        button.configurationUpdateHandler = { button in
            let isEnabled = button.state != .disabled
            button.configuration?.baseBackgroundColor = isEnabled ? AppColor.black : AppColor.gray30
            button.configuration?.baseForegroundColor = isEnabled ? AppColor.white : AppColor.gray45
        }
        return button
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
            wordTextField,
            meaningTextField,
            partOfSpeechSegmentedControl,
            saveButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        wordTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space24)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }

        meaningTextField.snp.makeConstraints { make in
            make.top.equalTo(wordTextField.snp.bottom).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }

        partOfSpeechSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(meaningTextField.snp.bottom).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(40)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(partOfSpeechSegmentedControl.snp.bottom).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }
    }

    override func configView() {
        view.backgroundColor = AppColor.background
        navigationItem.title = viewModel.isEditing ? "Edit a word" : "Add a word"

        // bind()보다 먼저 채워야 rx.text / rx.selectedSegmentIndex의 초기 방출에 값이 실린다.
        if let form = viewModel.initialForm {
            wordTextField.text = form.word
            meaningTextField.text = form.meaning
            partOfSpeechSegmentedControl.selectedSegmentIndex = form.partOfSpeechIndex
        }
    }
}

// MARK: - UI 팩토리
extension AddVocabViewController {
    private static func makeTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = AppColor.white
        textField.layer.cornerRadius = AppRadius.radius20
        textField.layer.borderWidth = AppBorder.thin
        textField.layer.borderColor = AppColor.gray30.cgColor
        textField.clipsToBounds = true
        textField.font = AppFont.title2
        
        textField.textColor = AppColor.black
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: AppFont.title2,
                .foregroundColor: AppColor.gray45
            ]
        )
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no

        let paddingFrame = CGRect(x: 0, y: 0, width: AppSpacing.space20, height: 0)
        textField.leftView = UIView(frame: paddingFrame)
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: paddingFrame)
        textField.rightViewMode = .always

        return textField
    }

    private static func makePartOfSpeechSegmentedControl() -> UISegmentedControl {
        let control = UISegmentedControl(items: PartOfSpeech.allCases.map { $0.title })
        control.selectedSegmentIndex = 0 // 기본값: allCases의 첫 값
        control.backgroundColor = AppColor.white
        control.selectedSegmentTintColor = AppColor.black
        control.layer.cornerRadius = AppRadius.radius20
        control.layer.borderWidth = AppBorder.thin
        control.layer.borderColor = AppColor.gray30.cgColor
        control.clipsToBounds = true
        control.setTitleTextAttributes(
            [.font: AppFont.label, .foregroundColor: AppColor.black],
            for: .normal
        )
        control.setTitleTextAttributes(
            [.font: AppFont.label, .foregroundColor: AppColor.white],
            for: .selected
        )

        return control
    }
}

// MARK: - 바인딩
extension AddVocabViewController {
    private func bind() {
        let input = AddVocabViewModel.Input(
            wordTextField: wordTextField.rx.text.orEmpty.asObservable(),
            meaningTextField: meaningTextField.rx.text.orEmpty.asObservable(),
            partOfSpeechSegment: partOfSpeechSegmentedControl.rx.selectedSegmentIndex.asObservable(),
            savedButtonTapped: saveButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.isValidSave
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.resetTrigger
            .emit(with: self) { owner, _ in
                owner.wordTextField.text = ""
                owner.meaningTextField.text = ""
                owner.partOfSpeechSegmentedControl.selectedSegmentIndex = 0
                owner.showToast("단어가 추가 되었습니다.")
            }.disposed(by: disposeBag)

        output.editCompleted
            .emit(with: self) { owner, _ in
                owner.delegate?.addVocabDidFinishEditing()
            }.disposed(by: disposeBag)
    }
}
