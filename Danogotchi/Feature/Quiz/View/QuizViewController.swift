import UIKit
import SnapKit
import RxSwift
import RxCocoa


protocol QuizViewControllerDelegate: AnyObject {
    func quizDidComplete(originalData: QuizData, result: QuizResult)
    func quizDidTapClose()
    func quizDidAbortAfterSaveFailure()
}

final class QuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: QuizViewModel
    weak var delegate: QuizViewControllerDelegate?
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 프로퍼티
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        return button
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "단어 학습"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.font(.bold, size: 17)
        label.textAlignment = .center
        return label
    }()
    private let currentQuestionLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.label
        return label
    }()
    private let progressView = CustomProgressView()
    private let totalQuestionLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.label
        return label
    }()
    private let quizQuestionCard = QuisQuestionCard()
    private let choiceButtons = (0..<4).map { _ in ChoiceButton() }
    private lazy var choiceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.space12
        stack.distribution = .fillEqually

        choiceButtons.forEach { stack.addArrangedSubview($0) }
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
            closeButton,
            progressView,
            quizQuestionCard,
            choiceStackView
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space12)
            make.size.equalTo(44)
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
            make.height.equalTo(12)  
        }
        
        quizQuestionCard.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(160)
        }
        
        choiceStackView.snp.makeConstraints { make in
            make.top.equalTo(quizQuestionCard.snp.bottom).offset(48)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space24)
        }
        
        choiceButtons.forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.background
    }
}

extension QuizViewController {
    /// 재시도가 다시 실패하면 알림이 자기 액션 핸들러 안에서 재표시된다.
    /// 이전 알림이 아직 떠 있으면 dismiss가 끝난 뒤에 띄워야 present가 유실되지 않는다.
    private func presentSaveFailureAlert(
        _ failure: QuizViewModel.SaveFailure,
        onRetry: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "저장 실패",
            message: failure == .retryable
                ? "학습 결과를 저장하지 못했어요. 다시 시도해주세요."
                : "이 단어를 찾을 수 없어 학습 결과를 저장할 수 없어요. 학습을 종료합니다.",
            preferredStyle: .alert
        )
        if failure == .retryable {
            alert.addAction(UIAlertAction(title: "재시도", style: .default) { _ in onRetry() })
        }
        alert.addAction(UIAlertAction(title: "종료", style: .cancel) { [weak self] _ in
            self?.viewModel.endSession()
            self?.delegate?.quizDidAbortAfterSaveFailure()
        })

        if let presented = presentedViewController {
            presented.dismiss(animated: true) { [weak self] in self?.present(alert, animated: true) }
        } else {
            present(alert, animated: true)
        }
    }

    private func bind() {
        let choiceTaps = Observable.merge(
            choiceButtons.enumerated().map { index, button in
                button.rx.tap.map { index }
            }
        )
        
        let retrySave = PublishRelay<Void>()
        let input = QuizViewModel.Input(
            choiceSelected: choiceTaps,
            retrySave: retrySave.asObservable()
        )
        
        let output = viewModel.transform(input: input)

        output.canAnswer
            .drive(with: self) { owner, enabled in
                owner.choiceButtons.forEach { $0.isEnabled = enabled }
            }.disposed(by: disposeBag)

        output.saveFailed
            .emit(with: self) { owner, failure in
                owner.presentSaveFailureAlert(failure) { retrySave.accept(()) }
            }.disposed(by: disposeBag)
        
        
        output.progress
            .drive(progressView.rx.progress)
            .disposed(by: disposeBag)
        
        Driver.combineLatest(output.currentQuestion, output.totalQuestion)
            .map { "\($0) / \($1)" }
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.questionWord
            .drive(with: self) { owner, text in
                owner.quizQuestionCard.text = text
                owner.quizQuestionCard.cardBackgroundColor = AppColor.pastel(for: text)
            }.disposed(by: disposeBag)

        output.choices
            .drive(with: self) { owner, choices in
                // 버튼 상태 초기화
                owner.choiceButtons.forEach {
                    $0.apply(.idle)
                }

                zip(owner.choiceButtons, choices).forEach { button, title in
                    button.setTitle(title, for: .normal)
                }
            }.disposed(by: disposeBag)

        output.answerResult
            .emit(with: self) { owner, result in
                owner.choiceButtons.forEach { $0.isEnabled = false }

                owner.choiceButtons[result.selectedIndex]
                    .apply(result.isCorrect ? .correct : .wrong)

                if !result.isCorrect {
                    owner.choiceButtons[result.correctIndex].apply(.correct)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak owner] in
                    owner?.viewModel.moveToNextQuestion()
                }
            }
            .disposed(by: disposeBag)
        
        output.quizCompleted
            .emit(with: self) { owner, completed in
                owner.delegate?.quizDidComplete(
                    originalData: completed.originalData,
                    result: completed.result
                )
            }.disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.quizDidTapClose()
            }.disposed(by: disposeBag)
    }
}
