import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher


final class ChoiceQuizViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    
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
        label.text = "1"
        label.textColor = .black
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .systemGray5
        progress.progress = 0.0
        return progress
    }()
    
    private let totalQuestionLabel: UILabel = {
        let label = UILabel()
        label.text = "10"
        label.textColor = .black
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let wordImageView: UIImageView = {
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
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice2Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 2", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice3Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 3", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let choice4Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택지 4", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let progressStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let choiceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
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
            progressStackView,
            wordImageView,
            questionLabel,
            choiceStackView
        ].forEach { view.addSubview($0) }
        
        
        [
            currentQuestionLabel,
            progressView,
            totalQuestionLabel
        ].forEach { progressStackView.addArrangedSubview($0) }
        
        [
            choice1Button,
            choice2Button,
            choice3Button,
            choice4Button
        ].forEach { choiceStackView.addArrangedSubview($0) }
    }
    
    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
        
        
        progressStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(20)
        }
        
        wordImageView.snp.makeConstraints { make in
            make.top.equalTo(progressStackView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(wordImageView.snp.width).multipliedBy(2.0/3.0)
        }
        
        questionLabel.snp.makeConstraints { make in
            make.top.equalTo(wordImageView.snp.bottom).offset(24)
            make.center.equalToSuperview()
        }
        
        choiceStackView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(80)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-24)
        }
    }
    
    override func configView() {
        
    }
    
    
}

extension ChoiceQuizViewController {
    private func bind() {
        
    }
}
