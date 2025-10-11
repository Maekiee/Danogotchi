import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher


final class ChoiceQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ChoiceQuizViewModel
    
    // 외부에서 새로운 QuizData를 받아 ViewModel을 리셋하기 위한 Relay
    private let restartTrigger = PublishRelay<QuizData>()
    
    init(viewModel: ChoiceQuizViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
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
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 17)
        label.textAlignment = .center
        return label
    }()
    
    private let currentQuestionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = .systemGreen
          progress.trackTintColor = .systemGray5
          progress.progress = 0.0
          progress.layer.cornerRadius = 4
          progress.clipsToBounds = true
          progress.layer.sublayers?[1].cornerRadius = 4
          progress.subviews[1].clipsToBounds = true
        return progress
    }()
    
    private let totalQuestionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let thumbnailImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "단어의 뜻을 선택하세요"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let choice1Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 1", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice2Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 2", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice3Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 3", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice4Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 4", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private lazy var progressStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.addArrangedSubview(progressView)
        return stack
    }()
    
    private lazy var choiceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
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
            thumbnailImage,
            questionLabel,
            choiceStackView
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.size.equalTo(44)
        }
        
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(8)  // 두께 조정 (기본 2 → 8)
        }
//        progressStackView.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(16)
//            make.horizontalEdges.equalToSuperview().inset(24)
//            make.height.equalTo(20)
//        }
        
        thumbnailImage.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(thumbnailImage.snp.width).multipliedBy(2.0/3.0)
        }
        
        questionLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImage.snp.bottom).offset(24)
            make.center.equalToSuperview()
        }
        
        choiceStackView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(80)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-24)
        }
        
        choice1Button.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
}

extension ChoiceQuizViewController {
    private func bind() {
        let choiceTaps = Observable.merge(
            choice1Button.rx.tap.map { 0 },
            choice2Button.rx.tap.map { 1 },
            choice3Button.rx.tap.map { 2 },
            choice4Button.rx.tap.map { 3 }
        )
        
        let input = ChoiceQuizViewModel.Input(
            choiceSelected: choiceTaps,
            restartWithNewData: restartTrigger.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        
        output.progress
            .drive(progressView.rx.progress)
            .disposed(by: disposeBag)
        
        Driver.combineLatest(output.currentQuestion, output.totalQuestion)
            .map { "\($0) / \($1)" }
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.wordImage
            .drive(with: self) { owner, urlString in
                if let url = URL(string: urlString) {
                    owner.thumbnailImage.kf.setImage(with: url)
                } else {
                    print("이미지 업음")
                    owner.thumbnailImage.image = nil
                }
            }.disposed(by: disposeBag)
        
        output.questionWord
            .drive(questionLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.choices
            .drive(with: self) { owner, choices in
                owner.choice1Button.setTitle(choices[0], for: .normal)
                owner.choice2Button.setTitle(choices[1], for: .normal)
                owner.choice3Button.setTitle(choices[2], for: .normal)
                owner.choice4Button.setTitle(choices[3], for: .normal)
                
                // 버튼 색상 초기화
                [owner.choice1Button, owner.choice2Button,
                 owner.choice3Button, owner.choice4Button].forEach {
                    $0.backgroundColor = .white
                    $0.isEnabled = true
                }
            }.disposed(by: disposeBag)
        
        output.answerResult
            .emit(with: self) { owner, result in
                let buttons = [owner.choice1Button, owner.choice2Button,
                               owner.choice3Button, owner.choice4Button]
                
                buttons.forEach { $0.isEnabled = false }
                
                let selectedButton = buttons[result.selectedIndex]
                selectedButton.backgroundColor = result.isCorrect ? .systemGreen : .systemRed
                
                if !result.isCorrect {
                    buttons[result.correctIndex].backgroundColor = .systemGreen
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return }
                    viewModel.moveToNextQuestion()
                }
            }
            .disposed(by: disposeBag)
        
        output.quizCompleted
            .emit(with: self) { owner, result in
                let currentQuizData = owner.viewModel.quizDataRelay.value
                let vm = CompleteQuizViewModel(result: result)
                let vc = CompleteQuizViewController(viewModel: vm, originalQuizData: currentQuizData, result: result)
                
                vc.onDismissAction = { [weak self] action, quizData, result in
                    guard let self = self else { return }
                    self.handleQuizAction(action, originalData: quizData, result: result)
                }
                
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind(with: self) { owner, _ in
                AlertUtils.showAlert(
                    on: owner,
                    title: "학습 중단",
                    message: "정말로 학습을 중단하시겠습니까?",
                    confirmAction: {
                        owner.dismiss(animated: true)
                    }
                )
            }.disposed(by: disposeBag)
    }
    
    private func handleQuizAction(_ action: CompleteQuizViewModel.ActionType, originalData: QuizData, result: QuizResult) {
        switch action {
        case .restart:
            let newQuizData = QuizData(
                words: originalData.allWord,
                allWord: originalData.allWord
            )
            restartTrigger.accept(newQuizData)
            
        case .retryIncorrect(let words):
            let newQuizData = QuizData(
                words: words,
                allWord: originalData.allWord
            )
            restartTrigger.accept(newQuizData)
            
        case .finish:
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            
        case .dismiss:
            break
        }
    }
}
