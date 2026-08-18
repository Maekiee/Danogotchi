import UIKit
import SnapKit
import RxSwift
import RxCocoa


protocol QuizViewControllerDelegate: AnyObject {
    func quizDidComplete(originalData: QuizData, result: QuizResult)
    func quizDidTapClose()
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
    private func bind() {
        let choiceTaps = Observable.merge(
            choiceButtons.enumerated().map { index, button in
                button.rx.tap.map { index }
            }
        )
        
        let input = QuizViewModel.Input(
            choiceSelected: choiceTaps
        )
        
        let output = viewModel.transform(input: input)
        
        
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
                    $0.isEnabled = true
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
