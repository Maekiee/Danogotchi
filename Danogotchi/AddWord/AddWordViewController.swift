import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class AddWordViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = AddWordViewModel()
    
    // MARK: UI Property
    private let dismissButton = IconButton(imageName: "xmark")
    private let saveButton = TextButton(title: "저장")
    private let showMoreImageButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        var textConfig = AttributedString("더 많은 이미지 보기")
        textConfig.font = .systemFont(ofSize: 13)
        config.image = UIImage(systemName: "chevron.right")
        config.imagePadding = 8
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10)
        config.preferredSymbolConfigurationForImage = symbolConfiguration
        config.imagePlacement = .trailing
        config.attributedTitle = textConfig
        button.configuration = config
        return button
    }()
    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    private let wordTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "단어"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    private let wordTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.font = .systemFont(ofSize: 18, weight: .regular)
        return tf
    }()
    private let meanTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "뜻"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    private let meanTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.font = .systemFont(ofSize: 18, weight: .regular)
        return tf
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
            dismissButton,
            saveButton,
            showMoreImageButton,
            thumbnail,
            wordTitleLabel,
            wordTextField,
            meanTitleLabel,
            meanTextField
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.equalToSuperview().offset(16)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        showMoreImageButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(4)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        thumbnail.snp.makeConstraints { make in
            make.top.equalTo(showMoreImageButton.snp.bottom)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(thumbnail.snp.width).multipliedBy(2.0/3.0)
        }
        
        wordTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().offset(20)
        }
        
        wordTextField.snp.makeConstraints { make in
            make.top.equalTo(wordTitleLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().offset(20)
        }
        
        meanTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(wordTextField.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().offset(20)
        }
        
        meanTextField.snp.makeConstraints { make in
            make.top.equalTo(meanTitleLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().offset(20)
        }
    }
    
    override func configView() {
        
    }
}

extension AddWordViewController {
    private func bind() {
        let input = AddWordViewModel.Input(
            wordTextField: wordTextField.tf.rx.text.orEmpty.asObservable(),
            meanTextField: meanTextField.tf.rx.text.orEmpty.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        dismissButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        showMoreImageButton.rx.tap
            .bind(with: self) { owner, _ in
                print("이동하기")
                let vc = ImageDetailViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: disposeBag)
        
        output.wordImageUrl
            .drive(with: self) { owner, url in
                owner.thumbnail.kf.setImage(with: URL(string: url)!)
            }.disposed(by: disposeBag)
        
    }
}
