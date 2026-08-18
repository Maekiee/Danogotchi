import UIKit
import SnapKit
import RxSwift
import RxCocoa


protocol CompleteQuizViewControllerDelegate: AnyObject {
    func completeQuizDidSelectAction(
        _ action: CompleteQuizViewModel.ActionType,
        originalQuizData: QuizData,
        result: QuizResult
    )
}

final class CompleteQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: CompleteQuizViewModel
    private let originalQuizData: QuizData
    private let currentResult: QuizResult
    weak var delegate: CompleteQuizViewControllerDelegate?
    
    // MARK: - 완료 후 액션을 전달하기 위한 클로저
//    var onDismissAction: ((CompleteQuizViewModel.ActionType, QuizData, QuizResult) -> Void)?
    
    init(viewModel: CompleteQuizViewModel, originalQuizData: QuizData, result: QuizResult) {
        self.viewModel = viewModel
        self.originalQuizData = originalQuizData
        self.currentResult = result
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "학습 완료!"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.display
        label.textAlignment = .center
        return label
    }()

    private let resultCard = QuizResultCard()
    private let primaryButton = CompleteActionButton(style: .primary, title: "")
    private let secondaryButton = CompleteActionButton(style: .secondary, title: "")
    private let endLearningButton = CompleteActionButton(style: .text, title: "학습 끝내기")

    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.space12
        [primaryButton, secondaryButton, endLearningButton].forEach { stack.addArrangedSubview($0) }
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
        [
            titleLabel,
            resultCard,
            buttonStackView
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space32)
            make.centerX.equalToSuperview()
        }

        resultCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(resultCard.snp.bottom).offset(AppSpacing.space32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space24)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
        }

        [primaryButton, secondaryButton].forEach {
            $0.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
        }

        endLearningButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    override func configView() {
        view.backgroundColor = AppColor.background
    }
}

extension CompleteQuizViewController {
    private func bind() {
        let input = CompleteQuizViewModel.Input(
            primaryButtonTap: primaryButton.rx.tap.asObservable(),
            secondaryButtonTap: secondaryButton.rx.tap.asObservable(),
            endLearningButtonTap: endLearningButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.scoreText
            .drive(with: self) { owner, text in
                owner.resultCard.scoreText = text
            }
            .disposed(by: disposeBag)

        output.summaryText
            .drive(with: self) { owner, text in
                owner.resultCard.summaryText = text
            }
            .disposed(by: disposeBag)

        output.correctCountText
            .drive(with: self) { owner, text in
                owner.resultCard.correctText = text
            }
            .disposed(by: disposeBag)

        output.incorrectCountText
            .drive(with: self) { owner, text in
                owner.resultCard.incorrectText = text
            }
            .disposed(by: disposeBag)

        output.experienceText
            .drive(with: self) { owner, text in
                owner.resultCard.experienceText = text
            }
            .disposed(by: disposeBag)

        output.primaryButtonTitle
            .drive(with: self) { owner, title in
                owner.primaryButton.setTitle(title, for: .normal)
            }
            .disposed(by: disposeBag)
        
        output.secondaryButtonTitle
            .drive(with: self) { owner, title in
                owner.secondaryButton.setTitle(title, for: .normal)
            }
            .disposed(by: disposeBag)
        
        output.primaryAction
            .emit(with: self) { owner, action in
                owner.handleAction(action)
            }
            .disposed(by: disposeBag)
        
        output.secondaryAction
            .emit(with: self) { owner, action in
                owner.handleAction(action)
            }
            .disposed(by: disposeBag)
        
        output.endLearningAction
            .emit(with: self) { owner, action in
                owner.handleAction(action)
            }.disposed(by: disposeBag)
        
        output.isEndLearningButtonHidden
            .drive(endLearningButton.rx.isHidden)
            .disposed(by: disposeBag)
    }
}

extension CompleteQuizViewController {
    private func handleAction(_ action: CompleteQuizViewModel.ActionType) {
        delegate?.completeQuizDidSelectAction(
            action,
            originalQuizData: originalQuizData,
            result: currentResult
        )
    }
}
