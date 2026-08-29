import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol OnboardingPetNameViewControllerDelegate: AnyObject {
    func onboardingPetNameDidFinish()
}

final class OnboardingPetNameViewController: BaseViewController {

    weak var delegate: OnboardingPetNameViewControllerDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel: OnboardingPetNameViewModel

    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "이름을 지어주세요"
        label.font = AppFont.font(.semibold, size: 28)
        label.textColor = AppColor.textPrimary
        return label
    }()
    private let nameTextField = RoundedTextField(placeholder: "이름")
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.footnote
        label.textColor = AppColor.error
        label.numberOfLines = 0
        return label
    }()
    private let doneButton = PrimaryFillButton(title: "완료")

    init(viewModel: OnboardingPetNameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()
    }

    override func configHierarchy() {
        [
            titleLabel,
            nameTextField,
            errorLabel,
            doneButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }

        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.space24)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(AppSpacing.space8)
            make.horizontalEdges.equalTo(nameTextField).inset(AppSpacing.space4)
        }

        doneButton.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualTo(view.keyboardLayoutGuide.snp.top).offset(-AppSpacing.space20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20).priority(.high)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }
    }

    override func configView() {
        doneButton.isEnabled = false
    }
}

extension OnboardingPetNameViewController {
    private func bind() {
        let input = OnboardingPetNameViewModel.Input(
            nameText: nameTextField.rx.text.orEmpty.asObservable(),
            doneTapped: doneButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.errorMessage
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)

        output.isDoneEnabled
            .drive(doneButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.didCreatePet
            .emit(with: self) { owner, _ in
                owner.view.endEditing(true)
                owner.delegate?.onboardingPetNameDidFinish()
            }.disposed(by: disposeBag)

        output.alertMessage
            .emit(with: self) { owner, message in
                AlertPresenter.showNotificationAlert(on: owner, title: "알림", message: message)
            }.disposed(by: disposeBag)
    }
}
