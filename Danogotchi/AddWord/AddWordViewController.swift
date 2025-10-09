import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class AddWordViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: AddWordViewModel
    private let entryPoint: EntryPoint
    
    init(viewModel: AddWordViewModel, entryPoint: EntryPoint) {
        self.viewModel = viewModel
        self.entryPoint = entryPoint
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI Property
    private let VScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.isUserInteractionEnabled = true
        view.delaysContentTouches = false
        view.canCancelContentTouches = true
        return view
    }()
    
    private let contentView = UIView()
    
    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private let emptyImageIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "photo.on.rectangle")
        view.tintColor = .systemGray3
        return view
    }()
    
    private let wordBookTitleTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "단어장 세트 이름"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    private let wordTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "단어"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    private let meanTextField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.title = "뜻"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    private lazy var addWordButton = PrimaryFillButton(title: self.entryPoint == .add ? "저장" : "수정")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        
        bind()
    }
    
    override func configHierarchy() {
        
        view.addSubview(VScrollView)
        VScrollView.addSubview(contentView)
        
        [
            thumbnail,
            wordBookTitleTextField,
            wordTextField,
            meanTextField,
            addWordButton
        ].forEach { contentView.addSubview($0) }
        
        thumbnail.addSubview(emptyImageIcon)
    }
    
    override func configLayout() {
        VScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        thumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(thumbnail.snp.width).multipliedBy(1.0/2.0)
        }
        
        emptyImageIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        wordBookTitleTextField.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        wordTextField.snp.makeConstraints { make in
            make.top.equalTo(wordBookTitleTextField.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        meanTextField.snp.makeConstraints { make in
            make.top.equalTo(wordTextField.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        [wordBookTitleTextField, wordTextField, meanTextField].forEach { underlineTextField in
            underlineTextField.tf.snp.makeConstraints { make in
                make.height.equalTo(40) // 원하는 높이 설정
            }
        }
        
        addWordButton.snp.makeConstraints { make in
            make.top.equalTo(meanTextField.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    override func configView() {
        navigationController?.navigationBar.tintColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: nil,
            action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "더 많은 사진 보기",
            style: .plain,
            target: nil,
            action: nil)
        
    }
}

extension AddWordViewController {
    private func bind() {
        let selectedImage = PublishRelay<String>()
        
        let input = AddWordViewModel.Input(
            wordBookTitleTextField: wordBookTitleTextField.tf.rx.text.orEmpty.asObservable(),
            wordTextField: wordTextField.tf.rx.text.orEmpty.asObservable(),
            meanTextField: meanTextField.tf.rx.text.orEmpty.asObservable(),
            selectedImage: selectedImage.asObservable(),
            savedButtonTapped: addWordButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        navigationItem.leftBarButtonItem!.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem!.rx.tap
            .withLatestFrom(output.itemSet)
            .bind(with: self) { owner, item in
                let (items, text) = item
                let vm = WordImageListViewModel(imageItems: items, wordText: text)
                let vc = WordImageListViewController(viewModel: vm)
                vc.onChangedImage = { selectedUrl in
                    selectedImage.accept(selectedUrl)
                }
                owner.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: disposeBag)
        
        output.wordImageUrl
            .drive(with: self) { owner, url in
                if url != "" {
                    owner.thumbnail.kf.setImage(with: URL(string: url)!)
                    owner.emptyImageIcon.isHidden = true
                }
                
                
            }.disposed(by: disposeBag)
        
        output.bookTitle
            .drive(wordBookTitleTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.wordTextFieldText
            .drive(wordTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.meanText
            .drive(meanTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.translateWord
            .drive(meanTextField.rx.placeholder)
            .disposed(by: disposeBag)
        
        output.isValidSave
            .drive(addWordButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.resetTrigger
            .emit(with: self) { owner, _  in
//                guard let self = self else { return }
                // 단어장 제목을 제외한 나머지 필드를 초기화
                owner.wordTextField.text = ""
                owner.meanTextField.text = ""
                
                // 이미지 뷰도 기본 이미지로 초기화할 수 있습니다.
                owner.thumbnail.image = nil
                if owner.thumbnail.image == nil {
                    owner.emptyImageIcon.isHidden = false
                }
                
                let message = owner.entryPoint == .add ? "단어가 추가 되었습니다." : "단어가 수정 되었습니다."
                owner.showToast(message, duration: .short)
                print("입력 필드가 초기화되었습니다.")
            }.disposed(by: disposeBag)
    }
}
