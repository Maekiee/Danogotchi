import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa


final class CompleteQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: CompleteQuizViewModel
    private let originalQuizData: QuizData
    
    init(viewModel: CompleteQuizViewModel, originalQuizData: QuizData) {
        self.viewModel = viewModel
        self.originalQuizData = originalQuizData
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
            .drive(primaryButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        output.secondaryButtonTitle
            .drive(secondaryButton.rx.title(for: .normal))
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
    }
    
    
}


extension CompleteQuizViewController {
    private func handleAction(_ action: CompleteQuizViewModel.ActionType) {
        switch action {
        case .continueNextSection(let startIndex):
            presentNextSection(startIndex: startIndex)
            
        case .showRetryActionSheet:
            showRetryActionSheet()
            
        case .retryCurrentSection:
            retryCurrentSection()
            
        case .retryWrongWords(let words):
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
        dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let presentingVC = self.presentingViewController else { return }
            
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
        let alert = UIAlertController(title: "다시 학습", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "구간 전체 학습", style: .default) { [weak self] _ in
            self?.retryCurrentSection()
        })
        
        alert.addAction(UIAlertAction(title: "틀린 단어 학습하기", style: .default) { [weak self] _ in
            self?.handleAction(.retryWrongWords(words: self?.originalQuizData.words.filter { word in
                // 현재 구간의 틀린 단어 필터링 로직 필요
                true
            } ?? []))
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func retryCurrentSection() {
        dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let presentingVC = self.presentingViewController else { return }
            
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
        dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let presentingVC = self.presentingViewController else { return }
            
            let quizData = QuizData(
                mode: self.originalQuizData.mode,
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
        dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let presentingVC = self.presentingViewController else { return }
            
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
