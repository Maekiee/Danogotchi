import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher


final class SelectQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SelectQuizViewModel()
    
    
    // MARK: - UI 프로퍼티
    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "구간 선택"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 17)
        return label
    }()
    
    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        return toggle
    }()
    
    private let counterContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let decreaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.text = "10"
        label.textColor = .black
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let increaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let startLearningButton = PrimaryFillButton(title: "학습시작")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            sectionTitleLabel,
            toggleSwitch,
            counterContainerView,
            startLearningButton
        ].forEach { view.addSubview($0) }
        
        [
            decreaseButton,
            countLabel,
            increaseButton
        ].forEach { counterContainerView.addSubview($0) }
    }
    
    override func configLayout() {
        sectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.equalToSuperview().offset(24)
        }
        
        toggleSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(sectionTitleLabel)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        counterContainerView.snp.makeConstraints { make in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(60)
        }
        
        decreaseButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        countLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(80)
        }
        
        increaseButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        startLearningButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
    }
}

extension SelectQuizViewController {
    private func bind() {
        let input = SelectQuizViewModel.Input(
            toggleIsOn: toggleSwitch.rx.isOn.asObservable(),
            decreaseButtonTap: decreaseButton.rx.tap.asObservable(),
            increaseButtonTap: increaseButton.rx.tap.asObservable(),
            startLearningTap: startLearningButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
//        startLearningButton.rx.tap
//            .bind(with: self) { owner, _ in
//                let vc = ChoiceQuizViewController()
//                vc.modalPresentationStyle = .fullScreen
//                owner.present(vc, animated: true)
//            }.disposed(by: disposeBag)
        
        output.startQuiz
            .asSignal()
            .emit(with: self) { owner, quizData in
                print(quizData)
                let vc = ChoiceQuizViewController()
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        output.isSection
            .drive(with: self) { owner, isEnabled in
                
                UIView.animate(withDuration: 0.2) {
                    owner.counterContainerView.alpha = isEnabled ? 1.0 : 0.0
                }
//                owner.counterContainerView.alpha = isEnabled ?  1.0 : 0.0
            }.disposed(by: disposeBag)
        
        output.sectionCount
            .map { "\($0)" }
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)
    }
}

