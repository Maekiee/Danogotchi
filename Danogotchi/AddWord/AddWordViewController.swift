import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class AddWordViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = AddWordViewModel()
    
    // MARK: UI Property
    private let dismissButton = IconButton(imageName: "xmark")
    private let saveButton = TextButton(title: "저장")
    private let showMoreImageButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "더 많은 이미지 보기"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        button.configuration = config
        return button
    }()
    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 8
        return view
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
            thumbnail
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        showMoreImageButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        thumbnail.snp.makeConstraints { make in
            make.top.equalTo(showMoreImageButton.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(thumbnail.snp.width).multipliedBy(2.0/3.0)
        }
    }
    
    override func configView() {
        
    }
}

extension AddWordViewController {
    private func bind() {
        let input = AddWordViewModel.Input()
        let output = viewModel.transform(input: input)
        
        dismissButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
    }
}
