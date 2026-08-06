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
//    private let progressView: UIProgressView = {
//        let progress = UIProgressView(progressViewStyle: .bar)
//        progress.progressTintColor = AppColor.oxfordBlue
//        progress.trackTintColor = AppColor.appWhite
//        progress.progress = 0.0
//        progress.layer.cornerRadius = 6
//        progress.clipsToBounds = true
//      
////        progress.layer.sublayers?[1].cornerRadius = 6
//        progress.subviews[1].clipsToBounds = true
//      
//        progress.layer.borderColor = UIColor.black.cgColor
//        progress.layer.borderWidth = 1
//        return progress
//    }()
    private let totalQuestionLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.label
        return label
    }()
    private let quizQuestionCard = QuisQuestionCard()
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "단어의 뜻을 선택하세요"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.title2
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private let choice1Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 1", for: .normal)
        button.setTitleColor(AppColor.white, for: .normal)
        button.backgroundColor = AppColor.black
        button.layer.cornerRadius = AppRadius.radius20
        button.titleLabel?.font = AppFont.title2
        
        button.layer.borderWidth = AppBorder.regular
        button.layer.borderColor = UIColor.black.cgColor
        
        button.layer.shadowColor = AppColor.pointDarkGray.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    private let choice2Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 2", for: .normal)
        button.setTitleColor(AppColor.white, for: .normal)
        button.backgroundColor = AppColor.black
        button.layer.cornerRadius = AppRadius.radius20
        button.titleLabel?.font = AppFont.title2
        
        button.layer.borderWidth = AppBorder.regular
        button.layer.borderColor = UIColor.black.cgColor
        
        button.layer.shadowColor = AppColor.pointDarkGray.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    private let choice3Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 3", for: .normal)
        button.setTitleColor(AppColor.white, for: .normal)
        button.backgroundColor = AppColor.black
        button.layer.cornerRadius = AppRadius.radius20
        button.titleLabel?.font = AppFont.title2
        
        button.layer.borderWidth = AppBorder.regular
        button.layer.borderColor = UIColor.black.cgColor
        
        button.layer.shadowColor = AppColor.pointDarkGray.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    private let choice4Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 4", for: .normal)
        button.setTitleColor(AppColor.white, for: .normal)
        button.backgroundColor = AppColor.black
        button.layer.cornerRadius = AppRadius.radius20
        button.titleLabel?.font = AppFont.title2
        
        button.layer.borderWidth = AppBorder.regular
        button.layer.borderColor = UIColor.black.cgColor
        
        button.layer.shadowColor = AppColor.pointDarkGray.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    private lazy var progressStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = AppSpacing.space8
        stack.alignment = .center
        stack.addArrangedSubview(progressView)
        return stack
    }()
    private lazy var choiceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.space12
        stack.distribution = .fillEqually
        
        [
            choice1Button,
            choice2Button,
            choice3Button,
            choice4Button
        ].forEach { stack.addArrangedSubview($0) }
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
            //            progressStackView,
            quizQuestionCard,
            //            questionLabel,
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
            make.height.equalTo(12)  // 두께 조정 (기본 2 → 8)
        }
        
        quizQuestionCard.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(160)
        }
        
        choiceStackView.snp.makeConstraints { make in
            make.top.equalTo(quizQuestionCard.snp.bottom).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space24)
        }
        
        choice1Button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.background
    }
}

extension QuizViewController {
    private func bind() {
        let choiceTaps = Observable.merge(
            choice1Button.rx.tap.map { 0 },
            choice2Button.rx.tap.map { 1 },
            choice3Button.rx.tap.map { 2 },
            choice4Button.rx.tap.map { 3 }
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
            }.disposed(by: disposeBag)
        //            .drive(questionLabel.rx.text)
        //            .disposed(by: disposeBag)
        
        output.choices
            .drive(with: self) { owner, choices in
                owner.choice1Button.setTitle(choices[0], for: .normal)
                owner.choice2Button.setTitle(choices[1], for: .normal)
                owner.choice3Button.setTitle(choices[2], for: .normal)
                owner.choice4Button.setTitle(choices[3], for: .normal)
                
                // 버튼 색상 초기화
                [owner.choice1Button, owner.choice2Button,
                 owner.choice3Button, owner.choice4Button].forEach {
                    $0.backgroundColor = AppColor.appWhite
                    $0.setTitleColor(AppColor.textPrimary, for: .normal)
                    $0.isEnabled = true
                }
            }.disposed(by: disposeBag)
        
        output.answerResult
            .emit(with: self) { owner, result in
                let buttons = [owner.choice1Button, owner.choice2Button,
                               owner.choice3Button, owner.choice4Button]
                
                buttons.forEach { $0.isEnabled = false }
                
                let selectedButton = buttons[result.selectedIndex]
                
                selectedButton.backgroundColor = result.isCorrect ? AppColor.appGreen : AppColor.appRed
                selectedButton.setTitleColor(.white, for: .normal)
                
                if !result.isCorrect {
                    buttons[result.correctIndex].backgroundColor = AppColor.appGreen
                    buttons[result.correctIndex].setTitleColor(.white, for: .normal)
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

extension Reactive where Base: CustomProgressView {
    var progress: Binder<Float> {
        return Binder(self.base) { view, progress in
            // 애니메이션과 함께 progress 설정
            view.setProgress(progress, animated: true)
        }
    }
}
