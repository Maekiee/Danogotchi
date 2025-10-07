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
        
        print("CompleteQuiz - Mode: \(originalQuizData.mode)")
        print("CompleteQuiz - HasNext: \(currentResult.hasNextSection)")
        print("CompleteQuiz - WrongWords: \(currentResult.incorrectWords.count)")
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
            print("Handling action: \(action)")
            
            switch action {
            case .continueNextSection(let startIndex):
                presentNextSection(startIndex: startIndex)
                
            case .showRetryActionSheet:
                showRetryActionSheet()
                
            case .retryCurrentSection:
                retryCurrentSection()
                
            case .retryWrongWords(let words):
                print("Wrong words count: \(words.count)")
                if words.isEmpty {
                    ToastManager.shared.show("틀린 단어가 없습니다.")
                    return
                }
                presentWrongWordsQuiz(words: words)
                
            case .restartFromBeginning:
                restartFromBeginning()
            }
        }
        
        private func presentNextSection(startIndex: Int) {
            print("Present next section: \(startIndex)")
            
            guard let presentingVC = presentingViewController else { return }
            
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                
                
                let vm = SelectQuizViewModel(startIndex: startIndex)
                let vc = SelectQuizViewController(viewModel: vm)
                vc.modalPresentationStyle = .formSheet
                
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                }
                
                presentingVC.present(vc, animated: true)
            }
        }
        
        private func showRetryActionSheet() {
            print("Show retry action sheet")
            let alert = UIAlertController(title: "다시 학습", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "구간 전체 학습", style: .default) { [weak self] _ in
                print("Retry current section selected")
                self?.retryCurrentSection()
            })
            
            alert.addAction(UIAlertAction(title: "틀린 단어 학습하기", style: .default) { [weak self] _ in
                print("Retry wrong words selected")
                guard let self = self else { return }
                handleAction(.retryWrongWords(words: currentResult.incorrectWords))
            })
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            
            present(alert, animated: true)
        }
        
        private func retryCurrentSection() {
            print("Retry current section")
            guard let presentingVC = presentingViewController else { return }
            
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                
                let quizData = QuizData(
                    mode: originalQuizData.mode,
                    words: originalQuizData.words,
                    allWord: originalQuizData.allWord,
                    startIndex: originalQuizData.startIndex,
                    sectionSize: originalQuizData.sectionSize
                )
                
                let vm = ChoiceQuizViewModel(quizData: quizData)
                let vc = ChoiceQuizViewController(viewModel: vm, quizData: quizData)
                vc.modalPresentationStyle = .fullScreen
                presentingVC.present(vc, animated: true)
            }
        }
        
        private func presentWrongWordsQuiz(words: [WordModel]) {
            guard let presentingVC = presentingViewController else { return }
            
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                
                let quizData = QuizData(
                    mode: originalQuizData.mode,
                    words: words,
                    allWord: originalQuizData.allWord,
                    startIndex: 0,
                    sectionSize: nil
                )
                
                let vm = ChoiceQuizViewModel(quizData: quizData)
                let vc = ChoiceQuizViewController(viewModel: vm, quizData: quizData)
                vc.modalPresentationStyle = .fullScreen
                presentingVC.present(vc, animated: true)
            }
        }
        
    private func restartFromBeginning() {
        print("Restart from beginning")
        guard let presentingVC = presentingViewController else { return }
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            let vm = SelectQuizViewModel(startIndex: 0)
            let vc = SelectQuizViewController(viewModel: vm)
            vc.modalPresentationStyle = .formSheet
            
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
            }
            
            presentingVC.present(vc, animated: true)
        }
    }
}
