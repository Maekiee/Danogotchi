import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class AddVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()

    // MARK: - UI 프로퍼티
    private let wordSectionLabel = AddVocabViewController.makeSectionLabel("WORD")
    private let wordTextField = AddVocabViewController.makeTextField(placeholder: "단어")
    private let meaningSectionLabel = AddVocabViewController.makeSectionLabel("MEANING")
    private let meaningTextField = AddVocabViewController.makeTextField(placeholder: "뜻")
    private let saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "저장"
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
            wordSectionLabel,
            wordTextField,
            meaningSectionLabel,
            meaningTextField,
            saveButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        wordSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space32)
            make.leading.equalToSuperview().offset(AppSpacing.space20)
        }

        wordTextField.snp.makeConstraints { make in
            make.top.equalTo(wordSectionLabel.snp.bottom).offset(AppSpacing.space12)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(56)
        }

        meaningSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(wordTextField.snp.bottom).offset(AppSpacing.space24)
            make.leading.equalToSuperview().offset(AppSpacing.space20)
        }

        meaningTextField.snp.makeConstraints { make in
            make.top.equalTo(meaningSectionLabel.snp.bottom).offset(AppSpacing.space12)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(56)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(meaningTextField.snp.bottom).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(56)
        }
    }

    override func configView() {
        view.backgroundColor = AppColor.background
        navigationItem.title = "Add a word"
    }
}

// MARK: - UI 팩토리
extension AddVocabViewController {
    private static func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: AppFont.label,
                .foregroundColor: AppColor.textSecondary,
                .kern: 1.0
            ]
        )
        return label
    }

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
}

// MARK: - 바인딩
extension AddVocabViewController {
    private func bind() {
        Observable.combineLatest(
            wordTextField.rx.text.orEmpty,
            meaningTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty }
        .bind(to: saveButton.rx.isEnabled)
        .disposed(by: disposeBag)
    }
}
