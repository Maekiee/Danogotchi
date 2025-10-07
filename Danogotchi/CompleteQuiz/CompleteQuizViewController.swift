import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: CompleteQuizViewModel
    private let originalQuizData: QuizData
    private let currentResult: QuizResult
    
    // MARK: - 완료 후 액션을 전달하기 위한 클로저
    var onDismissAction: ((CompleteQuizViewModel.ActionType, QuizData, QuizResult) -> Void)?
    
    init(viewModel: CompleteQuizViewModel, originalQuizData: QuizData, result: QuizResult) {
        self.viewModel = viewModel
        self.originalQuizData = originalQuizData
        self.currentResult = result
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "학습 완료"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let primaryButton = PrimaryFillButton(title: "")
    private let secondaryButton = PrimaryFillButton(title: "")
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        [primaryButton, secondaryButton].forEach { stack.addArrangedSubview($0) }
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
            scoreLabel,
            buttonStackView
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.centerX.equalToSuperview()
        }
        
        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(24)
        }
        
        [primaryButton, secondaryButton].forEach {
            $0.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }
    }
    
    override func configView() {
        
    }
}

extension CompleteQuizViewController {
    private func bind() {
        let input = CompleteQuizViewModel.Input(
            primaryButtonTap: primaryButton.rx.tap.asObservable(),
            secondaryButtonTap: secondaryButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.scoreText
            .drive(scoreLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.primaryButtonTitle
            .drive(with: self) { owner, title in
                print("Primary button title: \(title)")
                owner.primaryButton.setTitle(title, for: .normal)
            }
            .disposed(by: disposeBag)
        
        output.secondaryButtonTitle
            .drive(with: self) { owner, title in
                print("Secondary button title: \(title)")
                owner.secondaryButton.setTitle(title, for: .normal)
            }
            .disposed(by: disposeBag)
        
        output.primaryAction
            .emit(with: self) { owner, action in
                print("Primary action triggered: \(action)")
                owner.handleAction(action)
            }
            .disposed(by: disposeBag)
        
        output.secondaryAction
            .emit(with: self) { owner, action in
                print("Secondary action triggered: \(action)")
                owner.handleAction(action)
            }
            .disposed(by: disposeBag)
    }
}

extension CompleteQuizViewController {
    private func handleAction(_ action: CompleteQuizViewModel.ActionType) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onDismissAction?(action, self.originalQuizData, self.currentResult)
        }
    }
}
